#!/bin/bash

SERVER_IP=${1}

sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
sudo yum install zabbix-agent -y

sudo sed -i "s/^\(Server=\).*/\1"$SERVER_IP"/" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^\(ServerActive\).*/\1="$SERVER_IP"/" /etc/zabbix/zabbix_agentd.conf
# sudo sed -i "s/^\(Hostname\).*/\1="$HOST_NAME"/" /etc/zabbix/zabbix_agentd.conf

firewall-cmd --permanent  --add-port=10050/tcp
firewall-cmd --reload

systemctl enable zabbix-agent && systemctl start zabbix-agent
