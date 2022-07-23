#! /bin/bash

### Install nginx
echo "Installing nginx"
nginx="stable" # use nginx=development for latest development version
sudo add-apt-repository -y ppa:nginx/$nginx
sudo apt-get update
sudo apt-get -y install nginx=1.18.0-3ubuntu1+focal2

sudo ufw --force enable
sudo ufw allow 'Nginx Full'
sudo ufw status

sudo systemctl enable nginx
sudo systemctl start nginx

localhost=$(ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//' | head -n 1)
curl $localhost

# Setup nginx server block
sudo mkdir -p /var/www/$DOMAIN/html
sudo chown -R $USER:$USER /var/www/$DOMAIN/html
sudo chmod -R 755 /var/www/$DOMAIN

# Default html page
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
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwared-Proto \$scheme;
  }
}

server {
  listen 80;
  listen [::]:80;

  server_name $URL_REDIRECT_DOMAIN;

  location / {
    proxy_pass http://url_shortener_backend;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwared-Proto \$scheme;
  }
}
EOF

sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx