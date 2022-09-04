#!/bin/bash

prompt="Please enter your choice: "

echo " ██████  ██ ████████ ██       █████  ██████      ███████  █████  ███████ ██    ██     ███████ ████████  █████  ██████  ████████ ███████ ██████  "
echo "██       ██    ██    ██      ██   ██ ██   ██     ██      ██   ██ ██       ██  ██      ██         ██    ██   ██ ██   ██    ██    ██      ██   ██ "
echo "██   ███ ██    ██    ██      ███████ ██████      █████   ███████ ███████   ████       ███████    ██    ███████ ██████     ██    █████   ██████  "
echo "██    ██ ██    ██    ██      ██   ██ ██   ██     ██      ██   ██      ██    ██             ██    ██    ██   ██ ██   ██    ██    ██      ██   ██ "
echo " ██████  ██    ██    ███████ ██   ██ ██████      ███████ ██   ██ ███████    ██        ███████    ██    ██   ██ ██   ██    ██    ███████ ██   ██ "
echo "                                                                                                                                                "
echo "                                                          Made By SudoIt                                                                        "
echo "
                                                                                                                                               "
read -r -p "Do you use docker desktop? [y/N] " dockerDesktop

OPTIONS=(
  "Make Require Directories"
  "Pull Images"
  "Run Gitlab (Postgres And Redis) Containers"
  "Run Gitlab Container"
  "Run LDAP Containers"
  "Create SSL For GitLab"
  "Set DNS"
  "Install Docker Engine"
)

PS3="$prompt "

