#!/bin/bash

TIMEZONE_REGION="Europe"
TIMEZONE_CITY="Minsk"
SERVER_IP=$(hostname -I | cut -d' ' -f1)
SERVER_NAME=$(hostname)
DB_ZAB_PASS="4faadrDS"
DB_ROOT_PASS="4faadrDS"

sudo yum install epel-release yum-utils net-tools nano policycoreutils-python wget -y

sudo rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
sudo yum-config-manager --enable rhel-7-server-optional-rpms

sudo yum install mariadb mariadb-server -y

sudo touch /etc/my.cnf.d/innolog.conf

sudo cat >> /etc/my.cnf.d/innolog.conf <<_EOF_
# Innodb
innodb_file_per_table
#
innodb_log_group_home_dir = /var/lib/mysql/
innodb_buffer_pool_size = 4G
innodb_additional_mem_pool_size = 16M
#
innodb_log_files_in_group = 2
innodb_log_file_size=512M
innodb_log_buffer_size = 8M
innodb_lock_wait_timeout = 120
#
innodb_thread_concurrency = 4
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
#
#wsrep_provider_options="gcache.size=128M"
_EOF_


sudo systemctl enable mariadb && systemctl start mariadb

sudo mysql --user=root <<_EOF_
  UPDATE mysql.user SET Password=PASSWORD('${DB_ROOT_PASS}') WHERE User='root';
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
  FLUSH PRIVILEGES;
_EOF_

sudo cat <<EOF | mysql -uroot -p$DB_ROOT_PASS
create database zabbix character set utf8 collate utf8_bin;
grant all privileges on zabbix.* to zabbix@localhost identified by '${DB_ZAB_PASS}';
flush privileges;
EOF

sudo yum install zabbix-server-mysql zabbix-agent zabbix-web-mysql -y

# Import zabbix default db to zabbix database
ZABB_MYSQL_VERSION=$(zabbix_server_mysql --version | head -1 | awk '{print $3}')

sudo zcat /usr/share/doc/zabbix-server-mysql-$ZABB_MYSQL_VERSION/create.sql.gz | mysql -uroot -p$DB_ROOT_PASS zabbix

sudo sed -i 's/# DBHost=.*/DBHost=localhost/' /etc/zabbix/zabbix_server.conf
sudo sed -i 's/# DBName=.*/DBName=zabbix/' /etc/zabbix/zabbix_server.conf
sudo sed -i 's/# DBUser=.*/DBUser=zabbix/' /etc/zabbix/zabbix_server.conf
sudo sed -i "s/# DBPassword=.*/DBPassword="$DB_ZAB_PASS"/" /etc/zabbix/zabbix_server.conf

sudo sed -i 's/^\(max_execution_time\).*/\1 = 300/' /etc/php.ini
sudo sed -i 's/^\(memory_limit\).*/\1 = 128M/' /etc/php.ini
sudo sed -i 's/^\(post_max_size\).*/\1 = 16M/' /etc/php.ini
sudo sed -i 's/^\(upload_max_filesize\).*/\1 = 2M/' /etc/php.ini
sudo sed -i 's/^\(max_input_time\).*/\1 = 300/' /etc/php.ini
sudo sed -i "s/^\;date.timezone.*/date.timezone = \'"$TIMEZONE_REGION"\/"$TIMEZONE_CITY"\'/" /etc/php.ini

sudo firewall-cmd --permanent --zone=public --add-port=10050/tcp
sudo firewall-cmd --permanent --zone=public --add-port=10051/tcp
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload

sudo setenforce 0
sudo sed -i "s/^\(SELINUX\).*/\1="disabled"/" /etc/selinux/config

sudo systemctl enable zabbix-server && systemctl start zabbix-server
sudo systemctl enable httpd && systemctl start httpd
sudo systemctl enable zabbix-agent && systemctl start zabbix-agent
