#!/bin/bash

set -ex

if [ -z "${PACKAGER_REPO}" ]; then
    PACKAGER_REPO="develop"
fi

# set env
export DEBIAN_FRONTEND=noninteractive

# updating package list
apt-get update

# install dependencies
apt-get --no-install-recommends -y install apt-transport-https curl libterm-readline-perl-perl locales mc net-tools openjdk-8-jre telnet wget

## setting locale to en_US.UTF-8 (needed for postgresql)
locale-gen en_US.UTF-8
echo "LANG=en_US.UTF-8" > /etc/default/locale

# install postfix
echo "postfix postfix/main_mailer_type string Internet site" > preseed.txt
debconf-set-selections preseed.txt
apt-get --no-install-recommends install -q -y postfix

# configure zammad & elasticsearch repos & keys
wget -qO - https://deb.packager.io/key | apt-key add -
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-5.x.list
echo "deb https://deb.packager.io/gh/zammad/zammad xenial ${PACKAGER_REPO}" | tee /etc/apt/sources.list.d/zammad.list

# updating package list again
apt-get update

# install elasticsearch & attachment plugin
apt-get --no-install-recommends -y install elasticsearch
cd /usr/share/elasticsearch && bin/elasticsearch-plugin install mapper-attachments

# install zammad
apt-get --no-install-recommends -y install zammad

# postgresql config
echo 'max_connections = 200' >> /etc/postgresql/9.5/main/postgresql.conf
echo 'shared_buffers = 2GB' >> /etc/postgresql/9.5/main/postgresql.conf
echo 'temp_buffers = 1GB' >> /etc/postgresql/9.5/main/postgresql.conf
echo 'work_mem = 6MB' >> /etc/postgresql/9.5/main/postgresql.conf
echo 'max_stack_depth = 2MB' >> /etc/postgresql/9.5/main/postgresql.conf

# start postgres & elasticsearch
service postgresql start
service elasticsearch start
