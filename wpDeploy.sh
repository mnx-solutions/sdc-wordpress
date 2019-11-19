#!/bin/bash
# Type of instance Base 19.2

# wpDeploy
# Nick Leffler
# 20190930 v1

##### EDIT HERE ####
#siteName="_"
#siteTitle="TEST"
#adminEmail="test@test.com"
#siteURL="test.url.com"
#siteProto="http://"
#### DON"T TOUCH BELOW HERE ####

mdata_get () {
siteName=$(mdata-get MsiteName)
siteTitle=$(mdata-get MsiteTitle)
#adminEmail=$(mdata-get MadminEmail)
#siteProto=$(mdata-get MsiteProto)
siteURL=$(mdata-get MsiteURL)

if [[ $(mdata-get MsiteProto) == "ssl" ]]; then
	siteProto="https://"
	ssl=1
fi

fullURL="${siteProto}${siteURL}"
}

mdata_put () {
# mput to triton
mdata-put wpadmin_email ${adminEmail}
mdata-put wpadmin_password ${wpapasswd}
mdata-put root_SQL_password ${sqlpswd}
mdata-put wp_SQL_password ${wpasswd}
mdata-put full_URL ${fullURL}
mdata-put done_time $(date +'%Y%m%d_%H%M%S')
}

genSSL () {
mkdir -p "/opt/local/etc/nginx/ssl/${siteURL}/" || exit
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /opt/local/etc/nginx/ssl/${siteURL}/key -out /opt/local/etc/nginx/ssl/${siteURL}/crt \
    -subj "/C=TT/ST=TT/L=TT/O=TEMP/OU=TEMP/CN=$siteURL/emailAddress=TEMP"
}

addCron () {
cd /root/sdc-wordpress || exit
curl -s -o 'wpCertbot.sh' 'https://raw.githubusercontent.com/mnx-solutions/sdc-wordpress/master/wpCertbot.sh'
#wget 'https://raw.githubusercontent.com/mnx-solutions/sdc-wordpress/master/wpCertbot.sh' -O /root/sdc-wordpress/wpCertbot.sh
echo '30,60 * * * * root /root/sdc-wordpress/wpCertbot.sh' > /etc/cron.d/crontabs/wpCertbot
}

vHostHTTP () {
# create nginx config for site
cat <<EOF > "/opt/local/etc/nginx/vhosts/${siteURL}.conf"
server {
        ## Your website name goes here.
        server_name "${siteURL}";
        ## Your only path reference.
        root "${siteFP}";
        ## This should be in your http block and if it is, it's not needed here.
        index index.php;

     location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location ~ /\. {
        access_log off;
        log_not_found off;
        deny all;
    }

    location ~* \\.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires max;
        log_not_found off;
    }


    location / {
        # This is cool because no php is touched for static content.
        # include the "?\$args" part so non-default permalinks doesn't break when using query string
        try_files \$uri \$uri/ /index.php?\$args;
    }

    # Pass PHP scripts to PHP-FPM
    location ~* \\.php\$ {
        fastcgi_index   index.php;
        fastcgi_intercept_errors on;
        fastcgi_pass    php;
        #fastcgi_pass   unix:/var/run/php-fpm/php-fpm.sock;
        include         fastcgi_params;
        fastcgi_param   SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;
        fastcgi_param   SCRIPT_NAME        \$fastcgi_script_name;
    }
}
EOF
}

vHostHTTPS () {
# create nginx config for site
cat <<EOF > "/opt/local/etc/nginx/vhosts/${siteURL}.conf"
server {
    listen 80;
    server_name "${siteURL}";
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl;
        ## Your website name goes here.
        server_name "${siteURL}";
        ## Your only path reference.
        root "${siteFP}";
        ## This should be in your http block and if it is, it's not needed here.
        index index.php;

     location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location ~ /\. {
        access_log off;
        log_not_found off;
        deny all;
    }

    location ~* \\.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires max;
        log_not_found off;
    }


    location / {
        # This is cool because no php is touched for static content.
        # include the "?\$args" part so non-default permalinks doesn't break when using query string
        try_files \$uri \$uri/ /index.php?\$args;
    }

    # Pass PHP scripts to PHP-FPM
    location ~* \\.php\$ {
        fastcgi_index   index.php;
        fastcgi_intercept_errors on;
        fastcgi_pass    php;
        #fastcgi_pass   unix:/var/run/php-fpm/php-fpm.sock;
        include         fastcgi_params;
        fastcgi_param   SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;
        fastcgi_param   SCRIPT_NAME        \$fastcgi_script_name;
    }
	ssl on;
    ssl_certificate /opt/local/etc/nginx/ssl/${siteURL}/crt;
    ssl_certificate_key /opt/local/etc/nginx/ssl/${siteURL}/key;

    ssl_ciphers "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK";
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
    add_header X-Content-Type-Options nosniff;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 4.2.2.1 valid=300s;
    resolver_timeout 5s;
}
EOF
genSSL
}

