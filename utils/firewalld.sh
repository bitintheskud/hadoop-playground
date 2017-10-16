#! /bin/bash
# 
# Desc : if you working on a public network you might want to
#        filter only with your network/ip_address. 
#

  
# enable firewalld 
yum install -y firewalld
sudo systemctl start firewalld.service

# filter traffic
# ok let's live dangerously... 
MY_IP="$(echo $SSH_CLIENT|cut -d' ' -f1)"
sudo firewall-cmd --zone=public --permanent --add-source=${MY_IP}/32 || exit 1
# or 
#sudo firewall-cmd --zone=public --permanent --add-source=YOUR_NETWORK/MASK  


# hadoop port
sudo firewall-cmd --zone=public --permanent --add-port=8030-8033/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8088/tcp
sudo firewall-cmd --zone=public --permanent --add-port=8020/tcp 
sudo firewall-cmd --reload
