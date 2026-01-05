## Wordperss-postgersql
### Description
This project creates docker image of wordpress CMS with a PostgreSQL database 
as DB backend. It takes official WordPress [docker image](https://hub.docker.com/_/wordpress)
and adds [PG4WP](https://github.com/kevinoid/postgresql-for-wordpress/) plugin.
The plugin intercepts WordPress calls to the data base and replaces queries in MySql sql
dialect with those compatible  with Postgress.

The project is based on discontinued [ntninja/wordpress-postgresql](https://hub.docker.com/r/ntninja/wordpress-postgresql),
I felt the need for creating image from up-to-date versions of WordPress and PG4WP. Also,the docker image supports a 
minor workaround allowing simple usage of running it behind reversed proxy in subdir scheme, 
see [discussion](#subdir-scheme-workaround) below.

The repository contains an example configuration for docker running behind nginx reverse proxy
in subdirectory mapping schema.

### Use case
- run WordPress with existing Postgress, e.g. case of Postgress instance serving multiple dockers
- run WordPress with Georeplication with a Multi-Active Postgres installation like 
[CockroachDB](https://www.cockroachlabs.com/serverless/) for highly available and resilient Wordpress
infrastructure

### Running the image 
See section "[How to use this image](https://hub.docker.com/_/wordpress#how-to-use-this-image)" of the official
WordPress container (while mentally replacing references to MySql with Postgres). All the docker arguments
defining DB connection are the same, just fill correct values..
This docker image based on FPM  variant of official image. That means one have to run reversed proxy as front end for
WordPress, such as nginx, appache or Traefik.

### Subdir Scheme workaround
As mentioned above, one need reverse proxy to run this image. Two types of mapping schemes exist in such a setup: 
subdomain and subdir. In subdomain sheme the asset beyond a proxy can be accessed by dedicated "virtual host" like
https://sevice1.mydomain.com , https://service2.mydomain.com etc. service1 and service2 here are distinct applicaitons 
independent of one another. In subdir shceme distinction based on subdirectory prefix e.g. https://mydomain.com/service1 and
https://mydomain.com/service2.
When subdir scheme is chosen, the path in the URL must be translated to whatever the service expects, e.g. index.php 
entry point in the service is expected to be in root directory of URI : external address 
https://mydomain.com/service1/index.php  has to be translated http://internal-address/index.php. Similar translation happens
to all URLs including static resources. But sometimes resources are referenced in query string or other parameters. Moreover,
sometimes reverse proxy performs more complicated address translation (e.g. try_files directive in nginx configuration).
In most cases the *rewrite* directive can handle this, but I encountered some strange errors (204 HTTP responces on resources
 that exist) related to this rewriting.
So the workaround ensures that even un-rewriten path in URL points to intended resource by setting correct symbolic links in 
the  WordPress docker container. All you need to do is to define in *docker-compose.yml* environment variable 
*WORDPRESS_WEBROOT*. In case of URL https://mydomain.com/service1 the variable should be 
```
 - WORDPRESS_WEBROOT=/service1
```

Note that you do not HAVE to use this workaround - the workaround is enabled only if the variable is defined. So the docker
image can be safely used with subdomain schema or with subdir schema with other ways of handling the problem. 


### Complete example
The example assumes the docker runs as FPM backend behind nginx as reverse proxy.
- External URL for access to Wordpress CMS is something like https://mydomain.com/blog
- Internal address of the container is *${IP_ADDRESS_OF_WORPRESS_CONTAINER}*. This parameter used in both docker_compose.yml and nginx configuration file
- Parameters for accessing Postgress are *${WORDPRESS_DB_HOST_NAME}*, *${WORDPRESS_DB_USER}*, *${WORDPRESS-DB_NAME}*
- Posgress has dedicated network and static hostname as well as  WordPress container

To run the WordPress
- create docker_compose.yml from docker.compose.yml.example by replacing all the placeholders with actual data. Load file whatever you use for container management
- replace placeholders in wp.conf.examle with actual data ( *${IP_ADDRESS_OF_WORPRESS_CONTAINER}* and perhaps /blog if you want different path for your blog)
- modify default.conf in site-conf subdirectory of nginx configuration dir with include directive to load wp.conf
- ensure that directory mounted in */var/www/html* in the wordpress docker ( the content directory) is available in nginx under appropriate path: e.g. if location block is taken 
from the example, where root defined as */var/www* , and blog webroot ( defined in *WORDPRESS_WEBROOT* environment variable in the compose file) is blog, then the content
directory should be available under */var/www/blog*. In case of nginx running in a docker container, one can mount the directory as read only volume, if nginx runs as OS process,
it is possible to set up symbolic link pointing to content directory. The directory is used for serving static content directly by nginx and for checks of php scripts existance..
- enjoy your blog

The include directive should be placed in the *server* block along with other *location* blocks.
Also it is advisable ( even though not strictly required ) that the following location block exist
```
   # deny access to .htaccess/.htpasswd files
    location ~ /\.ht {
        deny all;
    }

```
This block ensures that htaccess and htpassword files are not accessible from the web and therefore sensitive inforamtion is 
not leaked.
site-confs directory in nginx default.conf include wp.conf


