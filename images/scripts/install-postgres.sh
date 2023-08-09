#!/bin/bash

POSTGRES_USER_PASSWORD=$(cat $POSTGRES_PASSWORD_PATH)
sudo rm $POSTGRES_PASSWORD_PATH

#### Install postgres, execute database schema script
echo "Installing postgres"
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc &>/dev/null
sudo apt update
sudo apt install postgresql postgresql-client -y

psql --version
sudo systemctl enable postgresql
sudo systemctl start postgresql.service


# Create user, DB
dir=$(pwd)
cd ~postgres
sudo -u postgres createuser --superuser $USER
sudo -u postgres psql << EOF
ALTER USER $USER PASSWORD '$POSTGRES_USER_PASSWORD';
EOF
unset POSTGRES_USER_PASSWORD

sudo -u postgres createdb $USER
DB_NAME="url_shortener"
sudo -u postgres createdb $DB_NAME

# Allow remote connection
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf

# Allow password authentication
TAB="$(printf '\t')"
cat << EOF | sudo tee -a /etc/postgresql/*/main/pg_hba.conf > /dev/null
local${TAB}all${TAB}all${TAB}password
EOF

sudo systemctl restart postgresql.service

cd $dir