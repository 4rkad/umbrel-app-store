#!/usr/bin/env bash

export APP_MYSQL_PASSWORD=$(derive_entropy "app-4rkad-labelbase-mysql-user-password")
export APP_MYSQL_ROOT_PASSWORD=$(derive_entropy "app-4rkad-labelbase-mysql-root-password")
export APP_DJANGO_SECRET_KEY=$(derive_entropy "app-4rkad-labelbase-django-secret-key")
export APP_DJANGO_CRYPTO_SALT=$(derive_entropy "app-4rkad-labelbase-django-crypto-salt")

DATA_DIR="${EXPORTS_APP_DIR}/data"
mkdir -p "${DATA_DIR}/mysql" "${DATA_DIR}/static" "${DATA_DIR}/media"
touch "${DATA_DIR}/labelbase.log"
chown -R 1000:1000 "${DATA_DIR}"

CONFIG_FILE="${DATA_DIR}/config.ini"
if [ ! -f "${CONFIG_FILE}" ]; then
  cat > "${CONFIG_FILE}" <<EOF
[internal]
secret_key = ${APP_DJANGO_SECRET_KEY}
proj_name = labelbase
crypto_salt = labelbase_${APP_DJANGO_CRYPTO_SALT}_
allowed_host = *
debug = False
current_timestamp_seconds = 0
self_hosted = True
sentry_dsn =

[database]
name = labelbase
user = ulabelbase
password = ${APP_MYSQL_PASSWORD}
host = 4rkad-labelbase_mysql_1
port = 3306
EOF
fi

NGINX_FILE="${DATA_DIR}/nginx.conf"
if [ ! -f "${NGINX_FILE}" ]; then
  cat > "${NGINX_FILE}" <<'EOF'
worker_processes 1;
events { worker_connections 1024; }

http {
  include       mime.types;
  default_type  application/octet-stream;
  sendfile      on;
  keepalive_timeout 65;

  upstream labelbase_django {
    server 4rkad-labelbase_django_1:8000;
  }

  server {
    listen 8080;
    client_max_body_size 100M;
    server_name _;
    charset utf-8;

    location /static { alias /app/static; autoindex off; }
    location /media  { alias /app/media;  autoindex off; }

    location / {
      proxy_pass http://labelbase_django;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_buffers 4 32k;
      proxy_buffer_size 32k;
    }
  }
}
EOF
fi