#### NGINX CONFIG FILE TEMPLATE ####
nginx-conf () {
# Make conf.d directory
mkdir -p /opt/local/etc/nginx/conf.d
mkdir -p /opt/local/etc/nginx/vhosts

# Create upstream file for PHP
cat <<EOF > /opt/local/etc/nginx/conf.d/upstream.conf
upstream php {
        server unix:/var/run/php-fpm.sock;
        #server 127.0.0.1:9000;
}
EOF

# Create barebone nginx config
cat <<EOF > /opt/local/etc/nginx/nginx.conf
user   wpuser wpgroup;
worker_processes  1;

events {
    # After increasing this value You probably should increase limit
    # of file descriptors (for example in start_precmd in startup script)
    worker_connections  1024;
}


http {
    include       /opt/local/etc/nginx/mime.types;
    default_type  application/octet-stream;

    #log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
    #                  '\$status \$body_bytes_sent "\$http_referer" '
    #                  '"\$http_user_agent" "\$http_x_forwarded_for"';

    #access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    gzip on;
    gzip_disable "msie6";

    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

    client_max_body_size 100M;
	
    include /opt/local/etc/nginx/conf.d/*.conf;
    include /opt/local/etc/nginx/vhosts/*.conf;

}
EOF
}
#### END OF NGINX TEMPLATE

sslConfig () {
if [[ "${ssl}" = 1 ]]; then
        vHostHTTPS
        genSSL
        addCron
else
        vHostHTTP
fi
}

create_wp_db () {
# Create root mysql user passwd
sqlpswd=$(openssl rand 39 -base64 | cut -c3-33)
# create wordpress user with passwd
wpasswd=$(openssl rand 39 -base64 | cut -c10-30)
wpapasswd=$(openssl rand 39 -base64 | cut -c15-37)
mysql -e "create database wordpress"
mysql -e "grant all on wordpress.* to wordpress@localhost identified by '${wpasswd}'"
}

mysql_lock_down () {
# Lock down mysql
# Make sure that NOBODY can access the server without a password
mysql -e "UPDATE mysql.user SET Password = PASSWORD('${sqlpswd}') WHERE User = 'root'@'localhost'"

# Kill the anonymous users
mysql -e "DROP USER ''@'localhost'"
# Because our hostname varies we'll use some Bash magic here.
mysql -e "DROP USER ''@'$(hostname)'"
# Kill off the demo database
mysql -e "DROP DATABASE test"
# Make our changes take effect
mysql -e "FLUSH PRIVILEGES"
}

install_deps () {
# Installed needed items
pkgin -y in top
pkgin -y in htop
pkgin -y in nano
pkgin -y in nginx
#pkgin -y in mariadb-server-10
#pkgin -y in mysql-server-5.7.26nb2 mysql-client-5.7.26nb2
pkgin -y in mysql-server-5 mysql-client-5
/usr/sbin/svcadm enable -r svc:/pkgsrc/mysql:default

# Install PHP stuff
pkgin -y in php73-mysqli
pkgin -y in php73-fpm
pkgin -y in php73-zlib
pkgin -y in php73-yaml
pkgin -y in php73-xsl
pkgin -y in php73-wddx
pkgin -y in php73-xmlrpc
pkgin -y in php73-tidy
pkgin -y in php73-soap
pkgin -y in php73-pspell
pkgin -y in php73-pecl-mcrypt
pkgin -y in php73-opcache
pkgin -y in php73-mbstring
pkgin -y in php73-json
pkgin -y in php73-imagick
pkgin -y in php73-iconv
pkgin -y in php73-gd
pkgin -y in php73-curl
pkgin -y in php73-bcmath
pkgin -y in php73-bz2
pkgin -y in php73-zip
}

########################################################################
#                                                                      #
#                           Starts HERE                                #
#                                                                      #
########################################################################

# set defaults
siteProto="http://"
ssl=0

# get mdata
mdata_get

# Create variable from inputed ones
siteFP="/home/wpuser/httpdocs/${siteURL}/public_html"

# Create users
useradd wpuser
groupadd wpgroup
usermod -G wpgroup wpuser

install_deps

# Enable errythang
/usr/sbin/svcadm enable -r svc:/pkgsrc/nginx:default
/usr/sbin/svcadm enable -r svc:/pkgsrc/php-fpm:default

# do mysql stuff
create_wp_db
#mysql_lock_down

# Install CP CLI
wget "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" -O /opt/local/sbin/wp
chmod +x /opt/local/sbin/wp

# create admin email 
adminEmail="admin@${siteURL}"

# Create site with wp-cli
mkdir -p "${siteFP}" || exit
cd "${siteFP}" || exit
wp core download
wp config create --dbname=wordpress --dbuser=wordpress --dbpass="${wpasswd}" --path="${siteFP}"
wp core install --url="${siteURL}" --title="${siteTitle}" --admin_user="${adminEmail}" --admin_password="${wpapasswd}" --admin_email="${adminEmail}" --path="${siteFP}" --skip-email
chown -R wpuser:wpgroup "/home/wpuser"

# Config php
# php.ini change
sed -i "s#;date.timezone =#date.timezone = America/New_York#g" /opt/local/etc/php.ini
sed -i "s#upload_max_filesize = 2M#upload_max_filesize = 99M#g" /opt/local/etc/php.ini
#sed -i "s#memory_limit = 128M#memory_limit = 256M#g" /opt/local/etc/php.ini
sed -i "s#post_max_size = 8M#post_max_size = 99M#g" /opt/local/etc/php.ini

# www pool config change
sed -i "s#listen = 127.0.0.1:9000#listen = /var/run/php-fpm.sock#" /opt/local/etc/php-fpm.d/www.conf
sed -i "s#user = www#user = wpuser#g" /opt/local/etc/php-fpm.d/www.conf
sed -i "s#group = www#group = wpgroup#g" /opt/local/etc/php-fpm.d/www.conf

/usr/sbin/svcadm restart svc:/pkgsrc/php-fpm

# Confiugre nginx and create config
nginx-conf
sslConfig
/usr/sbin/svcadm restart svc:/pkgsrc/nginx

# Echo errythang that matters
echo "The SQL root password is: ${sqlpswd} and the WP sql password is: ${wpasswd}"
echo "${siteName} is at ${siteProto}${siteURL} with the title ${siteTitle} and the admin email of ${adminEmail}"
echo "The wp-admin email/username is: ${adminEmail} and the password is: ${wpapasswd}"
echo "Thank you and have a great day"

mdata_put
