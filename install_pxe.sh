#!/usr/bin/bash

set -euo pipefail

install_pkgs() {
    echo "[+]--> Installing required packages"

    yum update -y
    yum install -y tftp tftp-server syslinux vsftpd xinetd
}

configure_tftp() {
    echo "[+]--> Configuring TFTP"

    sed -i 's/\tdisable\t*= yes/\tdisable\t\t\t= no/g' /etc/xinetd.d/tftp
    cp -v /usr/share/syslinux/{pxelinux.0,menu.c32,memdisk,mboot.c32,chain.c32} /var/lib/tftpboot
    mkdir -vp /var/lib/tftpboot/{pxelinux.cfg,networkboot}
}

copy_iso_files() {
    echo "[+]--> Copying CentOS ISO files"

    mount /dev/sr0 /mnt/
    cp -av /mnt/* /var/ftp/pub/

    cp /mnt/images/pxeboot/vmlinuz /var/lib/tftpboot/networkboot/
    cp /mnt/images/pxeboot/initrd.img /var/lib/tftpboot/networkboot/

    umount /mnt
}

configure_kickstart() {
    echo "[+]--> Configuring Kickstart"

    cp /root/anaconda-ks.cfg /var/ftp/pub/centos7.cfg
    sed -i '/^graphical$/d' /var/ftp/pub/centos7.cfg
    sed -i 's|^cdrom$|url --url="ftp://192.168.130.1/pub/"|g' /var/ftp/pub/centos7.cfg
    chmod 644 /var/ftp/pub/centos7.cfg
}

configure_pxe() {
    echo "[+]--> Configuring PXE boot menu"

    cat > /var/lib/tftpboot/pxelinux.cfg/default << EOF
default menu.c32
prompt 0
timeout 30
MENU TITLE CentOS_7 PXE Menu
LABEL centos7_x64
MENU LABEL CentOS 7_X64
KERNEL /networkboot/vmlinuz
APPEND initrd=/networkboot/initrd.img inst.repo=ftp://192.168.130.1/pub ks=ftp://192.168.130.1/pub/centos7.cfg
EOF
}

add_firewall_rule() {
    echo "[+]--> Adding firewall rules"

    iptables  -I INPUT 5 -p udp -m udp --dport 69 -m conntrack --ctstate NEW -j ACCEPT
    ip6tables -I INPUT 5 -p udp -m udp --dport 69 -m conntrack --ctstate NEW -j ACCEPT
    iptables  -I INPUT 5 -p tcp -m tcp --dport 21 -m conntrack --ctstate NEW -j ACCEPT
    ip6tables -I INPUT 5 -p tcp -m tcp --dport 21 -m conntrack --ctstate NEW -j ACCEPT
    iptables -I INPUT 5 -p udp -m udp --dport 4011 -m conntrack --ctstate NEW -j ACCEPT
    ip6tables -I INPUT 5 -p udp -m udp --dport 4011 -m conntrack --ctstate NEW -j ACCEPT

    iptables-save > /etc/sysconfig/iptables
    ip6tables-save > /etc/sysconfig/ip6tables
}

restart_svc() {
    echo "[+]--> Restarting DNS server"

    systemctl enable --now xinetd
    systemctl enable --now vsftpd
}

main() {
    echo "[+]--> START"

    install_pkgs
    configure_tftp
    copy_iso_files
    configure_kickstart
    # configure_pxe
    # add_firewall_rule
    # restart_svc

    echo "[+]--> END"
}

main
