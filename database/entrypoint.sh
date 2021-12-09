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

/etc/init.d/mysql start

# This is what you want to do from a DB management perspective, but the UU servers really want
# to create the database and schema together. The whole system is delightfully insecure, so...
# Whatever. At least we're jailed in a container.
# echo -e "\e[36mCreating databases...\e[0m"
# mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_USERNAME}_auth;"
# mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_USERNAME}_lookup;"
# mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_USERNAME}_vault;"

echo -e "\e[36mDropping old user...\e[0m"
mysql -e "REVOKE ALL PRIVILEGES ON * FROM ${DB_USERNAME};"

echo -e "\e[36mGranting global create priv (sigh)..\e[0m"
mysql -e "GRANT CREATE ON * TO ${DB_USERNAME} IDENTIFIED BY '${DB_PASSWORD}';"

echo -e "\e[36mRefreshing privileges...\e[0m"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_USERNAME}_auth.* TO ${DB_USERNAME} IDENTIFIED BY '${DB_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_USERNAME}_lookup.* TO ${DB_USERNAME} IDENTIFIED BY '${DB_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON ${DB_USERNAME}_vault.* TO ${DB_USERNAME} IDENTIFIED BY '${DB_PASSWORD}';"
mysql -e "FLUSH PRIVILEGES;"

# Don't be fooled by the docker-compose console. It may seem like the MySQL server shuts down
# *after* the vault connects to MySQL. This is a race condition in docker... if you remove this,
# then the `mysqladmin ping` busyloop will deadlock because we are only accepting local connections.
echo -e "\e[36mMaking MySQL available...\e[0m"
/etc/init.d/mysql stop
sed -i -e "s/bind-address[ \t]*=[ \t]*127\.0\.0\.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
/etc/init.d/mysql start
sleep infinity
