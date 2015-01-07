#!/bin/bash
#
# bootstrap.sh ~ bootstrapping script to setup a coge virtual machine
#
# Author(s): Evan Briones
#

PASS='dev'

if ! [ -f /var/log/install-packages ]; then
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
        libperl-dev \
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
        python-pip \
        aragorn \
        nodejs &> /dev/null

    #: Add global node dependencies
    npm install -g bower

    #: Setup CPAN Minus
    curl -L http://cpanmin.us | perl - App::cpanminus

    touch /var/log/install-packages
fi

#: Setup mysql database
if ! [ -f /var/log/setup-database ]; then
    echo "create user 'coge'@'localhost' IDENTIFIED BY '$PASS'" | mysql -uroot -pdev
    echo "create database coge" | mysql -uroot -pdev
    echo "grant all privileges on coge.* to coge" | mysql -uroot -pdev
    echo "create user 'coge_web'@'localhost' IDENTIFIED BY '$PASS'" | mysql -uroot -pdev
    echo "grant select on coge.* to coge_web" | mysql -uroot -pdev
    echo "flush privileges" | mysql -uroot -pdev

    mysql -uroot -p$PASS coge < /vagrant/setup/coge-schema.sql &> /dev/null
    mysql -uroot -p$PASS coge < /vagrant/setup/feature_type.sql &> /dev/null

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

#: Setup apache
if ! [ -f /var/log/setup-apache ]; then
    a2dissite 000-default.conf

    rm -fr /var/www
    ln -fs /vagrant/setup/coge-apache /etc/apache2/sites-enabled/coge.conf
    ln -fs /vagrant/coge/web /var/www

    service apache2 restart
fi

#: Setup JEX / CCTools
if ! [ -f /var/log/setup-jex ]; then
    #: Install CCTools
    rm -rf /vagrant/tmp && mkdir -p /vagrant/tmp && cd /vagrant/tmp
    wget -c "http://ccl.cse.nd.edu/software/files/cctools-4.2.2-source.tar.gz"
    tar xzvf cctools-4.2.2-source.tar.gz
    cd cctools-4.2.2-source
    ./configure --prefix /usr/local
    make install

    #: Install Yerba
    cd /vagrant
    mkdir -p /etc/yerba
    git clone https://github.com/LyonsLab/Yerba.git
    ln -s /vagrant/Yerba /opt/Yerba
    pip install -r  /opt/Yerba/requirements.txt
    cp /opt/Yerba/yerba.cfg.example /etc/yerba/yerba.cfg
    sudo -u www-data /opt/Yerba/bin/yerbad --setup

    #: Copy upstart scripts and pool configuration
    ln -sf /vagrant/setup/work_queue_pool.conf /etc/init/work_queue_pool.conf
    ln -sf /vagrant/setup/catalog_server.conf /etc/init/catalog_server.conf
    ln -sf /vagrant/setup/yerba.conf /etc/init/yerba.conf
    #: This will not be required with cctools 4.3
    ln -sf /vagrant/setup/pool.conf /etc/yerba/yerba.cfg

    # Setup logging directory
    mkdir -p /storage/yerba
    chown -R www-data:www-data /storage/yerba
    ln -sf /storage/yerba /opt/Yerba/log

    #: Start services
    initctl reload-configuration
    start catalog_server
    start work_queue_pool
    start yerba

    touch /var/log/setup-jex
fi

if ! [ -f /var/log/setup-storage ]; then
    mkdir -p /storage/public/data /storage/public/tmp /storage/coge
    chown -R www-data:www-data /storage/public /storage/coge

    touch /var/log/setup-storage
fi
