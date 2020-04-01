#!/bin/bash

sleep 5

interface=$(sudo iwconfig 2>/dev/null | grep -m 1 -o "^\w*");
statePin=17;

#LED de statut
sudo echo $statePin > /sys/class/gpio/export
cd /sys/class/gpio/gpio${statePin}
sudo echo out > direction
sudo echo 1 > value

#Changement de l'hostname
sudo echo "CENTRAL" > /etc/hostname
sudo sed -i "s/$(hostname)/CENTRAL/g" /etc/hosts

#Test de connexion internet
nc -z google.com 80
while [ $? -eq 1 ]; do nc -z google.com 80; done

curl -sL https://deb.nodesource.com/setup_13.x | bash -
sudo DEBIAN_FRONTEND=noninteractive apt install dnsmasq hostapd iptables-persistent nodejs -y

#Configuration du wifi sur le pays fr
sudo raspi-config nonint do_wifi_country fr

sudo service dnsmasq stop
sudo service hostapd stop

#Activation de l'ip forwarding
sudo echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf

#Configuration du firewall
sudo iptables -F
sudo iptables -X

##Bloque tout le traffic
sudo iptables -P INPUT DROP
sudo iptables -P OUTPUT DROP
sudo iptables -P FORWARD DROP

##Autorisation pour le loopback
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

##Autorisation de la passerelle de CENTRAL
passerelleCENTRAL=$(ip route | grep default | grep -m 1 -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
sudo iptables -A INPUT -s $passerelleCENTRAL -j ACCEPT
sudo iptables -A OUTPUT -d $passerelleCENTRAL -j ACCEPT
sudo iptables -A FORWARD -s $passerelleCENTRAL -j ACCEPT
sudo iptables -A FORWARD -d $passerelleCENTRAL -j ACCEPT

##Autorisation pour le serveur DHCP
sudo iptables -A INPUT -p udp --dport 67:68 --sport 67:68 -j ACCEPT
sudo iptables -A OUTPUT -p udp --dport 67:68 --sport 67:68 -j ACCEPT

##Autorisation pour le serveur sntp
sudo iptables -A INPUT -p udp --sport 123 -j ACCEPT
sudo iptables -A OUTPUT -p udp --sport 123 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 123 -j ACCEPT
sudo iptables -A OUTPUT -p udp --dport 123 -j ACCEPT
sudo iptables -A FORWARD -p udp --dport 123 -j ACCEPT
sudo iptables -A FORWARD -p udp --sport 123 -j ACCEPT

##Autorisation pour le DNS
dnsCENTRAL=$(cat /etc/resolv.conf | grep -m 1 -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
sudo iptables -A INPUT -s $dnsCENTRAL -j ACCEPT
sudo iptables -A OUTPUT -d $dnsCENTRAL -j ACCEPT
sudo iptables -A FORWARD -s $dnsCENTRAL -j ACCEPT
sudo iptables -A FORWARD -d $dnsCENTRAL -j ACCEPT

##Autorisation pour les serveur de paquets
sudo iptables -A INPUT -p tcp --match multiport --sports 80,443 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --match multiport --dports 80,443 -j ACCEPT
sudo iptables -A FORWARD -p tcp --match multiport --sports 80,443 -j ACCEPT
sudo iptables -A FORWARD -p tcp --match multiport --dports 80,443 -j ACCEPT

##Autorisation de SSH
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT

sudo iptables -A INPUT -p tcp --sport 22 -j ACCEPT
sudo iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT

##Autorisation du port 85 pour les commandes
sudo iptables -A INPUT -p udp --dport 85 -j ACCEPT
sudo iptables -A OUTPUT -p udp --dport 85 -j ACCEPT

#Configuration du PAT
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

#Sauvegarde des tables
sudo iptables-save > /etc/iptables/rules.v4

#Configuration de l'adresse ip statique sur l'interface wifi
sudo echo "
interface $interface
static ip_address=10.0.0.1/24
nohook wpa_supplicant
" >> /etc/dhcpcd.conf

sudo service dhcpcd restart

#Configuration du dhcp
sudo echo "
port=0
#log in /var/log/messages
log-dhcp
interface=$interface
dhcp-range=10.0.0.2,10.0.0.254,255.255.255.0,24h
dhcp-option=option:router, 10.0.0.1
dhcp-option=option:dns-server, $dnsCENTRAL
" > /etc/dnsmasq.conf

sudo service dnsmasq start

#Configuration du point d'accès wifi
sudo touch /etc/hostapd.psk
sudo echo "
logger_syslog=-1
logger_syslog_level=2
logger_stdout=-1
logger_stdout_level=2

interface=$interface
driver=nl80211

ssid=CENTRAL
#ignore_broadcast_ssid=1

hw_mode=g
channel=7

wmm_enabled=0
macaddr_acl=0

auth_algs=1
wpa=2
#wpa_passphrase=homeControl
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP

wpa_psk_file=/etc/hostapd.psk
ctrl_interface=/var/run/hostapd
eap_server=1
wps_state=2
ap_setup_locked=1
config_methods=push_button

" > /etc/hostapd/hostapd.conf

sudo echo '
DAEMON_CONF="/etc/hostapd/hostapd.conf"
' >> /etc/default/hostapd

sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd

sudo echo "[Unit]
Description=Server
After=network-online.target

[Service]
Type=simple

ExecStart=node /CENTRAL/Server/index.js

Restart=on-failure

[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/Server.service

systemctl enable Server.service
systemctl start Server.service

#Suppression du fichier init + extinction de la LED statut et redémarrage
sudo rm $0
sudo echo $statePin > /sys/class/gpio/unexport
sudo reboot