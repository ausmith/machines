#!/bin/bash

set -euo pipefail

apt-get install -y npm nodejs-legacy
# TODO: figure out why we cannot use npm latest
#npm install npm@latest -g

mkdir -p /var/www
cd /var/www
git clone https://github.com/ausmith/resume.git app
cd app
npm install --production

cat > /etc/nginx/sites-enabled/ausmithme.conf << "HEREDOC"
server {
  listen      8080;
  server_name ausmith.me;

  location ~ ^/(images/|js/|css/|fonts/|favicon.ico|opensearch.xml|robots.txt|humans.txt) {
    root /var/www/app/public;
    access_log off;
    expires max;
  }

  location / {
    proxy_redirect      off;
    proxy_set_header    Connection "";
    proxy_set_header    Host $http_host;
    proxy_set_header    X-Real-IP $remote_addr;
    proxy_set_header    x-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header    X-Forwarded-Proto $scheme;
    proxy_http_version  1.1;
    proxy_cache_key     nx$request_uri$scheme;
    proxy_pass          http://127.0.0.1:3000;
  }
}
HEREDOC

cat > /etc/systemd/system/ausmithme.service << HEREDOC
[Unit]
Description=ausmith.me site serve

[Service]
Restart=always
ExecStart=/usr/bin/nodejs ./bin/www
WorkingDirectory=/var/www/app
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=ausmith.me

[Install]
WantedBy=multi-user.target
HEREDOC

systemctl enable ausmithme.service
