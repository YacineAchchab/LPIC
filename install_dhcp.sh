#!/usr/bin/bash

set -euo pipefail

install_pkgs() {
    echo "[+]--> Installing required packages"

    yum update -y
    yum install -y dhcp
}

configure_dhcp() {
    echo "[+]--> Configuring dhcp"

    echo "DHCPDARGS=enp0s8" > /etc/sysconfig/dhcpd

    cat > /etc/dhcp/dhcpd.conf << "EOF"
#
# Configuration file for ISC dhcpd
#

# option definitions common to all supported networks...
default-lease-time 600;
max-lease-time 7200;

# If this DHCP server is the official DHCP server for the local
# network, the authoritative directive should be uncommented.
authoritative;

subnet 192.168.130.0 netmask 255.255.255.0 {
  range 192.168.130.10 192.168.130.254;
  option routers 192.168.130.1;
  option domain-name-servers 192.168.130.1;
  option broadcast-address 192.168.130.255;
  option domain-name "groupe3.local";
  option domain-search "groupe3.local";
  next-server 192.168.130.1;
  filename "pxelinux.0";
}

host self {
	hardware ethernet 08:00:27:60:19:48;
	fixed-address 192.168.130.1;
}
EOF

    cat > /etc/sysconfig/network-scripts/ifcfg-enp0s8 << EOF
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
IPADDR=192.168.130.1
NETMASK=255.255.255.0
GATEWAY=192.168.130.1
DNS1=192.168.130.1
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=no
IPV6_DEFROUTE=no
NAME=enp0s8
DEVICE=enp0s8
ONBOOT=yes
EOF
}

add_firewall_rule() {
    echo "[+]--> Adding firewall rules"

    iptables  -I INPUT 5 -p udp -m udp --dport 67 -m conntrack --ctstate NEW -j ACCEPT
    ip6tables -I INPUT 5 -p udp -m udp --dport 67 -m conntrack --ctstate NEW -j ACCEPT

    iptables-save > /etc/sysconfig/iptables
    ip6tables-save > /etc/sysconfig/ip6tables
}

start_svc() {
    echo "[+]--> Starting DNS server"

    systemctl restart network
    systemctl enable --now dhcpd
}

main() {
    echo "[+]--> START"

    install_pkgs
    configure_dhcp
    add_firewall_rule
    start_svc

    echo "[+]--> END"
}

main
