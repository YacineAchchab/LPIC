# !/bin/bash
# shebang interpreteur de commande
# nom         : Baudillon Rémy
# description : scrypt bash qui met une vm en marche avec cheat / Bookstack / wireguard / guacamole
# param 1     :
# param 2     :
# Auteur      : Baudillon Rémy
# email       : remy.baudillon@gmail.com / davy.nguyen@gmail.com
# version     : final


#******************************************************************
#                        CHEAT
#******************************************************************

clear


#déclaration des variables user

user="davy"
user2="esgi"


#installation et mise a jour des packages

function install_all_packages(){
	apt update && apt upgrade -y
	apt install -y sudo git tree vim unzip curl mlocate htop net-tools \
                   lynx zip figlet screenfetch sshfs 
	
}

#appel fonction pour installation de packages
install_all_packages


#installation de cheat avec github

function install_cheat(){
wget https://github.com/cheat/cheat/releases/download/4.2.2/cheat-linux-amd64.gz
gunzip cheat-linux-amd64.gz
chmod a+x cheat-linux-amd64
mv -v cheat-linux-amd64 /usr/local/bin/cheat
}


#creation groupe commun
sudo groupadd commun



#création des users + attribution des droits



if getent passwd $user > /dev/null 2>&1; then
    echo "ce user existe" $user
else
    echo "ce user n'existe pas et nous allons le créer"
    sudo useradd -m -s /bin/bash $user
fi

sudo usermod -aG sudo $user
sudo usermod -aG commun $user
echo "umask 007" >> /home/$user/.bashrc


if getent passwd $user2 > /dev/null 2>&1; then
    echo "ce user existe" $user2
else
    echo "ce user n'existe pas et nous allons le créer"
    sudo useradd -m -s /bin/bash $user2
    echo -e 'Pa55w.rd\nPa55w.rd' | sudo passwd $user2
fi

sudo usermod -aG sudo $user2
sudo usermod -aG commun $user2
echo "umask 007" >> /home/$user2/.bashrc


sleep 30


#installation de cheat
install_cheat

#Création de la banniere
function banner()
{
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo "banner /etc/issue.net" >> /etc/ssh/sshd_config

cat > /etc/issue.net << OEF

***********************************************************************************
FAIT ATTENTION A CE QUE VOUS FAITES
***********************************************************************************

OEF


figlet TOOLBOX > /etc/motd

}

#création des dossiers

mkdir -vp /opt/COMMUN/cheat/cheatsheets/community
mkdir -vp /opt/COMMUN/cheat/cheatsheets/personal

cheat --init > /opt/COMMUN/cheat/conf.yml

sed -i 's;/root/.config/; /opt/COMMUN/;' /opt/COMMUN/cheat/conf.yml

git clone https://github.com/cheat/cheatsheets.git

mv -v cheatsheets/[a-z]* /opt/COMMUN/cheat/cheatsheets/community

mkdir -v /root/.config/
mkdir -v /etc/skel/.config/


#Attribution des droits

chgrp -Rv commun /opt/COMMUN
chmod 2770 /opt/COMMUN
chmod -R 2770 /opt/COMMUN/cheat/cheatsheets/community
chmod -R 2770 /opt/COMMUN/cheat/cheatsheets/personal



#création des liens symboliques

ln -s /opt/COMMUN/cheat /root/.config/cheat
ln -s /opt/COMMUN/cheat /etc/skel/.config/cheat


mkdir /home/$user/.config
ln -s /opt/COMMUN/cheat /home/$user/.config/cheat


mkdir /home/$user2/.config
ln -s /opt/COMMUN/cheat /home/$user2/.config/cheat


#création des alias

alias min5="find . -type f -mmin –5 -ls"
alias chmod="chmod -v  --preserve-root"
alias ll="ls -rtl --color"


