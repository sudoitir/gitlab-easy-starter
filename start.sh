#!/bin/bash
echo "Start..............."
read -r -p "Do You Want To Make Require Directories? [y/N] " responseDir
if [[ "$responseDir" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  read -r -p "Are You SELinux users? [y/N] " responseSELinux
  if [[ "$responseSELinux" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    sudo mkdir -pv /srv/docker/gitlab/redis-data
    sudo mkdir -pv /srv/docker/gitlab/postgresql-data
    sudo mkdir -pv /srv/docker/gitlab/gitlab-data
    sudo setfacl -R -m u:sudoit:rwx /srv/docker/gitlab
    sudo chcon -Rt svirt_sandbox_file_t /srv/docker/gitlab/redis-data
    sudo chcon -Rt svirt_sandbox_file_t /srv/docker/gitlab/postgresql-data
    sudo chcon -Rt svirt_sandbox_file_t /srv/docker/gitlab/gitlab-data
  else
    sudo mkdir -pv /srv/docker/gitlab/redis-data
    sudo mkdir -pv /srv/docker/gitlab/postgresql-data
    sudo mkdir -pv /srv/docker/gitlab/gitlab-data
    sudo setfacl -R -m u:sudoit:rwx /srv/docker/gitlab
  fi
fi
read -r -p "Do You Create SSL? [y/N] " responseSSL
if [[ "$responseSSL" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  sudo apt install openssl -y
  openssl genrsa -out gitlab.key 2048
  openssl req -new -key gitlab.key -out gitlab.csr
  openssl x509 -req -days 3650 -in gitlab.csr -signkey gitlab.key -out gitlab.crt
  openssl dhparam -out dhparam.pem 2048
fi
read -r -p "Copy SSL Stuffs To Gitlab Directory?? [y/N] " responseSSLCP
if [[ "$responseSSLCP" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  mkdir -pv /srv/docker/gitlab/gitlab-data/certs
  cp gitlab.key /srv/docker/gitlab/gitlab-data/certs
  cp gitlab.crt /srv/docker/gitlab/gitlab-data/certs
  cp dhparam.pem /srv/docker/gitlab/gitlab-data/certs
  #  chmod 400 /srv/docker/gitlab/gitlab-data/certs/certsgitlab.key
fi
read -r -p "Do You Want To Create Containers? [y/N] " responseDocker
if [[ "$responseDocker" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  docker run --name gitlab-postgresql -d --restart always \
    --env 'DB_NAME=gitlab_haytech' \
    --env 'DB_USER=gitlab' \
    --env 'DB_PASS=hoS$P3g5KY*oN87ZSVdZQEwi9f%L' \
    --env 'DB_EXTENSION=pg_trgm,btree_gist' \
    -v /srv/docker/gitlab/postgresql-data:/var/lib/postgresql \
    sameersbn/postgresql:12-20200524
  docker run --name gitlab-redis -d --restart always \
    -v /srv/docker/gitlab/redis-data:/data \
    redis:6.2
  docker run --name gitlab -d --restart always \
    --link gitlab-postgresql:postgresql --link gitlab-redis:redisio \
    --publish 8022:22 --publish 8020:80 --publish 8443:443 \
    --env 'GITLAB_PORT=8020' --env 'GITLAB_SSH_PORT=8022' --env 'GITLAB_HOST=localhost' \
    --env 'GITLAB_SECRETS_DB_KEY_BASE=dPjHvKh7w4nNJsmKbfVXqN9M7NT4PwnwjJrdx7kH9kL4zT4WcLHWPqzvXjtpF3k3' \
    --env 'GITLAB_SECRETS_SECRET_KEY_BASE=m7gMdV3TT7kPx9sRhr3r7dsnc7Xrmst3TPRXdLt4VVbcbfbRsH3Ldc7K4fmqvNWM' \
    --env 'GITLAB_SECRETS_OTP_KEY_BASE=q7fMdm3FtvqCcphxvpHnp9mjKzc4qV9ntMtmHKj93vmsvN9LmczPjM3NThV7n9qp' \
    --env 'DEBUG=false' --env 'DB_ADAPTER=postgresql' --env 'DB_HOST=postgresql' --env 'DB_PORT=5432' \
    --env 'DB_USER=gitlab' --env 'DB_PASS=hoS$P3g5KY*oN87ZSVdZQEwi9f%L' --env 'DB_NAME=gitlab_haytech' \
    --env 'NGINX_HSTS_MAXAGE=2592000' --env 'REDIS_HOST=redis' --env 'REDIS_PORT=6379' \
    --env 'TZ=Asia/Tehran' --env 'GITLAB_TIMEZONE=Tehran' --env 'GITLAB_HTTPS=true' --env 'SSL_SELF_SIGNED=true' \
    --env 'GITLAB_ROOT_PASSWORD=' --env 'GITLAB_ROOT_EMAIL=' \
    --env 'GITLAB_BACKUP_SCHEDULE=weekly' --env 'GITLAB_BACKUP_TIME=02:00' \
    -v /srv/docker/gitlab/gitlab-data:/home/git/data \
    sameersbn/gitlab:15.0.3
  docker logs -f gitlab
fi
