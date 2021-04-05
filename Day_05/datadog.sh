#!/bin/bash

DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=0701c40915c531a3b229f0bf1b045d59 DD_SITE="datadoghq.eu" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"

sudo yum install -y httpd
sudo cat >> /etc/httpd/conf/httpd.conf <<_EOF_
<Location /server-status>
    SetHandler server-status
    Order Deny,Allow
    Deny from all
    Allow from 127.0.0.1
</Location>
ExtendedStatus On
EOF
_EOF_
sudo systemctl enable httpd
sudo systemctl start httpd

sudo cat >> /etc/datadog-agent/conf.d/apache.d/conf.yaml.example <<_EOF_
logs:
  - type: file
    path: /var/log/httpd/access_log
    source: apache
    sourcecategory: http_web_access
    service: apache
  - type: file
    path: /var/log/httpd/error_log
    source: apache
    sourcecategory: http_web_access
    service: apache
_EOF_

sudo chmod 655 -R /var/log/httpd
sudo systemctl restart datadog-agent