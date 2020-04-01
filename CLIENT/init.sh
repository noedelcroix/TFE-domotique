#!/bin/bash

sleep 5

interface=$(sudo iwconfig 2>/dev/null | grep -o "^\w*");
statePin=17;

#LED de statut
sudo echo $statePin > /sys/class/gpio/export
cd /sys/class/gpio/gpio${statePin}
sudo echo out > direction
sudo echo 1 > value

#Changement de l'hostname
sudo echo "CLIENT" > /etc/hostname
sudo sed -i "s/$(hostname)/CLIENT/g" /etc/hosts

#Configuration du wifi sur le pays fr
sudo raspi-config nonint do_wifi_country fr

#Activation de la recherche wps push button
sleep 5

nc -z google.com 80
while [ $? -eq 1 ]; do sudo wpa_cli -i $interface wps_pbc; nc -z google.com 80; done

sudo apt update
sudo apt install python3-gpiozero -y

#Création du fichier de configuration
sudo echo "{
    \"name\": \"$(hostname)\"
}" > /CLIENT/configHomeControl.json

#Création et activation des services
#Envoi des informations à CENTRAL
sudo echo "[Unit]
Description=Send information to gateway
After=network-online.target

[Service]
Type=simple

ExecStart=python3 /CLIENT/sendInfos.py

Restart=on-failure

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/sendInfos.service

#Ecoute des commandes
sudo echo "[Unit]
Description=Listen and execute commands
After=network-online.target

[Service]
Type=simple

ExecStart=python3 /CLIENT/listenCommand.py

Restart=on-failure

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/listenCommand.service

#Synchronisation du fichier de configuration avec les pins gpio
sudo echo "[Unit]
Description=Control gpio from configHomeControl
After=network-online.target

[Service]
Type=simple

ExecStart=python3 /CLIENT/gpioControl.py

Restart=on-failure

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/gpioControl.service

sudo systemctl enable sendInfos.service
sudo systemctl enable listenCommand.service
sudo systemctl enable gpioControl.service

sudo systemctl start sendInfos.service
sudo systemctl start listenCommand.service
sudo systemctl start gpioControl.service

#Suppression du fichier init + extinction de la LED statut et redémarrage
sudo rm $0
sudo echo $statePin > /sys/class/gpio/unexport
sudo reboot