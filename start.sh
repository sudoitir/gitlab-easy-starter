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
read -r -p "Are you using Docker desktop? (If Not Install Press 'n') [y/N] " dockerDesktop

if [[ ! -f ./secrets/db-key.txt || ! -f ./secrets/secrets-key.txt || ! -f ./secrets/otp-key.txt || ! -f ./secrets/postgres-key.txt || ! -f ./secrets/ldap-admin-key.txt || ! -f ./secrets/ldap-config-key.txt ]]; then

  REQUIRED_PKG="pwgen"
  PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")
  echo Checking for $REQUIRED_PKG: "$PKG_OK"
  if [ "" = "$PKG_OK" ]; then
    echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
    echo "Install pwgen for creating secrets..."
    sudo apt-get --yes install $REQUIRED_PKG
  fi

  echo "Some secrets is missing -> Generating new secrets..."

  gitlabSecretsDbKey="$(pwgen -Bsv1 64)"
  gitlabSecretsSecretKey="$(pwgen -Bsv1 64)"
  gitlabSecretsOtpKey="$(pwgen -Bsv1 64)"
  postgresKey="$(pwgen -Bsv1 35)"
  ldapAdminKey="$(pwgen -s 15)"
  ldapConfigKey="$(pwgen -s 15)"

  echo "Secrets are stored in ./secrets directory"

  mkdir -p ./secrets

  echo "$gitlabSecretsDbKey" >>./secrets/db-key.txt
  echo "$gitlabSecretsSecretKey" >>./secrets/secrets-key.txt
  echo "$gitlabSecretsOtpKey" >>./secrets/otp-key.txt
  echo "$postgresKey" >>./secrets/postgres-key.txt
  echo "$ldapAdminKey" >>./secrets/ldap-admin-key.txt
  echo "$ldapConfigKey" >>./secrets/ldap-config-key.txt
fi

timeZoneVar="$(cat /etc/timezone)"
city=$(echo "$timeZoneVar" | cut -d "/" -f 2)
dbKey=$(cat ./secrets/db-key.txt)
secretKey=$(cat ./secrets/secrets-key.txt)
otpKey=$(cat ./secrets/otp-key.txt)
postgresPass=$(cat ./secrets/postgres-key.txt)
ldapAdminSecretKey=$(cat ./secrets/ldap-admin-key.txt)
ldapConfigSecretKey=$(cat ./secrets/ldap-config-key.txt)

OPTIONS=(
  "Install Docker Engine"
  "Make Require Directories"
  "Create SSL For GitLab"
  "Pull Images"
  "Run Gitlab (Postgres And Redis) Containers"
  "Run LDAP Containers"
  "Run Gitlab Container"
  "Set DNS"
)

PS3="$prompt "

