#! /bin/bash
# 
# enable firewalld 
yum install -y firewalld
sudo systemctl start firewalld.service

# filter traffic
#sudo firewall-cmd --zone=public --permanent --add-source=YOUR_IP/32
#sudo firewall-cmd --zone=public --permanent --add-source=YOUR_NETWORK/MASK  

#sudo firewall-cmd --zone=public --permanent --add-port=8020-8050
