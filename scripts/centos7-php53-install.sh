#!/usr/bin/env bash

# Copyright:: Copyright (c) 2016 Been Kyung-yoon (http://www.php79.com/)
# License:: The MIT License (MIT)

STACK_ROOT=$( dirname $( cd "$( dirname "$0" )" && pwd ) )
source "${STACK_ROOT}/includes/function.inc.sh"

title "Compile and install PHP 5.3. (No 5.3 official repository in CentOS 7)"

if [ $OS = "centos6" ]; then
  abort "CentOS 6 does not support PHP 5.3 compilation installation."
fi


yum_install gcc autoconf \
libxml2-devel libmcrypt libmcrypt-devel libstdc++-devel \
ncurses-devel libtool-ltdl libtool-ltdl-devel openssl-devel \
libcurl libcurl-devel \
gd gd-devel \
bzip2 wget
#MariaDB-devel

# PHP - compile
cd /usr/local/src/ \
&& wget http://us1.php.net/distributions/php-5.3.29.tar.bz2 -O php-5.3.29.tar.bz2 \
&& tar jxfp php-5.3.29.tar.bz2 \
&& cd php-5.3.29 \
&& ./configure --prefix=/usr/local/php53 \
--with-config-file-path=/usr/local/php53/etc/php.ini \
--with-config-file-scan-dir=/usr/local/php53/etc/php.d \
--with-libdir=lib64 \
--enable-fpm \
--enable-mbstring --enable-mbregex \
--with-mysql-sock=/var/lib/mysql/mysql.sock \
--with-mysql=mysqlnd \
--with-mysqli=mysqlnd \
--with-pdo-mysql=mysqlnd \
--with-mcrypt \
--with-jpeg-dir --with-gd \
--with-openssl \
--with-curl \
--with-zlib \
&& make \
&& make install

if [ ${?} != "0" ]; then
  abort "PHP compilation failed. CENTOS 6 does not support PHP 5.3 compilation installation."
fi

if [ ! -f /usr/bin/php53 ]; then
  ln -s /usr/local/php53/bin/php /usr/bin/php53
fi

if [ ! -f /usr/local/php53/etc/php.ini ]; then
  cp -av php.ini-production /usr/local/php53/etc/php.ini
fi

if [ ! -d /usr/local/php53/etc/php.d ]; then
  mkdir /usr/local/php53/etc/php.d
fi

/usr/local/php53/bin/pecl install ZendOpcache
if [ ! -f /usr/local/php53/etc/php.d/10-opcache.ini ]; then
  cp -av "${STACK_ROOT}/php/53/compile/10-opcache.ini" /usr/local/php53/etc/php.d/
fi

# pecl/imagick requires PHP (version >= 5.4.0)
#/usr/local/php53/bin/pecl install imagick \
#&& cp -av "${STACK_ROOT}/php/53/compile/40-imagick.ini" /usr/local/php53/etc/php.d/

if [ ! -f /usr/local/php53/etc/php.d/z-php79.ini ]; then
  notice "PHP recommended settings have been added. \ N Configuration file path) /usr/local/php53/etc/php.d/z-php79.ini"
  cp -av "${STACK_ROOT}/php/53/z-php79.ini" /usr/local/php53/etc/php.d/
  string_quote ${TIMEZONE}
  sed -i "s/^date.timezone =.*/date.timezone = ${STRING_QUOTE}/g" /usr/local/php53/etc/php.d/z-php79.ini
fi

if [ ! -f /usr/local/php53/etc/php-fpm.conf ]; then
  cp -av "${STACK_ROOT}/php/53/compile/php-fpm.conf" /usr/local/php53/etc/
fi

if [ ! -d /usr/local/php53/var/session ]; then
    mkdir -p /usr/local/php53/var/session
fi
chown -v nobody.nobody /usr/local/php53/var/session

if [ ! -f /usr/lib/systemd/system/php53-php-fpm.service ]; then
  mkdir /usr/local/php53/sysconfig
  touch /usr/local/php53/sysconfig/php-fpm
  cp -av "${STACK_ROOT}/php/53/compile/php53-php-fpm.service" /usr/lib/systemd/system/
fi

systemctl enable php53-php-fpm
systemctl start php53-php-fpm


# # nginx Copy only if installed
if [ -f /etc/nginx/conf.d/0-php79.conf ]; then
  if [ ! -f "/etc/nginx/conf.d/1-fastcgi-php53.conf" ]; then
    cp -av "${STACK_ROOT}/nginx/1-fastcgi-php53.conf" /etc/nginx/conf.d/
  fi
fi
