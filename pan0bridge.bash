#!/bin/bash

#if using a raspberry pi or other similar device running a linux distro 
#make sure to resize image using sudo raspi-config
#may require sudo sed -i -e 's/\r$//' FILENAME.bash (Replace FILENAME with whatever you called the file) to work
#may need to chmod 777 the file prior to running

# Runs updates and upgrades distro
sudo aptitude update && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y && sudo apt-get install -f

sudo apt-get autoremove

#if using ubuntu uncomment the line bellow
#service network-manager stop

#sudo iwconfig pan0 power off
sudo ifconfig wlan0 down

#read -p 'Please give your node a new hostname:' hostVariable
#hostname $hostVariable
#sudo echo -n $hostVariable > /etc/init.d/hostname.sh
#sudo /etc/init.d/hostname.sh start

# Installs BATMAN-adv
sudo apt-get install batmand -y
#install Bluetooth Personal Area Network Daemon
sudo apt-get install bluetooth bluez-utils blueman -y

sudo sh -c "echo DisablePlugins = pnat >> /etc/bluetooth/main.conf"
#sudo nano /etc/bluetooth/main.conf
#DisablePlugins = pnat

sudo /etc/init.d/bluetooth start

echo bat0 > /sys/class/net/pan0/batman_adv/mesh_iface

# Installs batctl which is a configuration util for 
#BATMAN-adv and then it removes any firewall which might interfere with batman-adv
#sudo apt-get install batctl #iw iptables -y

# installs program to make bridge 
sudo aptitude install bridge-utils -y

sudo sed '65AutoEnable=true' /etc/bluetooth/main.conf

# Connects and sets up the mesh-metwork
echo " Now setting up and configuring Batman-adv Mesh "
#sudo ifconfig pan0 down
#sudo ifconfig pan0 mtu 1532
#sudo iwconfig pan0 enc off
#read -p 'Please give your mesh network an essid or enter essid you wish to create:' essidVariable
#sudo iwconfig pan0 mode ad-hoc essid $essidVariable ap 02:12:34:56:78:9A channel 1
#sudo iwconfig pan0 mode ad-hoc essid my-mesh-network ap 02:12:34:56:78:9A channel 1

sudo bluetoothd -m 1532

# Starts BATMAN-adv
sudo modprobe batman-adv

#ifconfig bnep0 10.0.0.1 netmask 255.255.255.0
#dhcpd3 -cf /tmp/dhcp.conf

#bluetoothd -n -d

sudo batctl if add hci0
sudo hciconfig hci0 up
ifconfig bat0 up

#sudo iwconfig pan0 mode ad-hoc essid my-mesh-network ap 02:12:34:56:78:9A channel 1
#sudo batctl if add pan0
#sudo ip link set up dev pan0
#sudo ip link add name mesh-bridge type bridge
#sudo ip link set dev eth0 master mesh-bridge
#sudo ip link set dev bat0 master mesh-bridge
#sudo ip link set up dev eth0
#sudo ip link set up dev bat0
#sudo ip link set up dev mesh-bridge
#sudo ifconfig pan0 up
#sudo ifconfig bat0 up

#Asks for input to assign ip, this ip is used to assign to your bridge node eg 192.168.1.1 
#read -p 'Please input the ip you want to use for bridge node eg 192.168.2.1: ' ipVariable
#echo "Thank you ${RED}$ipVariable ${GREEN}will now be used TAKE NOTE OF THIS"
#ip_command=`sudo ifconfig bat0 $ipVariable`
#sudo ifconfig bat0 echo $ipVariable

# sets up first node as bridge 
#sudo brctl addbr 192.168.0.1

sudo brctl addbr bridge-link
sudo brctl addif bridge-link bat0
sudo brctl addif bridge-link eth0
sudo ifconfig bridge-link up

#sudo dhclient bridge-link


# Adds bridge loop avoidance
#echo " setting loop avoidance "
#sudo batctl if add pan0
#sudo ip link add name br-lan type bridge
#sudo ip link set dev eth0 master br-lan
#sudo ip link set dev bat0 master br-lan
#sudo ip link set up dev br-lan
#sudo batctl bl 1

# Installs cronjob and runs daily checking for updates for ubuntu/debian OS
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
#sudo sh -c "echo iwconfig wlan0 power off >> /etc/rc.local"
#sudo sh -c "echo iwconfig pan0 power off >> /etc/rc.local"

echo " SETUP COMPLETE NOW DISPLAYING INFO FOR DEBUGGING "

# Displays ip for debugging purposes
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