echo 'alias min5="find . -type f -mmin –5 -ls"' >> /root/.bashrc 
echo 'alias chmod="chmod -v  --preserve-root"' >> /root/.bashrc
echo 'alias ll="ls -rtl --color"' >> /root/.bashrc



#******************************************************************
#                        BOOKSTACK
#******************************************************************



#---Mise à jours et installation des packages---#

DOMAIN='bookstack.s4nj1.local'
DB_password='passBookstack'


function update
{
    apt-get update && apt-get upgrade -y
}

function package_install
{
    apt-get install php7.4-fpm php7.4-common php7.4-mysql php7.4-gmp php7.4-curl php7.4-intl php7.4-mbstring php7.4-xmlrpc php7.4-gd php7.4-xml php7.4-cli php7.4-zip php7.4-soap php7.4-imap nginx mariadb-server mariadb-client -y 
}


#Création de la base de données
function mariadb_secure_install
{   
    mysql_secure_installation 
    mariadb -u root --execute="CREATE DATABASE bookstack"
    mariadb -u root --execute="CREATE USER 'bookstack'@'localhost' IDENTIFIED BY '$DB_password';"
    mariadb -u root --execute="GRANT ALL ON bookstack.* TO 'bookstack'@'localhost'; FLUSH PRIVILEGES;"
}

#installation de bookstack
function bookstack_download
{
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
    cd /var/www/
    mkdir -p $DOMAIN/html
    cd $DOMAIN/html
    git clone https://github.com/BookStackApp/BookStack.git --branch release --single-branch bookstack
    cd bookstack
    composer install --no-interaction  
}

function bookstack_env
{
    cp .env.example .env
    sed -i.bak "s@APP_URL=.*\$@APP_URL=http://$DOMAIN@" .env
    sed -i.bak 's/DB_DATABASE=.*$/DB_DATABASE=bookstack/' .env
    sed -i.bak 's/DB_USERNAME=.*$/DB_USERNAME=bookstack/' .env
    sed -i.bak "s/DB_PASSWORD=.*\$/DB_PASSWORD=$DB_password/" .env

}

#migration de la base de données
function migrate_data_base
{
    php artisan key:generate --no-interaction --force
    php artisan migrate --no-interaction --force 
}

#attribution permission
function change_permission
{
    chown -R www-data:www-data /var/www/$DOMAIN/ && chmod -R 755 /var/www/$DOMAIN
}

function removing_default_nginx
{
    rm /etc/nginx/sites-*/default
}

#configuration de nginx
function nginx_configuration
{
    uri='$uri'
    query_string='$query_string'

    cat > /etc/nginx/sites-available/$DOMAIN << EOL
server {
  listen 80;
  listen [::]:80;
  server_name bookstack.s4nj1.local ; 
  root /var/www/bookstack.s4nj1.local/html/bookstack/public;
  index index.php index.html;
  location / {
    try_files $uri $uri/ /index.php?$query_string;
  } 
  
  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php7.4-fpm.sock;
  }
}   
    
EOL

    ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
    systemctl restart nginx.service
    systemctl restart phpsessionclean.service
}

echo "###--BookStack installation--###"
sleep 2
echo "###--Package update--###"
update
sleep 5
echo "###--Package installation--###"
package_install
sleep 5
mariadb_secure_install
sleep 5
bookstack_download
sleep 5
bookstack_env
sleep 5
migrate_data_base
sleep 5
change_permission
sleep 5
nginx_configuration


#******************************************************************
#                        GUACAMOLE
#******************************************************************

# installation des différentes libs utilisées
function packagePreInstall() 
{
    apt-get update 
    sudo apt-get install -y gcc g++ libcairo2-dev libpng-dev libtool-bin libossp-uuid-dev libavcodec-dev libwebsockets-dev libavformat-dev libavutil-dev libswscale-dev build-essential libpango1.0-dev libssh2-1-dev libvncserver-dev libtelnet-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev
    apt-get install freerdp2-dev freerdp2-x11 -y
}

