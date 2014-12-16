#!/bin/bash
#
# bootstrap.sh ~ bootstrapping script to setup a coge virtual machine
#
# Author(s): Evan Briones
#

PASS='dev'

#: Install apt-add-repository
apt-get install -y --quiet python-software-properties

#: Enable multiverse packages
sed -i "/^# deb.*multiverse/ s/^# //" /etc/apt/sources.list

# Set package selection defaults
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
echo mysql-server mysql-server/root_password password $PASS | debconf-set-selections
echo mysql-server mysql-server/root_password_again password $PASS | debconf-set-selections

#: Add apt repositories
apt-add-repository ppa:chris-lea/node.js

#: Install software dependencies
echo Installing packages...
apt-get update && apt-get install -y \
    curl \
    git \
    mysql-server \
    samtools \
    ubuntu-dev-tools \
    build-essential \
    checkinstall \
    gcc-multilib \
    expat \
    libexpat1-dev \
    libgd2-xpm-dev \
    libapache2-mod-perl2 \
    libapache2-mod-wsgi \
    libzmq3-dev \
    build-essential \
    njplot \
    imagemagick \
    graphviz \
    apache2 \
    swig \
    ttf-mscorefonts-installer \
    python-setuptools \
    python-numpy \
    python-dev \
    aragorn \
    nodejs &> /dev/null
