# Home Control

## Installation

1. Install Raspbian on each Raspberry (CENTRAL and CLIENT).

2. if you want ssh enabled, create a ssh file on the sdcard boot partition.

3. Copy each folder to the rootf partition of the good Raspberry Pi sdcard.
4. Add `sudo /bin/bash /<CLIENT | CENTRAL>/init.sh` to /rootf/etc/rc.local file on each sdcard.
5. Start first the CENTRAL Raspberry Pi and wait 2 minutes untill reboot or check the script status by connecting a led on GPIO17 pin (the led is on when the script is running and is off when the script end or is not yet begined).
6. Start the second Raspberry Pi and wait 1 minutes untill reboot or check the script status by connecting a led on GPIO17 pin (the led is on when the script is running and is off when the script end or is not yet begined).

## Configuration

### CENTRAL

1. ethernet :
   1. DHCP client.
   2. The server script send information to the app.
2. wifi :
   1. Access point with WPA2 encryption (with rsn). WPS_PBC generate password encryption for each connection.
   2. DHCP server on 10.0.0.0/24.
   3. The server script receive and send CLIENTS informations there.
3. Firewall :

   1. Block all traffic not allowed (INPUT, OUTPUT AND FORWARD).
   2. Allow DHCP, DNS, HTTP, HTTPS, SSH and SNTP traffic.
   3. Allow traffic from and to the CENTRAL Raspberry.
   4. PAT for all OUTPUT traffic to ethernet.
   5. Allow INPUT and OUTPUT traffic with 85 port (but not FORWARD).

4. Server :
   1. Receives the 85 port traffic.
   2. Check command (rules, destination, ...).
   3. Send 85 port traffic if it's allowed.
   4. Send the CLIENTS Raspberry informations Pi to the app.

### CLIENT

1. wifi :
   1. WPS_PBC connection to access to the access point.
   2. DHCP client.
   3. Command Listener.
   4. Status emitter.
   5. Gpio controler from config.
2. Bluetooth :
   1. iBeacon BLE.

### APP

1. (in development)

## HELP

1. Show DHCP lease : `cat /var/lib/misc/dnsmasq.leases`
2. Get default gateway : `ip route | grep default | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}`
3. Show connected device to hostapd : `arp -a`
4. To send a command : `nc -u 10.42.0.1 85`
5. command structure : `{"command": "set", "key": "id", "value": 95}`
6. GPIO control command : `{"command": "set", "key": "pins", "value": [{"type":0, "number": 17, "value": 1}, {"type":0, "number": 18, "value": 1}]}`
7. Send one command : `echo -n '{"command": "set", "key": "pins", "value": [{"type":0, "number": 17, "value": 1}, {"type":0, "number": 18, "value": 1}]}' | nc -u 10.0.0.135 85 -w1`
