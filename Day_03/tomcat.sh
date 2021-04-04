#!/bin/bash

sudo yum install -y tomcat
sudo yum install -y tomcat-webapps tomcat-admin-webapps tomcat-docs-webapp tomcat-javadoc
sudo systemctl enable tomcat
sudo systemctl start tomcat