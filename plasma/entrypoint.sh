#!/usr/bin/env bash
#    Copyright (C) 2021  Adam Johnson
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

BIN_PATH="/opt/plServers/bin"
INI_PATH="/opt/plServers/etc/PlasmaServers.ini"
SHARE_PATH="/opt/plServers/share"
SAVE_PATH="/opt/plServers/SavedGames"

mkdir -p ${SAVE_PATH}

if [[ ! -f "$BIN_PATH/$1" ]]; then
    echo "ERROR: plServer binary $1 not found!"
    exit 1
fi

# Be sure the database is ready before launching plServers.
echo -e "\e[36mWaiting for database availability...\e[0m"
until mysqladmin ping -h "${DB_ADDRESS}" -P "${DB_PORT}" -u "${DB_USERNAME}" "--password=${DB_PASSWORD}" --silent
do
    sleep 0.1
done

# Everything that isn't plNetLookupServer needs to wait on pls to become available.
# So... do that.
if [[ $1 != "plNetLookupServer" ]]; then
    echo -e "\e[36mWaiting for plNetLookupServer...\e[0m"
    until curl -f http://lookup:${PLS_HTTP_PORT:-7677}
    do
        sleep 0.1
    done
fi

# For some reason, if the lookup database persists, the other servers cannot connect. So, we
# destroy the contents.
if [[ $1 == "plNetLookupServer" ]]; then
    echo -e "\e[36mDropping stale PLS data...\e[0m"
    mysql -h "${DB_ADDRESS}" -P "${DB_PORT}" -u "${DB_USERNAME}" "--password=${DB_PASSWORD}" -e "USE ${DB_USERNAME}_lookup; DELETE FROM Servers;"
    if [[ $? -ne 0 ]]; then
        echo -e "\e[31mShit!\e[0m"
    fi
fi

# Write PlasmaServers.ini
cat << EOF > "${INI_PATH}"
[global]
pls=lookup
bindaddr=0.0.0.0
;WebsiteUrl=${STATUS_URL}
NATAddr=${EXTERNAL_ADDRESS:-127.0.0.1}

PythonDir=${SHARE_PATH}/python
SDLDir=${SHARE_PATH}/SDL
AgeDir=${SHARE_PATH}/AgeFiles
SavedGamesDir=${SAVE_PATH}

[EventLog]
disable=1

[db]
DbUserName=${DB_USERNAME}
DbPassword=${DB_PASSWORD}
DbHost=${DB_ADDRESS}
DbPort=${DB_PORT}

[Auth_Server]
HttpListenPort=${AUTH_HTTP_PORT}
db.dbname=${DB_USERNAME}_auth

[Lookup_Server]
HttpListenPort=${PLS_HTTP_PORT}
db.dbname=${DB_USERNAME}_lookup

[game_server]
AlwaysAllowTimeout

[Generated_Lobby]
HttpListenPort=${LOBBY_HTTP_PORT}

[vault_server]
db.dbname=${DB_USERNAME}_vault
HttpListenPort=${VAULT_HTTP_PORT}

[Server_Agent]
HttpListenPort=${AGENT_HTTP_PORT}
EOF

ulimit -c unlimited
"$BIN_PATH/$1" ini="$INI_PATH"
