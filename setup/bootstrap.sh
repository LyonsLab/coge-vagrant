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

#: Add node dependencies
npm install -g bower

#: Setup CPAN
curl -L http://cpanmin.us | perl - App::cpanminus

#: Setup mysql database
if ! [ -f /var/log/setup-database ]; then
    echo "create user 'coge'@'localhost' IDENTIFIED BY '$PASS'" | mysql -uroot -pdev
    echo "create database coge" | mysql -uroot -pdev
    echo "grant all privileges on coge.* to coge" | mysql -uroot -pdev
    echo "create user 'coge_web'@'localhost' IDENTIFIED BY '$PASS'" | mysql -uroot -pdev
    echo "grant select on coge.* to coge_web" | mysql -uroot -pdev
    echo "flush privileges" | mysql -uroot -pdev

    mysql -u root -p $PASS coge < /vagrant/setup/coge-schema.sql &> /dev/null
    mysql -u root -p $PASS coge < /vagrant/setup/feature_type.sql &> /dev/null

    touch /var/log/setup-database
fi

#: Setup coge repository
if ! [ -f  /var/log/setup-coge ]; then
    cd /vagrant
    git clone https://github.com/LyonsLab/coge.git

    cd /vagrant/coge
    #: Install Perl modules
    cat modules.txt | xargs cpanm

    #: Install javascript modules
    sudo -u www-data bower install -f

    # Setup directories
    cd /vagrant/coge/web
    setup.sh

    #: Install local perl modules
    cd /vagrant/coge/modules
    perl Makefile.PL lib=/usr/local/lib/perl/5.18.2/
    make install

    #: Link config
    ln -fs /vagrant/setup/coge.conf /var/www/coge.conf

    touch /var/log/setup-coge
fi
