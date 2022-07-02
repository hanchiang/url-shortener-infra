#!/bin/bash

USER="han"

POSTGRES_USER_PASSWORD=$(cat /tmp/postgres-user-password.txt)
sudo rm /tmp/postgres-user-password.txt

# Install docker
sudo apt-get update

# Remove docker
sudo apt-get -y remove docker-desktop || true
rm -r $HOME/.docker/desktop || true
sudo rm /usr/local/bin/com.docker.cli || true
sudo apt-get -y purge docker-desktop || true

# Add docker repository
sudo apt-get -y install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install docker
sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Create "docker" group, add users to allow sudo-less usage of docker
sudo groupadd docker || true
sudo usermod -a -G docker $USER
sudo usermod -a -G docker ubuntu
echo "groups before $(groups)" 
newgrp docker
echo "groups after $(groups)"

docker version
docker compose version

# Start docker on boot
sudo systemctl enable docker.service
sudo systemctl enable containerd.service


# Install postgres, execute database schema script
echo "Installing postgres"
sudo apt-get -y install postgresql postgresql-contrib
sudo systemctl start postgresql.service
sudo systemctl enable postgresql

sudo -u postgres createuser --superuser $USER
sudo -u postgres psql << EOF
ALTER USER $USER PASSWORD '$POSTGRES_USER_PASSWORD';
EOF
unset POSTGRES_USER_PASSWORD

sudo -u postgres createdb $USER
DB_NAME="url_shortener"
sudo -u postgres createdb $DB_NAME

sudo cp /tmp/postgres-schema.sql .
sudo -u $USER psql -d $DB_NAME -f postgres-schema.sql

# Allow password authentication
TAB="$(printf '\t')"
cat << EOF | sudo tee -a /etc/postgresql/*/main/pg_hba.conf >/dev/null
local${TAB}all${TAB}all${TAB}password
EOF

sudo systemctl restart postgresql.service

# Install redis
echo "Installing redis"
sudo apt-get -y install redis-server
sudo sed "s/^supervised no/supervised systemd/" /etc/redis/redis.conf > redis.conf
sudo systemctl restart redis.service
sudo systemctl enable redis-server


