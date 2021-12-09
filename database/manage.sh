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

echo "Manage UU"
echo ""

do_help() {
    echo "Available commands:"
    echo "    addacct - adds a new account to the server"
    echo "    changepass - changes the password of an already existing account"
    echo "    listacct - lists all accounts"
    echo "    makeadmin - gives an account access to the vault manager"
}

if [[ ! -n $1 ]]; then
    do_help
elif [[ $1 = "addacct" ]]; then
    if [[ ! -n $3 ]]; then
        echo "addacct [username] [password]"
        exit 1
    fi
    guid=$(uuidgen)
    mysql -e "INSERT INTO ${DB_USERNAME}_auth.Accounts (AcctName, HashedPassword, NeverExpires, IsActive, AcctUUID) VALUES ('$2', UPPER(MD5('$3')), 1, 1, '$guid');"
    if [[ $? -ne 0 ]]; then
        echo -e "\e[33mWARNING\e[0m: Unable to create account. Does it already exist?"
        exit 1
    fi
    echo "Created account '$2'"
elif [[ $1 = "changepass" ]]; then
    if [[ ! -n $3 ]]; then
        echo "changepass [username] [password]"
        exit 1
    fi
    mysql -e "UPDATE ${DB_USERNAME}_auth.Accounts SET HashedPassword = UPPER(MD5('$3')) WHERE AcctName = '$2';"
    if [[ $? -ne 0 ]]; then
        echo -e "\e[33mWARNING\e[0m: Unable to change account password. Does it exist?"
        exit 1
    fi
    echo "Password changed."
elif [[ $1 = "listacct" ]]; then
    echo "(begin account list)"
    mysql -e "SELECT AcctName FROM ${DB_USERNAME}_auth.Accounts;" | sed 1d
    echo "(end of account list)"
elif [[ $1 = "makeadmin" ]]; then
    if [[ ! -n $2 ]]; then
        echo "makeadmin [username]"
        exit 1
    fi
    mysql -e "INSERT INTO ${DB_USERNAME}_auth.Permissions (AcctName, AcctStatus) VALUES('$2', 'ADMIN');"
    if [[ $? -ne 0 ]]; then
        echo -e "\e[33mWARNING\e[0m: Failed to make '$2' an admin. Are they already one?"
        exit 1
    fi
    echo "'$2' is now an admin."
fi
