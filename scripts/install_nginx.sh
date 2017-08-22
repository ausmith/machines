#!/bin/bash

set -euo pipefail

apt-get install -y nginx

# Possible network tweak from ponyfoo.com/articles/immutable-deployments-packer
# sysctl -w net.ipv4.tcp_slow_start_after_idle=0

# ipv4 forwarding
cp /etc/sysctl.conf /tmp/.
echo "net.ipv4.ip_forward = 1" >> /tmp/sysctl.conf
cp /tmp/sysctl.conf /etc/.
sysctl -p /etc/sysctl.conf

# 80 -> 8080
iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 8080
iptables -A INPUT -p tcp -m tcp --sport 80 -j ACCEPT
iptables -A OUTPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables-save > /tmp/iptables-store.conf
mv /tmp/iptables-store.conf /etc/iptables-store.conf

# Always remember port forwarding
cat > /tmp/iptables-ifupd << HEREDOC
#!/bin/bash
iptables-restore < /etc/iptables-store.conf
HEREDOC
chmod +x /tmp/iptables-ifupd
mv /tmp/iptables-ifupd /etc/network/if-up.d/iptables

# Setup nginx.conf
cat > /etc/nginx/nginx.conf << "HEREDOC"
user              www-data;
worker_processes  4;

error_log /var/log/nginx/error.log;
pid       /var/run/nginx.pid;

events {
  worker_connections  1024;
}

http {
  proxy_cache_path  /var/cache/nginx levels=1:2 keys_zone=one:8m max_size=3000m inactive=600m;
  proxy_temp_path   /var/tmp;
  include           mime.types;
  default_type      application/octet-stream;
  sendfile          on;
  keepalive_timeout 65;
  server_tokens     off;

  gzip            on;
  gzip_comp_level 6;
  gzip_vary       on;
  gzip_min_length 1000;
  gzip_proxied    any;
  gzip_types      text/plain text/css application/json application/x-javascript text/javascript text/xml application/xml application/xml+rss images/x-icon;
  gzip_buffers    16 8k;

  log_format main '$remote_addr - $host [$time_local] "$request" '
                  '$status $body_bytes_sent "$http_referer" '
                  '"$http_user_agent"';

  access_log /var/log/nginx/access.log combined;

  include /etc/nginx/sites-enabled/*;
}
HEREDOC

rm /etc/nginx/sites-enabled/default

# Run at system startup
systemctl enable nginx.service
