FROM php:7-apache
RUN apt-get update && apt-get install -y vim libfreetype6-dev libjpeg62-turbo-dev libmcrypt-dev libpng12-dev libicu-dev mlocate libxslt-dev
RUN chown -R www-data:www-data /var/www/html
RUN docker-php-ext-configure gd --with-jpeg-dir=/usr/lib/x86_64-linux-gnu
RUN docker-php-ext-install bcmath


ENV PHP_AMQP_BUILD_DEPS libtool automake git pkg-config librabbitmq-dev libzmq-dev

RUN docker-php-ext-install gd mysqli pdo pdo_mysql mcrypt intl mbstring xsl zip
RUN cp /usr/src/php/php.ini-development /usr/local/etc/php/php.ini && sed -i.bak 's/\;error_log = php_errors.log/error_log = \/var\/log\/php_errors.log/' /usr/local/etc/php/php.ini && touch /var/log/php_errors.log
RUN a2enmod rewrite && apachectl restart

RUN touch /usr/local/etc/php/conf.d/xdebug.ini; \
	echo xdebug.remote_enable=1 >> /usr/local/etc/php/conf.d/xdebug.ini; \
  	echo xdebug.remote_autostart=0 >> /usr/local/etc/php/conf.d/xdebug.ini; \
  	echo xdebug.remote_connect_back=1 >> /usr/local/etc/php/conf.d/xdebug.ini; \
  	echo xdebug.remote_port=9000 >> /usr/local/etc/php/conf.d/xdebug.ini; \
  	echo xdebug.remote_log=/tmp/php5-xdebug.log >> /usr/local/etc/php/conf.d/xdebug.ini;
  	### xdebug install
    RUN cd /usr/local/src && apt-get install -y wget && wget http://xdebug.org/files/xdebug-2.4.0.tgz
    RUN cd /usr/local/src && tar zxvf xdebug-2.4.0.tgz
    RUN cd /usr/local/src/xdebug-2.4.0 && phpize
    RUN cd /usr/local/src/xdebug-2.4.0 && ./configure && make
    RUN mkdir /usr/local/lib/php/20151012
    RUN cp /usr/local/src/xdebug-2.4.0/modules/xdebug.so /usr/local/lib/php/20151012  && \
    echo "zend_extension = /usr/local/lib/php/20151012/xdebug.so" >>  /usr/local/etc/php/php.ini

#RUN	mkdir ~/software && \
#	cd  ~/software/ && \
#	apt-get install -y wget && \
#	wget http://xdebug.org/files/xdebug-2.4.0.tgz && \
#	tar -xvzf xdebug-2.4.0.tgz && \
#	cd xdebug-2.4.0 && \
#	phpize && \
#	./configure && \
#	make && \
#	cp modules/xdebug.so /usr/local/lib/php/extensions/no-debug-non-zts-20151012 && \
#	apachectl graceful
RUN apt-get update && apt-get install -y $PHP_AMQP_BUILD_DEPS --no-install-recommends
RUN cd /usr/lib && \
    git clone --depth=1 -b v0.7.1 git://github.com/alanxz/rabbitmq-c.git && \
    cd rabbitmq-c && \
    git submodule update --init && \
    autoreconf -i && \
    ./configure && \
    make && \
    make install

COPY docker-php-ext-install-pecl /usr/local/bin/

RUN docker-php-ext-install-pecl amqp-1.7.0alpha2
RUN php -m | grep amqp
# # If you need the plain old 'mysql' extension in php7 for legacy reasons, uncomment below
# RUN mkdir -p ~/software  && \
#     cd ~/software && \
#     apt-get install git -y && \
#     git clone https://github.com/php/pecl-database-mysql mysql --recursive && \
#     cd mysql && \
#     phpize && \
#     ./configure && \
#     make && \
#     make install && \
#     echo "extension = /usr/local/lib/php/extensions/no-debug-non-zts-20141001/mysql.so" >> /usr/local/etc/php/php.ini && \
#     apachectl graceful