select opt in "${OPTIONS[@]}" "Quit"; do
  case "$REPLY" in

  1)
    read -r -p "Enter Your Linux UserName For Giving Permission: " userName

    read -r -p "Are You SELinux users? [y/N] " responseSELinux
    if [[ "$responseSELinux" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      sudo mkdir -pv /srv
      sudo chown -R "$userName":"$userName" /srv
      mkdir -pv /srv/docker/gitlab/redis
      mkdir -pv /srv/docker/gitlab/postgresql
      mkdir -pv /srv/docker/gitlab/gitlab
      #sudo setfacl -R -m u:sudoit:rwx /srv/docker/gitlab
      #sudo chmod -R a+X /srv/docker/gitlab
      sudo chmod -R a+X /srv/docker/gitlab
      sudo chcon -Rt svirt_sandbox_file_t /srv/docker/gitlab/redis
      sudo chcon -Rt svirt_sandbox_file_t /srv/docker/gitlab/postgresql
      sudo chcon -Rt svirt_sandbox_file_t /srv/docker/gitlab/gitlab
      sudo chcon -Rt svirt_sandbox_file_t /srv/docker/ldap/ldap
      sudo chcon -Rt svirt_sandbox_file_t /srv/docker/ldap/slapd.d
      sudo chcon -Rt svirt_sandbox_file_t /srv/docker/ldap/certs
    else
      sudo mkdir -pv /srv/docker
      sudo chown -R "$userName":"$userName" /srv
      mkdir -pv /srv/docker/ldap/ldap
      mkdir -pv /srv/docker/ldap/slapd.d
      mkdir -pv /srv/docker/ldap/certs
      mkdir -pv /srv/docker/gitlab/redis
      mkdir -pv /srv/docker/gitlab/postgresql
      mkdir -pv /srv/docker/gitlab/gitlab
    fi
    echo "Done"
    ;;

  2)
    echo "Pull Images...."
    if [[ "$dockerDesktop" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      docker pull postgres:14.5
      docker pull redis:7.0.4
      docker pull sameersbn/gitlab:15.3.1
      docker pull osixia/openldap:1.5.0
      docker pull osixia/phpldapadmin:latest
      echo "Done"
    else
      sudo docker pull postgres:14.5
      sudo docker pull redis:7.0.4
      sudo docker pull sameersbn/gitlab:15.3.1
      sudo docker pull osixia/openldap:1.5.0
      sudo docker pull osixia/phpldapadmin:latest
      echo "Done"
    fi
    ;;

  3)
    echo "you chose choice $REPLY which is $opt"
    echo "Run Gitlab Postgres...."
    read -r -p "Enter A Password For Postgres " postgresPass
    read -r -p "Enter Database Time Zone " timeZone
    echo "Example: Asia/Tehran"
    if [[ "$dockerDesktop" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      docker run --name gitlab-postgresql -d --restart always \
        --env POSTGRES_DB="gitlabhq_production" \
        --env POSTGRES_USER="gitlab" \
        --env POSTGRES_PASSWORD="$postgresPass" \
        --env TZ="$timeZone" \
        --volume /srv/docker/gitlab/postgresql:/var/lib/postgresql \
        postgres:14.5

      echo "Run Gitlab Redis...."
      docker run --name gitlab-redis -d --restart always \
        --volume /srv/docker/gitlab/redis:/data \
        redis:7.0.4
      echo "Done"
    else
      sudo docker run --name gitlab-postgresql -d --restart always \
        --env POSTGRES_DB="gitlabhq_production" \
        --env POSTGRES_USER="gitlab" \
        --env POSTGRES_PASSWORD="$postgresPass" \
        --env TZ="$timeZone" \
        --volume /srv/docker/gitlab/postgresql:/var/lib/postgresql \
        postgres:14.5

      echo "Run Gitlab Redis...."
      sudo docker run --name gitlab-redis -d --restart always \
        --volume /srv/docker/gitlab/redis:/data \
        redis:7.0.4
      echo "Done"
    fi
    ;;

  4)
    echo "you chose choice $REPLY which is $opt"
    echo "Run Gitlab...."
    if [[ "$dockerDesktop" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      docker run --name gitlab -d --restart always \
        --link gitlab-postgresql:postgresql --link gitlab-redis:redisio \
        --publish 8022:22 --publish 8040:80 \
        --env DB_USER="gitlab" \
        --env DB_PASS="hoSP3g5KY*oN87ZSVdZQEwi9f%L" \
        --env DB_NAME="gitlabhq_production" \
        --env GITLAB_PORT="8040" \
        --env GITLAB_SSH_PORT="8022" \
        --env GITLAB_HOST="localhost" \
        --env GITLAB_SECRETS_DB_KEY_BASE="dPjHvKh7w4nNJsmKbfVXqN9M7NT4PwnwjJrdx7kH9kL4zT4WcLHWPqzvXjtpF3k3" \
        --env GITLAB_SECRETS_SECRET_KEY_BASE="m7gMdV3TT7kPx9sRhr3r7dsnc7Xrmst3TPRXdLt4VVbcbfbRsH3Ldc7K4fmqvNWM" \
        --env GITLAB_SECRETS_OTP_KEY_BASE="q7fMdm3FtvqCcphxvpHnp9mjKzc4qV9ntMtmHKj93vmsvN9LmczPjM3NThV7n9qp" \
        --env NGINX_HSTS_MAXAGE="2592000" \
        --env TZ="Asia/Tehran" \
        --env GITLAB_TIMEZONE="Tehran" \
        --env GITLAB_BACKUP_SCHEDULE="weekly" \
        --env GITLAB_BACKUP_TIME="02:00" \
        --env LDAP_ENABLED="true" \
        --env OAUTH_AUTO_LINK_LDAP_USER="true" \
        --env LDAP_HOST="localhost" \
        --env LDAP_PASS="hj^degD6$3gK*6^aWcS3" \
        --volume /srv/docker/gitlab/gitlab:/home/git/data \
        sameersbn/gitlab:15.3.1
      docker logs -f gitlab
      echo "Done"
    else
      sudo docker run --name gitlab -d --restart always \
        --link gitlab-postgresql:postgresql --link gitlab-redis:redisio \
        --publish 8022:22 --publish 8040:80 \
        --env DB_USER="gitlab" \
        --env DB_PASS="hoSP3g5KY*oN87ZSVdZQEwi9f%L" \
        --env DB_NAME="gitlabhq_production" \
        --env GITLAB_PORT="8040" \
        --env GITLAB_SSH_PORT="8022" \
        --env GITLAB_HOST="localhost" \
        --env GITLAB_SECRETS_DB_KEY_BASE="dPjHvKh7w4nNJsmKbfVXqN9M7NT4PwnwjJrdx7kH9kL4zT4WcLHWPqzvXjtpF3k3" \
        --env GITLAB_SECRETS_SECRET_KEY_BASE="m7gMdV3TT7kPx9sRhr3r7dsnc7Xrmst3TPRXdLt4VVbcbfbRsH3Ldc7K4fmqvNWM" \
        --env GITLAB_SECRETS_OTP_KEY_BASE="q7fMdm3FtvqCcphxvpHnp9mjKzc4qV9ntMtmHKj93vmsvN9LmczPjM3NThV7n9qp" \
        --env NGINX_HSTS_MAXAGE="2592000" \
        --env TZ="Asia/Tehran" \
        --env GITLAB_TIMEZONE="Tehran" \
        --env GITLAB_BACKUP_SCHEDULE="weekly" \
        --env GITLAB_BACKUP_TIME="02:00" \
        --env LDAP_ENABLED="true" \
        --env OAUTH_AUTO_LINK_LDAP_USER="true" \
        --env LDAP_HOST="localhost" \
        --env LDAP_PASS="hj^degD6$3gK*6^aWcS3" \
        --volume /srv/docker/gitlab/gitlab:/home/git/data \
        sameersbn/gitlab:15.3.1
      sudo docker logs -f gitlab
      echo "Done"
    fi
    ;;

  5)
    echo "you chose choice $REPLY which is $opt"

    echo "Run LDAP...."
    if [[ "$dockerDesktop" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      docker run -p 389:389 -p 636:636 --name openldap-haytech \
        --env LDAP_ORGANISATION="HayTech" \
        --env LDAP_DOMAIN="haytech.ir" \
        --env LDAP_ADMIN_PASSWORD="hj^degD63gK*6^aWcS3" \
        --env LDAP_CONFIG_PASSWORD="FHELX!6yUDBwjT56rMT" \
        --env LDAP_BACKEND="mdb" \
        --env LDAP_TLS="true" \
        --env LDAP_TLS_CRT_FILENAME="ldap.crt" \
        --env LDAP_TLS_KEY_FILENAME="ldap.key" \
        --env LDAP_TLS_DH_PARAM_FILENAME="dhparam.pem" \
        --env LDAP_TLS_CA_CRT_FILENAME="ca.crt" \
        --env LDAP_TLS_ENFORCE="false" \
        --env LDAP_TLS_CIPHER_SUITE="SECURE256:-VERS-SSL3.0" \
        --env LDAP_TLS_VERIFY_CLIENT="demand" \
        --env LDAP_REPLICATION="false" \
        --env KEEP_EXISTING_CONFIG="false" \
        --env LDAP_REMOVE_CONFIG_AFTER_SETUP="true" \
        --env LDAP_SSL_HELPER_PREFIX="ldap" \
        --volume /srv/docker/ldap/ldap:/var/lib/ldap \
        --volume /srv/docker/ldap/slapd.d:/etc/ldap/slapd.d \
        --volume /srv/docker/ldap/certs:/container/service/slapd/assets/certs/ \
        --detach osixia/openldap:1.5.0

      echo "Run PHP_LDAP_ADMIN...."
      docker run -p 8010:80 --name phpldap-admin-haytech \
        --env 'PHPLDAPADMIN_LDAP_HOSTS=openldap' \
        --env 'PHPLDAPADMIN_HTTPS=false' \
        osixia/phpldapadmin:latest
      echo "Done"
    else
      sudo docker run -p 389:389 -p 636:636 --name openldap-haytech \
        --env LDAP_ORGANISATION="HayTech" \
        --env LDAP_DOMAIN="haytech.ir" \
        --env LDAP_ADMIN_PASSWORD="hj^degD63gK*6^aWcS3" \
        --env LDAP_CONFIG_PASSWORD="FHELX!6yUDBwjT56rMT" \
        --env LDAP_BACKEND="mdb" \
        --env LDAP_TLS="true" \
        --env LDAP_TLS_CRT_FILENAME="ldap.crt" \
        --env LDAP_TLS_KEY_FILENAME="ldap.key" \
        --env LDAP_TLS_DH_PARAM_FILENAME="dhparam.pem" \
        --env LDAP_TLS_CA_CRT_FILENAME="ca.crt" \
        --env LDAP_TLS_ENFORCE="false" \
        --env LDAP_TLS_CIPHER_SUITE="SECURE256:-VERS-SSL3.0" \
        --env LDAP_TLS_VERIFY_CLIENT="demand" \
        --env LDAP_REPLICATION="false" \
        --env KEEP_EXISTING_CONFIG="false" \
        --env LDAP_REMOVE_CONFIG_AFTER_SETUP="true" \
        --env LDAP_SSL_HELPER_PREFIX="ldap" \
        --volume /srv/docker/ldap/ldap:/var/lib/ldap \
        --volume /srv/docker/ldap/slapd.d:/etc/ldap/slapd.d \
        --volume /srv/docker/ldap/certs:/container/service/slapd/assets/certs/ \
        --detach osixia/openldap:1.5.0

      echo "Run PHP_LDAP_ADMIN...."
      sudo docker run -p 8010:80 --name phpldap-admin-haytech \
        --env 'PHPLDAPADMIN_LDAP_HOSTS=openldap' \
        --env 'PHPLDAPADMIN_HTTPS=false' \
        osixia/phpldapadmin:latest
      echo "Done"
    fi
    ;;

  6)
    read -r -p "Do You Create SSL? [y/N] " responseSSL
    if [[ "$responseSSL" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      openssl genrsa -out gitlab.key 2048
      openssl req -new -key gitlab.key -out gitlab.csr
      openssl x509 -req -days 3650 -in gitlab.csr -signkey gitlab.key -out gitlab.crt
      openssl dhparam -out dhparam.pem 2048
    fi
    read -r -p "Copy SSL Stuffs To Gitlab Directory?? [y/N] " responseSSLCP
    if [[ "$responseSSLCP" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      mkdir -pv /srv/docker/gitlab/gitlab/certs
      cp gitlab.key /srv/docker/gitlab/gitlab/certs
      cp gitlab.crt /srv/docker/gitlab/gitlab/certs
      cp dhparam.pem /srv/docker/gitlab/gitlab/certs
      #  chmod 400 /srv/docker/gitlab/gitlab/certs/certsgitlab.key
    fi
    echo "Done"
    ;;
  7)
    echo "nameserver 178.22.122.100
nameserver 185.51.200.2" | sudo tee -a /etc/resolv.conf
    echo "Done"
    ;;

  8)
    sudo apt-get update
    sudo apt-get install \
      ca-certificates \
      curl \
      gnupg \
      lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
    echo "Done"
    ;;

  9)
    break
    ;;

  *) echo "Invalid option $REPLY" ;;

  esac
  REPLY=

done
