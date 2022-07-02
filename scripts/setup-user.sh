USER="han"

# Setup sudo to allow no-password sudo for "admin" group and adding "han" user
sudo groupadd -r admin
sudo useradd -m -s /bin/bash $USER
sudo usermod -a -G admin $USER
sudo cp /etc/sudoers /etc/sudoers.orig
echo "$USER  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER

# Installing SSH key
echo "Adding public ssh keys in authorized_keys/"
sudo mkdir -p /home/$USER/.ssh
sudo chmod 700 /home/$USER/.ssh
sudo cp /tmp/url_shortener_rsa.pub /home/$USER/.ssh/authorized_keys
sudo chmod 600 /home/$USER/.ssh/authorized_keys
sudo chown -R $USER /home/$USER/.ssh
sudo usermod --shell /bin/bash $USER

# open ssh port
sudo ufw allow OpenSSH