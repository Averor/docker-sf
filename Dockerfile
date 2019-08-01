FROM php:7.1-apache-stretch

MAINTAINER averor.dev@gmail.com

RUN echo "Europe/Warsaw" > /etc/timezone && cp /usr/share/zoneinfo/Europe/Warsaw /etc/localtime

ENV APACHE_DOCUMENT_ROOT /var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

RUN a2enmod rewrite

RUN    apt-get update \
    && apt-get install -y --fix-missing

RUN apt-get install -y \
    locales \
    nano \
    git \
    libicu57 libicu-dev \
    librabbitmq-dev \
    libxml2 libxml2-dev \
    sqlite3 \
    zip unzip \
    zlib1g-dev \
    libcurl4-gnutls-dev \
    libssl-dev \
    libpng-dev \
    libxrender1 \
    libfontconfig \
    mysql-client \
    moreutils \
    libpq-dev

RUN    sed -i -e 's/# pl_PL.UTF-8 UTF-8/pl_PL.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG=pl_PL.UTF-8

ENV LANG pl_PL.UTF-8
ENV LANGUAGE pl_PL:en
ENV LC_ALL pl_PL.UTF-8

COPY ./xdebug.ini /tmp/

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
    && docker-php-ext-install gd \
    && docker-php-ext-install iconv \
    && docker-php-ext-install intl \
    && docker-php-ext-install json \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install opcache \
    && docker-php-ext-install pcntl \
    && docker-php-ext-install pdo \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install session \
    && docker-php-ext-install soap \
    && docker-php-ext-install xml \
    && docker-php-ext-install zip \
    && docker-php-ext-install pgsql \
    && docker-php-ext-install pdo_pgsql pgsql

# MongoDB
RUN pecl install mongodb
RUN echo "extension=mongodb.so" > /usr/local/etc/php/conf.d/ext-mongodb.ini

# AMQP
RUN pecl install amqp
RUN docker-php-ext-enable amqp

RUN usermod -u 1000 www-data
RUN usermod -G www-data www-data

RUN echo 'PassEnv APP_ENV' > /etc/apache2/conf-enabled/expose-env.conf
RUN echo 'PassEnv APP_DEBUG' >> /etc/apache2/conf-enabled/expose-env.conf
RUN echo 'PassEnv APP_SECRET' >> /etc/apache2/conf-enabled/expose-env.conf

RUN mkdir /var/www/html/var && chmod -R 770 /var/www/html/var

WORKDIR /var/www/html

EXPOSE 80
EXPOSE 443

CMD ["apache2-foreground"]
