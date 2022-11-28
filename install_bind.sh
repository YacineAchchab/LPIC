#!/bin/bash
# nom         : 
# description : scrypt bash bind DNS
# param 1     :
# param 2     :
# Auteur      : Baudillon Rémy / Letang Nicolas / Eliott Lavier / Yassine Achchab / Nohann AMAND-REGHAI
# email       : 
# version     : VF

set -euo pipefail

install_pkgs() 

{
echo "###########################################################"
echo "installation des packages"
echo "###########################################################"

    yum update -y
    yum install -y bind-utils bind-chroot
}

function init_svc() 

{
echo "###########################################################"
echo "Initialising service"
echo "###########################################################"

    systemctl disable --now named
    /usr/libexec/setup-named-chroot.sh /var/named/chroot on
    systemctl enable named-chroot
}

function configure_named() 

{

echo "###########################################################"
echo "configure named"
echo "###########################################################"

    cat > /var/named/chroot/etc/named.conf << EOF
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//
// See the BIND Administrator's Reference Manual (ARM) for details about the
// configuration located in /usr/share/doc/bind-{version}/Bv9ARM.html

options {
        listen-on port 53 { any; };
        listen-on-v6 port 53 { any; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        recursing-file  "/var/named/data/named.recursing";
        secroots-file   "/var/named/data/named.secroots";
        allow-query     { any; };
        recursion no;

        dnssec-enable yes;
        dnssec-validation yes;

        /* Path to ISC DLV key */
        bindkeys-file "/etc/named.root.key";

        managed-keys-directory "/var/named/dynamic";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};

zone "groupe3.local" {
    type master;
    file "groupe3.zone.forward";
};


zone "103.168.192.in-addr.arpa" IN {
        type master;
        file "groupe3.zone.reverse";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF
}

function add_forward_zone() 

{
echo "###########################################################"
echo "Adding forward DNS zone"
echo "###########################################################"

    cat > /var/named/chroot/var/named/groupe3.zone.forward << "EOF"
; Host informations
$TTL 86400          ; Default TTL

@ IN SOA groupe3.local. hostmaster.groupe3.local. (
    2022111100      ; Serial
    28800           ; Refresh
    7200            ; Retry
    864000          ; Expire
    86400           ; Min TTL
)

; Nameservers records
            IN  NS      ns.groupe3.local.
ns          IN  A       192.168.103.1

; Other records
mail        IN  A       192.168.103.2
www         IN  A       192.168.103.3
ad          IN  A       192.168.103.4
proxy       IN  A       192.168.103.5
firewall    IN  A       192.168.103.6
parc        IN  A       192.168.103.7
supervision IN  A       192.168.103.8
EOF
}

function add_reverse_zone() 

{
echo "###########################################################"
echo "Adding reverse DNS zone"
echo "###########################################################"

    cat > /var/named/chroot/var/named/groupe3.zone.reverse << "EOF"
; Reverse host informations
$TTL 86400          ; Default TTL

@ IN SOA groupe3.local. hostmaster.groupe3.local. (
    2022111100      ; Serial
    28800           ; Refresh
    7200            ; Retry
    864000          ; Expire
    86400           ; Min TTL
)

; Nameservers records
103.168.192.in-addr.arpa.       IN  NS      ns.groupe3.local.

; Other records
1.103.168.192.in-addr.arpa.     IN  PTR     ns.groupe3.local.
2.103.168.192.in-addr.arpa.     IN  PTR     mail.groupe3.local.
3.103.168.192.in-addr.arpa.     IN  PTR     www.groupe3.local.
4.103.168.192.in-addr.arpa.     IN  PTR     ad.groupe3.local.
5.103.168.192.in-addr.arpa.     IN  PTR     proxy.groupe3.local.
6.103.168.192.in-addr.arpa.     IN  PTR     firewall.groupe3.local.
7.103.168.192.in-addr.arpa.     IN  PTR     parc.groupe3.local.
8.103.168.192.in-addr.arpa.     IN  PTR     supervision.groupe3.local.
EOF
}

function restart_svc() 

{
echo "###########################################################"
echo "Restartind DNS server"
echo "###########################################################"

    systemctl restart named-chroot
}

function configure_firewall() 

{
echo "#########################################################"
echo "addition des regles iptables"
echo "#########################################################"

    cat > /tmp/iptables << EOF
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:logdrop - [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp -m multiport --dports 80,22 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -p udp -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p udp -m udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
-A INPUT -j logdrop
-A logdrop -m limit --limit 5/min --limit-burst 10 -j LOG --log-prefix "IPTables dropped: "
-A logdrop -j DROP
COMMIT
EOF

    install -g root -o root -m 0400 -T /tmp/iptables /etc/sysconfig/iptables
    install -g root -o root -m 0400 -T /tmp/iptables /etc/sysconfig/ip6tables
    rm /tmp/iptables

    systemctl enable --now iptables
    systemctl enable --now ip6tables
}




function main() {
    echo "[+]--> START"

    install_pkgs
    sleep 10
    init_svc
    sleep 10
    configure_named
    sleep 10
    add_forward_zone
    sleep 10
    add_reverse_zone
    sleep 10
    restart_svc
    sleep 10
    configure_firewall

    echo "[+]--> END"
}

main