select opt in "${OPTIONS[@]}" "Quit"; do
  case "$REPLY" in

  1)
    REQUIRED_PKG="docker-ce"
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")
    echo Checking for $REQUIRED_PKG: "$PKG_OK"
    if [ "" = "$PKG_OK" ]; then
      echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
      sudo apt-get update
      sudo apt-get --yes install \
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
      sudo apt-get --yes install docker-ce docker-ce-cli containerd.io docker-compose-plugin
    fi
    echo "Done"
    ;;

  2)
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

  3)
    read -r -p "Do You Create SSL? [y/N] " responseSSL
    if [[ "$responseSSL" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      openssl genrsa -out gitlab.key 2048
      openssl req -new -key gitlab.key -out gitlab.csr
      openssl x509 -req -days 3650 -in gitlab.csr -signkey gitlab.key -out gitlab.crt
      openssl dhparam -out dhparam.pem 2048
    fi
    read -r -p "Copy SSL Certs To Gitlab Directory?? [y/N] " responseSSLCP
    if [[ "$responseSSLCP" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      mkdir -pv /srv/docker/gitlab/gitlab/certs
      cp gitlab.key /srv/docker/gitlab/gitlab/certs
      cp gitlab.crt /srv/docker/gitlab/gitlab/certs
      cp dhparam.pem /srv/docker/gitlab/gitlab/certs
      #  chmod 400 /srv/docker/gitlab/gitlab/certs/certsgitlab.key
    fi
    echo "Done"
    ;;

  4)
    echo "Pull Images...."
    if [[ "$dockerDesktop" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      docker pull postgres:14.5
      docker pull redis:7.0.4
      docker pull sameersbn/gitlab:15.3.1
      docker pull osixia/openldap:1.5.0
      docker pull wheelybird/ldap-user-manager:v1.5

      echo "Done"
    else
      sudo docker pull postgres:14.5
      sudo docker pull redis:7.0.4
      sudo docker pull sameersbn/gitlab:15.3.1
      sudo docker pull osixia/openldap:1.5.0
      sudo docker pull wheelybird/ldap-user-manager:v1.5
      echo "Done"
    fi
    ;;

  5)
    echo "you chose choice $REPLY which is $opt"
    echo "Run Gitlab Postgres...."
    if [[ "$dockerDesktop" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      docker run --name gitlab-postgresql -d --restart always \
        --env POSTGRES_DB="gitlabhq_production" \
        --env POSTGRES_USER="gitlab" \
        --env POSTGRES_PASSWORD="$postgresPass" \
        --env TZ="$timeZoneVar" \
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
        --env TZ="$timeZoneVar" \
        --volume /srv/docker/gitlab/postgresql:/var/lib/postgresql \
        postgres:14.5

      echo "Run Gitlab Redis...."
      sudo docker run --name gitlab-redis -d --restart always \
        --volume /srv/docker/gitlab/redis:/data \
        redis:7.0.4
      echo "Done"
    fi
    ;;

  6)
    echo "you chose choice $REPLY which is $opt"

    echo "Run LDAP...."
    if [[ "$dockerDesktop" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      read -r -p "Enter Domain before dot, Example = example " domain1
      read -r -p "Enter Domain after dot, Example = org " domain2

      docker run -p 389:389 -p 636:636 --name openldap-haytech --restart always \
        --env LDAP_ORGANISATION="$domain1-$domain2" \
        --env LDAP_DOMAIN="$domain1.$domain2" \
        --env LDAP_RFC2307BIS_SCHEMA="true" \
        --env LDAP_ADMIN_PASSWORD="$ldapAdminSecretKey" \
        --env LDAP_CONFIG_PASSWORD="$ldapConfigSecretKey" \
        --env LDAP_REMOVE_CONFIG_AFTER_SETUP="true" \
        --env LDAP_TLS_VERIFY_CLIENT="never" \
        --volume /srv/docker/ldap/ldap:/var/lib/ldap \
        --volume /srv/docker/ldap/slapd.d:/etc/ldap/slapd.d \
        --volume /srv/docker/ldap/certs:/container/service/slapd/assets/certs/ \
        --detach osixia/openldap:1.5.0

      echo "Info: Exposes Port -> "
      echo "LDAP Ports  : 389 - 636"

      echo "Run PHP_LDAP_ADMIN...."

      docker run -p 8010:80 --name ldap-ui-haytech --restart always --link openldap-haytech:ldapio \
        --env LDAP_URI="ldap://openldap" \
        --env LDAP_BASE_DN="dc=$domain1,dc=$domain2" \
        --env LDAP_REQUIRE_STARTTLS="false" \
        --env LDAP_ADMINS_GROUP="admins" \
        --env LDAP_ADMIN_BIND_DN="cn=admin,dc=$domain1,dc=$domain2" \
        --env LDAP_ADMIN_BIND_PWD="admin" \
        --env LDAP_IGNORE_CERT_ERRORS="true" \
        --env NO_HTTPS="true" \
        --env PASSWORD_HASH="SSHA" \
        --env SERVER_HOSTNAME="localhost:8010" \
        wheelybird/ldap-user-manager:v1.5

      echo "Info: Exposes Port -> "
      echo "LDAP UI  : 8010"

      echo "Done"
    else
      read -r -p "Enter Domain before dot, Example = example " domain1
      read -r -p "Enter Domain after dot, Example = org " domain2

      sudo docker run -p 389:389 -p 636:636 --name openldap-haytech --restart always \
        --env LDAP_ORGANISATION="$domain1-$domain2" \
        --env LDAP_DOMAIN="$domain1.$domain2" \
        --env LDAP_RFC2307BIS_SCHEMA="true" \
        --env LDAP_ADMIN_PASSWORD="$ldapAdminSecretKey" \
        --env LDAP_CONFIG_PASSWORD="$ldapConfigSecretKey" \
        --env LDAP_REMOVE_CONFIG_AFTER_SETUP="true" \
        --env LDAP_TLS_VERIFY_CLIENT="never" \
        --volume /srv/docker/ldap/ldap:/var/lib/ldap \
        --volume /srv/docker/ldap/slapd.d:/etc/ldap/slapd.d \
        --volume /srv/docker/ldap/certs:/container/service/slapd/assets/certs/ \
        --detach osixia/openldap:1.5.0

      echo "Info: Exposes Port -> "
      echo "LDAP Ports  : 389 - 636"

      echo "Run PHP_LDAP_ADMIN...."

      sudo docker run -p 8010:80 --name ldap-ui-haytech --restart always --link openldap-haytech:ldapio \
        --env LDAP_URI="ldap://openldap" \
        --env LDAP_BASE_DN="dc=$domain1,dc=$domain2" \
        --env LDAP_REQUIRE_STARTTLS="false" \
        --env LDAP_ADMINS_GROUP="admins" \
        --env LDAP_ADMIN_BIND_DN="cn=admin,dc=$domain1,dc=$domain2" \
        --env LDAP_ADMIN_BIND_PWD="admin" \
        --env LDAP_IGNORE_CERT_ERRORS="true" \
        --env NO_HTTPS="true" \
        --env PASSWORD_HASH="SSHA" \
        --env SERVER_HOSTNAME="localhost:8010" \
        wheelybird/ldap-user-manager:v1.5

      echo "Info: Exposes Port -> "
      echo "LDAP UI  : 8010"

      echo "Done"
    fi
    ;;

  7)
    echo "you chose choice $REPLY which is $opt"
    echo "Run Gitlab...."

    read -r -p "Select Automatic Backups: (disable, daily, weekly or monthly) " autoBackup
    read -r -p "Enable LDAP ? (true/false)" ldapEnable
    if [[ "$dockerDesktop" =~ ^([yY][eE][sS]|[yY])$ ]]; then
      docker run --name gitlab -d --restart always \
        --link gitlab-postgresql:postgresql --link gitlab-redis:redisio --link openldap-haytech:ldapio \
        --publish 8022:22 --publish 8040:80 \
        --env DB_USER="gitlab" \
        --env DB_PASS="$postgresPass" \
        --env DB_NAME="gitlabhq_production" \
        --env GITLAB_PORT="8040" \
        --env GITLAB_SSH_PORT="8022" \
        --env GITLAB_HOST="localhost" \
        --env GITLAB_SECRETS_DB_KEY_BASE="$dbKey" \
        --env GITLAB_SECRETS_SECRET_KEY_BASE="$secretKey" \
        --env GITLAB_SECRETS_OTP_KEY_BASE="$otpKey" \
        --env NGINX_HSTS_MAXAGE="2592000" \
        --env TZ="$timeZoneVar" \
        --env GITLAB_TIMEZONE="$city" \
        --env GITLAB_BACKUP_SCHEDULE="$autoBackup" \
        --env GITLAB_BACKUP_TIME="02:00" \
        --env LDAP_ENABLED="$ldapEnable" \
        --env OAUTH_AUTO_LINK_LDAP_USER="$ldapEnable" \
        --env LDAP_HOST="localhost" \
        --env LDAP_PASS="$ldapAdminSecretKey" \
        --volume /srv/docker/gitlab/gitlab:/home/git/data \
        sameersbn/gitlab:15.3.1
      docker logs -f gitlab
      echo "Info: Exposes Port -> "
      echo "GitLab SSH Port  : 8022"
      echo "Gitlab Port      : 8040"
      echo "Done"
    else
      sudo docker run --name gitlab -d --restart always \
        --link gitlab-postgresql:postgresql --link gitlab-redis:redisio --link openldap-haytech:ldapio \
        --publish 8022:22 --publish 8040:80 \
        --env DB_USER="gitlab" \
        --env DB_PASS="$postgresPass" \
        --env DB_NAME="gitlabhq_production" \
        --env GITLAB_PORT="8040" \
        --env GITLAB_SSH_PORT="8022" \
        --env GITLAB_HOST="localhost" \
        --env GITLAB_SECRETS_DB_KEY_BASE="$dbKey" \
        --env GITLAB_SECRETS_SECRET_KEY_BASE="$secretKey" \
        --env GITLAB_SECRETS_OTP_KEY_BASE="$otpKey" \
        --env NGINX_HSTS_MAXAGE="2592000" \
        --env TZ="$timeZoneVar" \
        --env GITLAB_TIMEZONE="$city" \
        --env GITLAB_BACKUP_SCHEDULE="$autoBackup" \
        --env GITLAB_BACKUP_TIME="02:00" \
        --env LDAP_ENABLED="$ldapEnable" \
        --env OAUTH_AUTO_LINK_LDAP_USER="$ldapEnable" \
        --env LDAP_HOST="localhost" \
        --env LDAP_PASS="$ldapAdminSecretKey" \
        --volume /srv/docker/gitlab/gitlab:/home/git/data \
        sameersbn/gitlab:15.3.1
      sudo docker logs -f gitlab
      echo "Info: Exposes Port -> "
      echo "GitLab SSH Port  : 8022"
      echo "Gitlab Port      : 8040"
      echo "Done"
    fi
    ;;

  8)
    echo "nameserver 178.22.122.100
nameserver 185.51.200.2" | sudo tee -a /etc/resolv.conf
    echo "Done"
    ;;

  9)
    break
    ;;

  *) echo "Invalid option $REPLY" ;;

  esac
  REPLY=

done
