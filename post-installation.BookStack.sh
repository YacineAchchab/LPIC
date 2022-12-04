#!/bin/bash

# Variables
DOMAIN="wiki.achchab.local"
DB_PASS=$DB_PASS 
user=$(id -un 1000)
BOOKSTACK_DIR="/var/www/bookstack"

# Installation

# set -o xtrace
# set -x

export DEBIAN_FRONTEND=noninteractive
apt update -y
apt upgrade -y

apt install nginx \
	php-fpm \
	php-mbstring \
	php-tokenizer \
	php-gd \
	php-xml \
	php-curl \
	php-mysql \
	composer \
	mariadb-server -y | tee -a /root/install.bookstack.log

# Set up database
mysql -u root --execute="CREATE DATABASE bookstack;"
mysql -u root --execute="CREATE USER 'nimda'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -u root --execute="GRANT ALL ON bookstack.* TO 'nimda'@'localhost';FLUSH PRIVILEGES;"

# Set up Bookstack
### Download BookStack

git clone https://github.com/BookStackApp/BookStack.git --branch release --single-branch /var/www/bookstack
chown -Rv $user:$user $BOOKSTACK_DIR
chown -Rv www-data. $BOOKSTACK_DIR/storage
chown -Rv www-data. $BOOKSTACK_DIR/public/uploads
chown -Rv www-data. $BOOKSTACK_DIR/bootstrap/cache
cd $BOOKSTACK_DIR || exit

# Install BookStack composer dependencies
export COMPOSER_ALLOW_SUPERUSER=1
composer install --no-dev --no-plugins

# Copy and update BookStack environment variables
cp .env.example .env
sed -i.bak "s@APP_URL=.*\$@APP_URL=http://$DOMAIN@" .env
sed -i.bak 's/DB_DATABASE=.*$/DB_DATABASE=bookstack/' .env
sed -i.bak 's/DB_USERNAME=.*$/DB_USERNAME=nimda/' .env
sed -i.bak "s/DB_PASSWORD=.*\$/DB_PASSWORD=$DB_PASS/" .env

# Generate the application key
php artisan key:generate --no-interaction --force
# Migrate the databases
php artisan migrate --no-interaction --force

php artisan bookstack:create-admin --email="barry.booker@example.com" --name="Bazza" --external-auth-id="bbooker"
php artisan bookstack:create-editor --email="bary.boker@example.com" --name="Baza" --external-auth-id="bber"
# Set up nginx
cat > /etc/nginx/sites-available/bookstack.conf << "EOF"
server {
  	listen 80;
    	listen [::]:80;

    	server_name wiki.achchab.local;

    	root /var/www/bookstack/public;
	index index.php index.html;

	location / {
	        try_files $uri $uri/ /index.php?$query_string;
	}
	    
	location ~ \.php$ {
		include snippets/fastcgi-php.conf;
		fastcgi_pass unix:/run/php/php7.4-fpm.sock;
	}
}

EOF

ln -s /etc/nginx/sites-available/bookstack.conf /etc/nginx/sites-enabled

nginx -t 
nginx -s reload
systemctl restart php7.4-fpm 

