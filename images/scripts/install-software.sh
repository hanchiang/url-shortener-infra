#!/bin/bash

USER="han"

POSTGRES_USER_PASSWORD=$(cat $POSTGRES_PASSWORD_PATH)
sudo rm /tmp/postgres-user-password.txt

sudo apt-get update

#### Install postgres, execute database schema script
echo "Installing postgres"
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql-13

sudo systemctl enable postgresql
sudo systemctl start postgresql.service

sudo -u postgres createuser --superuser $USER
sudo -u postgres psql << EOF
ALTER USER $USER PASSWORD '$POSTGRES_USER_PASSWORD';
EOF
unset POSTGRES_USER_PASSWORD

sudo -u postgres createdb $USER
DB_NAME="url_shortener"
sudo -u postgres createdb $DB_NAME

sudo -u $USER psql -d $DB_NAME -f $POSTGRES_SCHEMA_PATH
sudo rm $POSTGRES_SCHEMA_PATH

# Allow password authentication
TAB="$(printf '\t')"
cat << EOF | sudo tee -a /etc/postgresql/*/main/pg_hba.conf >/dev/null
local${TAB}all${TAB}all${TAB}password
EOF

sudo systemctl restart postgresql.service

#### Install redis
echo "Installing redis"
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
sudo apt-get update
sudo apt-get -y install redis-tools=6:6.2.7-1rl1~focal1
sudo apt-get -y install redis-server=6:6.2.7-1rl1~focal1

sudo sed "s/^supervised no/supervised systemd/" /etc/redis/redis.conf > redis.conf
sudo systemctl enable redis-server
sudo systemctl restart redis.service

### Install nginx
echo "Installing nginx"
nginx="stable" # use nginx=development for latest development version
sudo add-apt-repository -y ppa:nginx/$nginx
sudo apt-get update
sudo apt-get -y install nginx=1.18.0-3ubuntu1+focal2

sudo ufw --force enable
sudo ufw allow 'Nginx Full'
sudo ufw status
sudo systemctl start nginx
sudo systemctl enable nginx

localhost=$(ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//' | head -n 1)
curl $localhost

# Setup nginx server block
DOMAIN="api.urlshortener.yaphc.com"
sudo mkdir -p /var/www/$DOMAIN/html
sudo chown -R $USER:$USER /var/www/$DOMAIN/html
sudo chmod -R 755 /var/www/$DOMAIN

cat << EOF | sudo tee /var/www/$DOMAIN/html/index.html > /dev/null
<!DOCTYPE html>
<html>
  <head>
  <title>Welcome to nginx!</title>
  <style>
      body {
          width: 35em;
          margin: 0 auto;
          font-family: Tahoma, Verdana, Arial, sans-serif;
      }
  </style>
  </head>
  <body>
  <h1>Welcome to nginx!</h1>
  <p>If you see this page, the nginx web server is successfully installed and
  working. Further configuration is required.</p>

  <p>For online documentation and support please refer to
  <a href="http://nginx.org/">nginx.org</a>.<br/>
  Commercial support is available at
  <a href="http://nginx.com/">nginx.com</a>.</p>

  <p><em>Thank you for using nginx.</em></p>
  </body>
</html>
EOF

cat << EOF | sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null
upstream url_shortener_backend {
  server localhost:3000;
}

server {
  listen 80;
  listen [::]:80;

  server_name $DOMAIN;

  location / {
    proxy_pass http://url_shortener_backend;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }
}
EOF

sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx


#### Install docker
echo "Installing docker"

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
sudo systemctl start docker
echo "groups before $(groups)" 
newgrp docker
echo "groups after $(groups)"

sudo docker version
sudo docker compose version

# Start docker on boot
sudo systemctl enable docker.service
sudo systemctl enable containerd.service