# installation de tomcat
function apacheInstall()
{
    sudo apt-get install openjdk-11-jdk -y
    java --version
    sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat
    wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.62/bin/apache-tomcat-9.0.62.tar.gz -P ~
    tar -xzf apache-tomcat-9.0.62.tar.gz -C /opt/tomcat/
    mv /opt/tomcat/apache-tomcat-9.0.62 /opt/tomcat/tomcatapp
    sudo find /opt/tomcat/tomcatapp/bin/ -type f -iname "*.sh" -exec chmod +x {} \;
    sudo chown -R tomcat: /opt/tomcat

    cat > /etc/systemd/system/tomcat.service << EOF

[Unit]
Description=Tomcat 9 servlet container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true"

Environment="CATALINA_BASE=/opt/tomcat/tomcatapp"
Environment="CATALINA_HOME=/opt/tomcat/tomcatapp"
Environment="CATALINA_PID=/opt/tomcat/tomcatapp/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/tomcatapp/bin/startup.sh
ExecStop=/opt/tomcat/tomcatapp/bin/shutdown.sh

[Install]
WantedBy=multi-user.target

EOF
    sudo systemctl daemon-reload
    sudo systemctl enable --now tomcat
    sudo ufw allow 8080/tcp
}

# installation de guacamole serveur
function guacamoleServer()
{
    wget https://downloads.apache.org/guacamole/1.4.0/source/guacamole-server-1.4.0.tar.gz -P ~
    tar xzf ~/guacamole-server-1.4.0.tar.gz
    cd ~/guacamole-server-1.4.0
    ./configure --with-systemd-dir=/etc/systemd/system/
    make 
    make install
    ldconfig
    systemctl daemon-reload
    systemctl start guacd
    systemctl enable guacd

}

# installation de guacamole client
function guacamoleClient()
{
    mkdir /etc/guacamole
    wget https://downloads.apache.org/guacamole/1.4.0/binary/guacamole-1.4.0.war -P ~
    mv ~/guacamole-1.4.0.war /etc/guacamole/guacamole.war
    ln -s /etc/guacamole/guacamole.war /opt/tomcat/tomcatapp/webapps

}

#configuration serveur de guacamole
function ConfigureServer()
{

    echo "GUACAMOLE_HOME=/etc/guacamole" | tee -a /etc/default/tomcat
    echo "export GUACAMOLE_HOME=/etc/guacamole" | tee -a /etc/profile

    cat > /etc/guacamole/guacamole.properties << OEF
guacd-hostname: 127.0.0.1
guacd-port:    4822
user-mapping:    /etc/guacamole/user-mapping.xml
auth-provider:    net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider

OEF

cat > /etc/guacamole/guacd.conf << OEF
[server]
bind_host = 127.0.0.1

OEF
    
    sudo ln -s /etc/guacamole /opt/tomcat/tomcatapp/.guacamole
    sudo chown -R tomcat: /opt/tomcat

}

# configuration de la methode d'authentification sur les machines clientes
function authenticationMethod()
{
    #echo -n password1234 | openssl md5
    cat > /etc/guacamole/user-mapping.xml << EOF
<user-mapping>

    <!-- Per-user authentication and config information -->

    <!-- A user using md5 to hash the password
         guacadmin user and its md5 hashed password below is used to 
             login to Guacamole Web UI-->
    <!-- FIRST USER -->
    <authorize 
            username="Guagadmin"
            password="bdc87b9c894da5168059e00ebffb9077"
            encoding="md5">

        <!-- First authorized Remote connection -->
        <connection name="Test">
            <protocol>ssh</protocol>
            <param name="hostname">192.168.1.11</param>
            <param name="port">22</param>
            <param name="username">devuser</param>
            <param name="password">devuser</param>
        </connection>

        <!-- Second authorized remote connection -->
        <connection name="Windows Server 2019">
            <protocol>rdp</protocol>
            <param name="hostname">10.10.10.5</param>
            <param name="port">3389</param>
            <param name="username">tech</param>
            <param name="ignore-cert">true</param>
        </connection>
    </authorize>
</user-mapping>
EOF
    sudo systemctl restart guacd
    sudo systemctl restart tomcat.service
}


