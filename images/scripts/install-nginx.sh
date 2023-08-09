#! /bin/bash

### Install nginx
echo "Installing nginx"
NGINX_BRANCH="stable" # use nginx=development for latest development version

sudo add-apt-repository -y ppa:nginx/$NGINX_BRANCH
sudo apt update
sudo apt -y install nginx=1.18.0-6ubuntu14

sudo ufw --force enable
sudo ufw allow 80
sudo ufw allow 443
sudo ufw status verbose

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


# Compile GeoIP2 module for nginx
# Guide: https://medium.com/@maxime.durand.54/add-the-geoip2-module-to-nginx-f0b56e015763
git clone https://github.com/leev/ngx_http_geoip2_module.git

echo "Compiling GeoIP2 module for nginx"
sudo apt -y install \
libmaxminddb0 libmaxminddb-dev mmdb-bin \
build-essential libpcre3-dev zlib1g-dev 

# Download nginx source, compile with GeoIP2 module
NGINX_VERSION="1.18.0"
wget -q http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
tar -zxf nginx-$NGINX_VERSION.tar.gz
rm nginx-$NGINX_VERSION.tar.gz
cd nginx-$NGINX_VERSION

./configure --with-compat --add-dynamic-module=../ngx_http_geoip2_module
make modules

sudo mkdir -p /usr/lib/nginx/modules
sudo cp objs/ngx_http_geoip2_module.so /usr/lib/nginx/modules

# sudo sed -i "1 i\load_module modules/ngx_http_geoip2_module.so;" /etc/nginx/nginx.conf
sudo nginx -t
sudo systemctl restart nginx


echo "Installing geoipupdate"

sudo add-apt-repository -y ppa:maxmind/ppa
sudo apt update
sudo apt -y install geoipupdate 

cat<<EOF | sudo tee /etc/GeoIP.conf > /dev/null
 # GeoIP.conf file for geoipupdate program, for versions >= 3.1.1.
 # Used to update GeoIP databases from https://www.maxmind.com.
 # For more information about this config file, visit the docs at
 # https://dev.maxmind.com/geoip/updating-databases?lang=en.
 
 # AccountID is from your MaxMind account.
 AccountID $MAXMIND_ACCOUNT_ID
 
 # LicenseKey is from your MaxMind account
 LicenseKey $MAXMIND_LICENSE_KEY
 
 # EditionIDs is from your MaxMind account.
 EditionIDs GeoLite2-ASN GeoLite2-City GeoLite2-Country
EOF
unset MAXMIND_ACCOUNT_ID MAXMIND_LICENSE_KEY

MAXMIND_DIR="/usr/share/GeoIP"

cat <<EOF >> mycron
MAILTO="$ADMIN_EMAIL"
# Run GeoIP database every day at 1400 UTC
0 14 * * * sudo /usr/bin/geoipupdate -v -d $MAXMIND_DIR
EOF
crontab mycron
crontab -l
rm mycron

sudo mkdir -p $MAXMIND_DIR

# Run it
sudo geoipupdate -v -d $MAXMIND_DIR