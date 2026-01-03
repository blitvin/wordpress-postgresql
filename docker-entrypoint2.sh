#!/bin/sh

# Ensure that we have `db.php` in `wp-content`
mkdir -p "wp-content"
if ! [ -e "wp-content/db.php" ];
then
	cp "/usr/src/wordpress/pg4wp/db.php" "wp-content/db.php"
fi

if [ "${WORDPRESS_WEBROOT}" != "" ] ; then
if [ ! -e /var/www${WORDPRESS_WEBROOT} ]; then
ln -s /var/www/html /var/www${WORDPRESS_WEBROOT}
fi
fi

exec docker-entrypoint.sh "$@"
