#! /bin/bash
# 
# Desc : if you working on a public network you might want to
#        filter only with your network/ip_address. 
#
  
# enable firewalld 
yum install -y firewalld
sudo systemctl start firewalld.service

# filter traffic
#sudo firewall-cmd --zone=public --permanent --add-source=YOUR_IP/32
# or 
#sudo firewall-cmd --zone=public --permanent --add-source=YOUR_NETWORK/MASK  
# hadoop port
#sudo firewall-cmd --zone=public --permanent --add-port=8020,8088,8030,8031,8032,8033
