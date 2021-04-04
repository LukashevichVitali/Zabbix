#!/bin/bash

password=ghksIlld2

sudo yum install openldap openldap-servers openldap-clients -y
sudo systemctl start slapd
sudo systemctl enable slapd
sudo slappasswd -s $password > /tmp/hash
sed -i "s|\${PASSWORD\}|$(cat /tmp/hash)|g" /tmp/ldap/ldaprootpasswd.ldif /tmp/ldap/ldapdomain.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/ldap/ldaprootpasswd.ldif
sudo cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
sudo chown -R ldap:ldap /var/lib/ldap/DB_CONFIG
sudo systemctl restart slapd
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/ldap/ldapdomain.ldif
sudo ldapadd -x -D "cn=Manager,dc=devopsldab,dc=com" -w $password -f /tmp/ldap/baseldapdomain.ldif
sudo ldapadd -x -D "cn=Manager,dc=devopsldab,dc=com" -w $password -f /tmp/ldap/ldapgroup.ldif
sudo ldapadd -x -D "cn=Manager,dc=devopsldab,dc=com" -w $password -f /tmp/ldap/ldapuser.ldif

sudo yum install -y epel-release
sudo yum install -y phpldapadmin
sudo sed -i "397s%// %%" /etc/phpldapadmin/config.php
sudo sed -i "398s%^%// %" /etc/phpldapadmin/config.php
sudo sed -i "11 aRequire ip 134.17.128.10/32" /etc/httpd/conf.d/phpldapadmin.conf
sudo systemctl restart httpd