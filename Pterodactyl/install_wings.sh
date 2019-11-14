#!bin/bash

# This script was created to install the Pterodactyl Wings Daemon onto a new machine.
#
#
# Requirments: Ubuntu >= 18.04
#
#
# Author: Josh King
#

if [ -z "$1" ] && [ -z "$2" ]
then
  echo 'Missing Arguments. Example ./install_wings.sh $hostname $token'
fi

apt update

# Install Docker
apt install docker.io
systemctl start docker
systemctl enable docker

# TODO - Enable Swap on docker

# Install Nodejs
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
apt -y install nodejs make gcc g++
apt -y install npm

# Install Daemon
mkdir -p /srv/daemon /srv/daemon-data
cd /srv/daemon
curl -L https://github.com/pterodactyl/daemon/releases/download/v0.6.12/daemon.tar.gz | tar --strip-components=1 -xzv
npm install --only=production

# Get ssl certificate
apt -y install certbot
certbot -certonly -d $1

# Get node configuration
npm run configure -- --panel-url https://developersclub.net --token $2

# TODO Properly configure AppArmor instead of removing it.
# Remove AppArmor
apt -y remove AppArmor

# Create/Enable Daemon
echo "[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service

[Service]
User=root
WorkingDirectory=/srv/daemon
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/bin/node /srv/daemon/src/index.js
Restart=on-failure
StartLimitInterval=600

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/wings.service

systemctl start wings
systemctl enable --now wings
