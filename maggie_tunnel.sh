#!/bin/bash
########
# Author: Ratish Maruthiyodan
# Project: Docker HDP Lab
# Description: Script to setup an IPIP tunnel between MAC and the SWARM_MANAGER Node, where the Overlay_Gateway runs
########

VPN_INT='utun0'
TUN_INT='gif0'
SWARM_MANAGER='maggie-cluster-n1.openstacklocal'
SWARM_MANAGER_IP='172.26.64.100'
DOCKER_INT_NW='10.0.1.0/24'

ifconfig | grep -q $VPN_INT
if [ $? -eq 0 ]
then
        LOCAL_IP=$(ifconfig $VPN_INT | grep inet | awk '{print $2}')
else
        LOCAL_INT=$(netstat -nr | grep default | awk '{print $6}' | head -n1)
        LOCAL_IP=$(ifconfig $LOCAL_INT | grep "inet " | awk '{print $2}')
fi

echo "Enter $SWARM_MANAGER's root password when prompted"
TUN_INT_NW=`ssh root@$SWARM_MANAGER_IP /opt/docker_cluster/free_tunip.sh $USER $LOCAL_IP`
TUN_INT_IP_OTHER="$TUN_INT_NW.1"
TUN_INT_IP="$TUN_INT_NW.2"

ifconfig | grep -q $VPN_INT
if [ $? -eq 0 ]
then
	#TUN0_IP=$(ifconfig $VPN_INT | grep inet | awk '{print $2}')

	#ifconfig | grep -q $IPIP_TUN_INT
	#if [ $? -eq 0 ]
	#then
	echo "Enter the laptop user password if prompted"
	sudo ifconfig $TUN_INT tunnel $LOCAL_IP $SWARM_MANAGER_IP
	sudo ifconfig $TUN_INT $TUN_INT_IP netmask 255.255.255.0 $TUN_INT_IP_OTHER mtu 1380 up
	sudo route delete -net $DOCKER_INT_NW
	sudo route add -net $DOCKER_INT_NW $TUN_INT_IP_OTHER
else
	echo "Enter the laptop user password if prompted"
	LOCAL_INT=$(netstat -nr | grep default | awk '{print $6}' | head -n1)
	LOCAL_IP=$(ifconfig $LOCAL_INT | grep "inet " | awk '{print $2}')
	sudo ifconfig $TUN_INT tunnel $LOCAL_IP $SWARM_MANAGER_IP
	sudo ifconfig $TUN_INT $TUN_INT_IP netmask 255.255.255.0 $TUN_INT_IP_OTHER mtu 1380 up
	sudo route delete -net $DOCKER_INT_NW
	sudo route add -net $DOCKER_INT_NW $TUN_INT_IP_OTHER
fi
echo -e "\n\tDone !"