packagePreInstall
sleep 5
apacheInstall
sleep 5
guacamoleServer
sleep 5
guacamoleClient
sleep 5
ConfigureServer
sleep 5
authenticationMethod



#******************************************************************
#                        WIREGUARD
#******************************************************************

#Mise a jour et installetion des packets
function install()
{
    apt-get update -y
    apt-get install wireguard iptables -y
}

#Création des cles privé et public
function ServerKey()
{
    echo 'Never communicate Private key ! '
    wg genkey | tee /etc/wireguard/wg-private.key
    wg genkey | tee /etc/wireguard/wg-public.key 
}

#Configuration du serveur Wireguard
function ServerConf()
{
    ServerPrivateKey=`cat /etc/wireguard/wg-private.key`
    Interface=`ip route list default | awk '{print $5}'`
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    cat > /etc/wireguard/wg0.conf << EOF

[Interface]
Address = 192.168.110.34/24
SaveConfig = True 
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $Interface -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $Interface  -j MASQUERADE
ListenPort = 51820
PrivateKey = $ServerPrivateKey 

EOF
}

#Création des dossiers wireguard
function addClientConf()
{
    mkdir /etc/wireguard/Client/$1/Client1/
    wg genkey | tee /etc/wireguard/Client/$1/Client1/wg-private.key
    wg genkey | tee /etc/wireguard/Client/$1/Client1/wg-public.key

    ClientPrivateKey=`cat /etc/wireguard/Client/$1/Client1/wg-private.key`
    ServerPublicKey=`cat /etc/wireguard/wg-public.key`

    cat > /etc/wireguard/Client/$1/Client1/client1.conf << EOF

[Interface]
PrivateKey = $ClientPrivateKey
address = 192.168.110.45/24

[Peer]
PublicKey = $ServerPublicKey
AllowedIPs = $wireguardNetwork, $lanNetwork
Endpoint = $PrivateIp:16384

EOF

}

# Ajoute le client au serveur wireguard
function addClientToServeur()
{
    ClientPublicKey=`cat /etc/wireguard/Client/$1/Client1/wg-public.key`
    echo "[Peer]" >> /etc/wireguard/Client/$1/Client1/client1.conf
    echo "PublicKey = $ClientPublicKey" >> /etc/wireguard/Client/$1/Client1/client1.conf
    echo "AllowedIPs = 192.168.110.45/32" >>  /etc/wireguard/Client/$1/Client1/client1.conf
}

#Creation des dossiers de configurations
function ClientConf()
{
    mkdir /etc/wireguard/Client

    OSconf="Linux Android Mac Windows" 
    for os in $OSconf;
    do 
        if [[ -d "$os" ]];
        then 
            echo "$os exists."
        else 
            echo "$os folder creation."
            mkdir /etc/wireguard/Client/$os
        fi
    done

    #Creation d'un configuration pour un Client windows

    addClientConf Windows 
    cp /etc/wireguard/Client/Windows/Client1/client1.conf /root
    addClientToServeur Windows

}

function enableWireguard()
{
    wg-quick up wg0
    systemctl enable wg-quick@wgvpn

}


echo '###-Update and install-###'
install

lanNetwork="192.168.1.0/24"
wireguardNetwork="192.168.110.0/24"
PrivateIp=`curl ifconfig.me`

sleep 3
echo '###-Server Key generation-###'
ServerKey
sleep 2 
echo '###-Serveur configuration-###'
ServerConf
sleep 5 
echo "###-Client Configuration-###"
ClientConf
sleep 5 
enableWireguard

