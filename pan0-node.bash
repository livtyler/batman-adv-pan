#!/bin/bash

#if using a raspberry pi or other similar device running a linux distro 
#make sure to resize image using sudo raspi-config
#may require sudo sed -i -e 's/\r$//' FILENAME.bash (Replace FILENAME with whatever you called the file) to work
#may need to chmod 777 the file prior to running

#PLEASE NOTE On completion of install on both bridge and node they will need to be paired follow the following commands to pair. #Please note using tab when needing to enter the bluetooth address will help as it will prevent mistakes being made in typing the #bluetooth address

#sudo bluetoothctl
#scan on
#pairable on
#discoverable on
#devices
#pair "USE TAB TO AUTOFILL THIS"
#connect "USE TAB TO AUTOFILL THIS"
#trust "USE TAB TO AUTOFILL THIS"


# Runs updates and upgrades distro
sudo aptitude update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y  && sudo apt-get install -f

#if using ubuntu uncomment the line bellow
#service network-manager stop

#sudo iwconfig pan0 power off
sudo ifconfig pan0 down

read -p 'Please give your node a new hostname:' hostVariable
hostname $hostVariable
sudo echo -n $hostVariable > /etc/init.d/hostname.sh
sudo /etc/init.d/hostname.sh start

# Installs BATMAN-adv
sudo apt-get install batmand -y
sudo apt-get install batctl -y

# Installs batctl which is a configuration util for 
#BATMAN-adv and then it removes any firewall which might interfere with batman-adv
sudo apt-get install batctl iw iptables -y

sudo sh -c "echo DisablePlugins = pnat >> /etc/bluetooth/main.conf"
sudo sed '67AutoEnable=true' /etc/bluetooth/main.conf

# Connects and sets up the mesh-metwork
echo " Now setting up and configuring Batman-adv Mesh "
sudo ifconfig pan0 down
sudo ifconfig pan0 mtu 1532

#sets bat0 to handle all routing
echo bat0 > /sys/class/net/pan0/batman_adv/mesh_iface
echo bat0 > /sys/class/net/eth0/batman_adv/mesh_iface

#Configures pan0 sets password for wireless should be same as bridge gateway
read -p 'Please give your mesh network an essid or enter essid you wish to join: ' essidVariable
sudo iwconfig pan0 mode ad-hoc essid $essidVariable ap 02:12:34:56:78:9A channel 1
read -p 'Please give your wireless mesh network a password: ' wpaPassphrase
echo $wpaPassphrase "$essidVariable" > /etc/wpa_supplicant.conf
#Runs the wpa_supplicant daemon to apply changes
sudo wpa_supplicant -B -i pan0 -DWext -c /etc/wpa_supplicant.conf

# Starts BATMAN-adv
sudo modprobe batman-adv

#adds pan0 to the batman-adv virtual interface
sudo batctl if add pan0
sudo ifconfig pan0 up

#Asks for input to assign ip, this ip is used to assign to your bridge node eg 192.168.3.2 
read -p 'Please input the ip you want to use for bridge node eg 192.168.1.2: ' ipVariable
echo "Thank you $ipVariable will now be used TAKE NOTE OF THIS"
ip_command=`sudo ifconfig bat0 $ipVariable`
sudo ifconfig bat0 echo $ipVariable

#removes ip addresses previously assigned to these devices as this is now managed by batman-adv
sudo ifconfig eth0 0.0.0.0
sudo ifconfig pan0 0.0.0.0

#comment out or delete the one above and uncomment the line bellow to allow bat0 to assign ip automatically this is probably easier
#sudo dhclient bat0

#brings up bat0 interface
sudo ifconfig bat0 up

# Installs cronjob and runs daily checking for updates for debian/raspbian OS
# to keep it upto date for security updates only, should not break anything when it updates
echo " Now Installing CronJob and Setting daily checks for security Updates ONLY Will not update Core or Programs "
sudo aptitude install cron-apt anacron -y
sudo rm /etc/cron.d/cron-apt
cd /etc/cron.daily
sudo ln -s /usr/sbin/cron-apt
APTCOMMAND=/usr/bin/aptitude
cd /etc/cron-apt/action.d
sudo rm 3-download
sudo aptitude safe-upgrade -y quiet=2

# Set the batman_adv module to auto start on reboot
echo " Setting BATMAN-adv to auto start on reboot "
#sudo sh -c "echo batman_adv >> /etc/modules"
sudo sh -c "echo batman_adv >> /etc/rc.local"

# Displays ip for debugging purposes
echo " SETUP COMPLETE NOW DISPLAYING INFO FOR DEBUGGING "
ifconfig|grep Bcast

# Shows nodes on the mesh will be empy if you have not set a node yet
sudo batctl o

echo "Holy scripts Batman that was easier than I thought - Robin"
cat << "EOF"
                                          .      .
                                 ./       |      |        \.
                               .:(        |i __ j|        ):`.
                             .'   `._     |`::::'|     _.'    `.
                           .'        "---.j `::' f.---"         `.
                     _____/     ___  ______      __    __   ___   \_   __
                    |      \   |   ||      |`__'|  \  /  | |   | |" \ |  |
                    |  .-.  | .'   `|_    _|\--/|   \/   |.'   `.|   \|  |
                    |  |_|  | |  i  | |  |  :"":|        ||  i  ||    |  |
                    |       / | .^. | |  |  ::::|        || .^. ||       |
                    |  .-.  \ | | | | |  |   :: |        || | | ||  |\   |
                    |  | |  |.' """ `.|  |      |  i  i  j' """ `.  | \  | LS
                    |  `-'  ||   _   ||  |      |  |\/|  |   _   |  | [  |
                   [|      / |  | |  ||  |      |  |  |  |  | |  |  | |  |].
                  ] `-----'  :--' `--::--'      `--' ::--"--::`--"--' `--':[
                  |      __  ::-"""`.:' "--.    .----::.----:: ,.---._    :|
                  [  .-""  "`'              \  /      "      `'       `-. :].
                 ]:.'                        \/                          `.:[
                 |/                                                        \|
EOF

# References
# https://sudoroom.org/wiki/Mesh/Server_security
# https://jshi-lab.assembla.com/spaces/social-sight/wiki/ODROID_XU3_Setup?version=9
# http://ascii.co.uk/art/batman
# https://downloads.open-mesh.org/batman/manpages/batctl.8.html
# https://www.thinkpenguin.com/gnu-linux/how-configure-wifi-card-using-command-line-or-terminal
# http://pastebin.com/4U9vdFFm
# https://www.open-mesh.org/projects/batman-adv/wiki/Tweaking
