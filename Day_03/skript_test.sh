#!/bin/bash

sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat <<EOF | sudo tee /etc/yum.repos.d/elasticsearch.repo
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md'
EOF

sudo yum install --enablerepo=elasticsearch elasticsearch -y
sudo systemctl daemon-reload
# sed -i "s/#network.host: 192.168.0.1/network.host: 127.0.0.1/" /etc/elasticsearch/elasticsearch.yml
sudo sed -i '$ a \network.host: "0.0.0.0"' /etc/elasticsearch/elasticsearch.yml
sudo sed -i '$ a \discovery.seed_hosts: ["127.0.0.1", "[::1]"]' /etc/elasticsearch/elasticsearch.yml
# systemctl restart elasticsearch.service
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service

sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat <<EOF | sudo tee /etc/yum.repos.d/kibana.repo
[kibana-7.x]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md' > /etc/yum.repos.d/kibana.repo
EOF

sudo firewall-cmd --permanent --zone=public --add-port=5601/tcp
sudo firewall-cmd --permanent --zone=public --add-port=9200/tcp
sudo firewall-cmd --reload

sudo yum install kibana -y
sudo sed -i '$ a \server.host: "0.0.0.0"' /etc/kibana/kibana.yml
# sudo systemctl daemon-reload
sudo systemctl enable kibana.service
sudo systemctl start kibana.service
