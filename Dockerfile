FROM wordpress:fpm-alpine

# Install extra PHP extensions
RUN apk add --no-cache --virtual .build-deps postgresql-dev

RUN docker-php-ext-configure pgsql --with-pgsql=/usr
RUN docker-php-ext-install pgsql

RUN runDeps="$( \
		scanelf --needed --nobanner --recursive \
			/usr/local/lib/php/extensions \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" && apk add --virtual .wordpress-phpexts-rundeps $runDeps;
RUN apk del .build-deps

ADD https://github.com/PostgreSQL-For-Wordpress/postgresql-for-wordpress/archive/refs/tags/v3.4.1.tar.gz /usr/src/wordpress
RUN tar zxvf /usr/src/wordpress/v3.4.1.tar.gz -C /usr/src/wordpress postgresql-for-wordpress-3.4.1/pg4wp
RUN mv /usr/src/wordpress/postgresql-for-wordpress-3.4.1/pg4wp /usr/src/wordpress/pg4wp
RUN rmdir /usr/src/wordpress/postgresql-for-wordpress-3.4.1/
RUN rm /usr/src/wordpress/v3.4.1.tar.gz
ADD ./docker-entrypoint2.sh          /usr/local/bin/docker-entrypoint2.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint2.sh
ENTRYPOINT ["docker-entrypoint2.sh"]
CMD ["php-fpm"]
