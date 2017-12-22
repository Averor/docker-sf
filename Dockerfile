FROM php:7.1.10-apache-jessie

MAINTAINER averor.dev@gmail.com

ARG DOCKER_VHOST_NAME

RUN echo "Europe/Warsaw" > /etc/timezone && cp /usr/share/zoneinfo/Europe/Warsaw /etc/localtime

RUN    apt-get update \
    && apt-get install -y --fix-missing

RUN apt-get install -y \
    locales \
    git \
    libicu52 libicu-dev \
    libxml2 libxml2-dev \
    zip unzip \
    zlib1g-dev \
    libcurl4-gnutls-dev \
    libssl-dev \
    mysql-client \
    moreutils

RUN    sed -i -e 's/# pl_PL.UTF-8 UTF-8/pl_PL.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=pl_PL.UTF-8

ENV LANG pl_PL.UTF-8
ENV LANGUAGE pl_PL:en
ENV LC_ALL pl_PL.UTF-8

COPY ./vhost.conf /tmp/
COPY ./xdebug.ini /tmp/

RUN sed "s/_VHOST_NAME_/$DOCKER_VHOST_NAME/g" /tmp/vhost.conf > /etc/apache2/sites-available/$DOCKER_VHOST_NAME.conf

RUN    cd /etc/apache2/sites-available/ \
    && a2dissite * \
    && a2ensite $DOCKER_VHOST_NAME \
    && a2enmod rewrite \
    && mkdir -p /var/www/html/$DOCKER_VHOST_NAME

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

# XDebug
RUN    curl -fsSL "http://xdebug.org/files/xdebug-2.5.5.tgz" -o xdebug.tar.gz \
    && mkdir -p /tmp/xdebug \
    && tar -xf xdebug.tar.gz -C /tmp/xdebug --strip-components=1 \
    && rm xdebug.tar.gz \
    && docker-php-ext-configure /tmp/xdebug --enable-xdebug \
    && docker-php-ext-install /tmp/xdebug \
    && rm -r /tmp/xdebug
RUN cat /tmp/xdebug.ini >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN    docker-php-ext-install bcmath \
    && docker-php-ext-install curl \
    && docker-php-ext-install iconv \
    && docker-php-ext-install intl \
    && docker-php-ext-install json \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install pcntl \
    && docker-php-ext-install pdo \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install session \
    && docker-php-ext-install soap \
    && docker-php-ext-install xml \
    && docker-php-ext-install zip

# MongoDB
RUN pecl install mongodb
RUN echo "extension=mongodb.so" > /usr/local/etc/php/conf.d/ext-mongodb.ini

RUN usermod -u 1000 www-data
RUN usermod -G www-data www-data

RUN echo 'PassEnv APP_ENV' > /etc/apache2/conf-enabled/expose-env.conf
RUN echo 'PassEnv APP_DEBUG' >> /etc/apache2/conf-enabled/expose-env.conf
RUN echo 'PassEnv APP_SECRET' >> /etc/apache2/conf-enabled/expose-env.conf
