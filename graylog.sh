# !/bin/bash
# shebang interpreteur de commande
# nom         : Baudillon Rémy
# description : scrypt bash qui install greylog
# param 1     :
# param 2     :
# Auteur      : Baudillon Rémy
# email       : remy.baudillon@gmail.com
# version     : final


function outil
{
apt update && apt upgrade
apt install -y sudo git tree vim unzip curl mlocate htop net-tools \
               lynx zip figlet screenfetch sshfs \
			   apt-transport-https openjdk-11-jre-headless uuid-runtime pwgen dirmngr gnupg wget
}

function mangodb
{
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list
apt-get update
apt-get install -y mongodb-org
}

function reload_mangodb
{
systemctl daemon-reload
systemctl enable mongod.service
systemctl restart mongod.service

systemctl --type=service --state=active | grep mongod
}

function elasticsearch
{
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/oss-7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
apt update && apt install elasticsearch-oss

tee -a /etc/elasticsearch/elasticsearch.yml > /dev/null << EOT
cluster.name: graylog
action.auto_create_index: false
EOT
}

function reload_elast
{
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl restart elasticsearch.service
}

function greylog
{
wget https://packages.graylog2.org/repo/packages/graylog-4.2-repository_latest.deb
dpkg -i graylog-4.2-repository_latest.deb
apt-get update && apt-get install graylog-server graylog-integration-plugins
}

function server
{
#initial root password = admin / nextcloud : a2a1e69c4f8340f60ff88d1484f30c77dc7f46ae32b443db8c0bc373679feba7
password_secret=`pwgen -N 1 -s 96`
sed -i "s/password_secret =/password_secret = $password_secret/g" /etc/graylog/server/server.conf
root_password=`echo a2a1e69c4f8340f60ff88d1484f30c77dc7f46ae32b443db8c0bc373679feba7`
sed -i "s/root_password_sha2 =/root_password_sha2 = $root_password/g" /etc/graylog/server/server.conf
sed -i "s/#http_bind_address = 127.0.0.1:9000/http_bind_address = ADRESSE IP DE VOTRE MACHINE GRAYLOG:9000/g" /etc/graylog/server/server.conf
}

function reload_greylog
{
systemctl daemon-reload
systemctl enable graylog-server.service
systemctl start graylog-server.service
systemctl --type=service --state=active | grep graylog

}

function reboot
{
	systemctl reboot
}

outil
sleep 15
mangodb
sleep 15
reload_mangodb
sleep 15
elasticsearch
sleep 15
reload_elast
sleep 15
greylog
sleep 15
server
sleep 15
reload_greylog
sleep 10
reboot