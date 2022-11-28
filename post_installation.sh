#!/bin/bash
# nom         : 
# description : scrypt bash post installation (REDDAT)
# param 1     :
# param 2     :
# Auteur      : Baudillon Rémy / Letang Nicolas / Eliott Lavier / Yassine Achchab / Nohann AMAND-REGHAI
# email       : 
# version     : VF



function install_utils ()

{    
echo "###########################################################"
echo "installation des packages"
echo "###########################################################"

    yum update -y && yum upgrade -y    
    yum install rsync screen gdisk \
		iotop dstat sudo vim wget git lynx \
		net-tools mlocate tree iptables iptables-services -y
    yum autoremove --purge -y wpasupplicant
    yum autoremove -y telnet firewalld
}


function create_users() 

{
echo "###########################################################"
echo "Création du user "nimda" et "remy""
echo "###########################################################"

    if ! grep sudo /etc/group > /dev/null 2>&1; then
        groupadd -r sudo
    fi

    if ! id nimda > /dev/null 2>&1; then
        useradd -d /home/nimda -m -c "Admin Default User" -U -G sudo nimda
    fi

    if ! id devuser > /dev/null 2>&1; then
        useradd -d /home/devuser -m -c "Admin User" -U -G sudo devuser
    fi

    echo -e "nextcloud\nnextcloud" | passwd nimda > /dev/null 2>&1
    echo -e "nextcloud\nnextcloud" | passwd devuser > /dev/null 2>&1
}



function add_ssh_keys()

{
echo "###########################################################"
echo "création des cles ssh"
echo "###########################################################"

    install -d -g nimda -o nimda -m 0700 /home/nimda/.ssh
    install -d -g devuser -o devuser -m 0700 /home/devuser/.ssh

    cat > /tmp/ssh_key << EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMdVW/+a9d8oFWjHhLWJRK81u0FEl37ygqxkjA0mAY5t
EOF

    install -g nimda -o nimda -m 0400 -T /tmp/ssh_key /home/nimda/.ssh/authorized_keys
    install -g devuser -o devuser -m 0400 -T /tmp/ssh_key /home/devuser/.ssh/authorized_keys

    rm /tmp/ssh_key
}


function configure_ssh_config() 

{
echo "#########################################################"
echo "Configuration serveur ssh"
echo "#########################################################"
    if ! grep "PermitRootLogin no" /etc/ssh/sshd_config > /dev/null 2>&1; then
        echo -e "PermitRootLogin no\nPubkeyAuthentication yes\nBanner  /etc/issue.net" \
            >> /etc/ssh/sshd_config
    fi

    systemctl restart sshd


}


function root_alias()

{
echo "#########################################################"
echo "Customisation du Shell root"
echo "#########################################################"
    echo "umask 007" >> /root/.bashrc
    echo 'PS1="\[\033[38;5;2m\]\h\[$(tput sgr0)\]@\[$(tput sgr0)\]\[\033[38;5;1m\]\u\[$(tput sgr0)\][\d]\n>\[$(tput sgr0)\]\[\033[38;5;190m\]\w\[$(tput sgr0)\]:\\$ \[$(tput sgr0)\]"'  >> /root/.bashrc 
    cat >> /root/.bashrc << EOF
alias ll="ls -rtl --color"
alias lla="ll -al"
alias rm="rm -v --preserve-root"
alias mkdir="mkdir -vp"
alias mv="mv -vi"
alias min5="find / -type f -mmin 5 -ls"
alias min3="find / -type f -mmin 3 -ls"
alias min5.="find . -type f -mmin 5 -ls"
alias min3.="find . -type f -mmin 3 -ls"
alias chmod="chmod -v --preserve-root"
alias grep="grep --color=auto"
alias oport="netstat -tulanp"
#info memoire 
alias meminfo="free -m -l -t"
#Info process use memory
alias psmem="ps aux | sort -nr -k 4" 
#Info process use cpu
alias pscpu="ps auxf | sort -nr -k 3"
EOF
}

function skel_alias()

{
echo "#########################################################"
echo "Customisation du Shell skel"
echo "#########################################################"

    echo "umask 007" >> /etc/skel/.bashrc
    echo 'PS1="\[\033[38;5;2m\]\h\[$(tput sgr0)\]@\[$(tput sgr0)\]\[\033[38;5;1m\]\u\[$(tput sgr0)\][\d]\n>\[$(tput sgr0)\]\[\033[38;5;190m\]\w\[$(tput sgr0)\]:\\$ \[$(tput sgr0)\]"'  >> /etc/skel/.bashrc
    cat >> /etc/skel/.bashrc << EOF
alias ll="ls -rtl --color"
alias lla="ll -al"
alias rm="rm -v --preserve-root"
alias mkdir="mkdir -vp"
alias mv="mv -vi"
alias min5="find / -type f -mmin 5 -ls"
alias min3="find / -type f -mmin 3 -ls"
alias min5.="find . -type f -mmin 5 -ls"
alias min3.="find . -type f -mmin 3 -ls"
alias chmod="chmod -v --preserve-root"
alias grep="grep --color=auto"
alias oport="netstat -tulanp"
#info memoire
alias meminfo="free -m -l -t"
#Info process use memory
alias psmem="ps aux | sort -nr -k 4"
#Info process use cpu
alias pscpu="ps auxf | sort -nr -k 3"
EOF
}

function user_alias()

{
	local u=$1
echo "#########################################################"
echo "Customisation du Shell user"
echo "#########################################################"
    echo "umask 007" >> /home/$u/.bashrc
    echo 'PS1="\[\033[38;5;2m\]\h\[$(tput sgr0)\]@\[$(tput sgr0)\]\[\033[38;5;1m\]\u\[$(tput sgr0)\][\d]\n>\[$(tput sgr0)\]\[\033[38;5;190m\]\w\[$(tput sgr0)\]:\\$ \[$(tput sgr0)\]"'  >> /home/$u/.bashrc
    cat >> /home/$u/.bashrc << EOF
alias ll="ls -rtl --color"
alias lla="ll -al"
alias rm="rm -v --preserve-root"
alias mkdir="mkdir -vp"
alias mv="mv -vi"
alias min5="find / -type f -mmin 5 -ls"
alias min3="find / -type f -mmin 3 -ls"
alias min5.="find . -type f -mmin 5 -ls"
alias min3.="find . -type f -mmin 3 -ls"
alias chmod="chmod -v --preserve-root"
alias grep="grep --color=auto"
alias oport="netstat -tulanp"
#info memoire
alias meminfo="free -m -l -t"
#Info process use memory
alias psmem="ps aux | sort -nr -k 4"
#Info process use cpu
alias pscpu="ps auxf | sort -nr -k 3"
EOF

}

function configure_banner() 

{
echo "#########################################################"
echo "Customisation de la banniere ssh"
echo "#########################################################"

    cat > /etc/issue.net << EOF
**************************************************************************
                            NOTICE TO USERS

This computer system is the private property of its owner, whether
individual, corporate or government.  It is for authorized use only.
Users (authorized or unauthorized) have no explicit or implicit
expectation of privacy.

Any or all uses of this system and all files on this system may be
intercepted, monitored, recorded, copied, audited, inspected, and
disclosed to your employer, to authorized site, government, and law
enforcement personnel, as well as authorized officials of government
agencies, both domestic and foreign.

By using this system, the user consents to such interception, monitoring,
recording, copying, auditing, inspection, and disclosure at the
discretion of such personnel or officials.  Unauthorized or improper use
of this system may result in civil and criminal penalties and
administrative or disciplinary action, as appropriate. By continuing to
use this system you indicate your awareness of and consent to these terms
and conditions of use. LOG OFF IMMEDIATELY if you do not agree to the
conditions stated in this warning.

****************************************************************************
EOF
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



function harden_fstab() 

{
echo "#########################################################"
echo "config fstable"
echo "#########################################################"

    cat > /etc/fstab << EOF
#
# /etc/fstab
#
UUID="87bac2ce-a37d-4db9-9a57-a38ea889001e" /            xfs    defaults,nodev,x-systemd.device-timeout=0 0 0
UUID=14474fbd-90b8-4275-b2a4-a91242d1da83   /boot        xfs    defaults,nosuid,nodev,noexec 0 0
UUID=C5C9-D1CC                              /boot/efi    vfat   nosuid,nodev,noexec,umask=0077,shortname=winnt 0 0
UUID="c8581ccc-6015-4845-aa3b-63c1317141de" /tmp         xfs    defaults,nosuid,nodev,x-systemd.device-timeout=0 0 0
UUID="8059cd8f-3fa8-4edc-8ee7-6de36bb38878" /var         xfs    defaults,nosuid,nodev,noexec,x-systemd.device-timeout=0 0 0
UUID="0b853bb1-cec7-4c47-91b1-1b24bcf7df33" /var/log     xfs    defaults,nosuid,nodev,noexec,x-systemd.device-timeout=0 0 0
UUID="3c027ab2-d119-4c6f-8f1f-63606f73f994" /var/tmp     xfs    defaults,nosuid,nodev,x-systemd.device-timeout=0 0 0
EOF
}


function configure_network() 

{
echo "#########################################################"
echo "config reseau"
echo "#########################################################"

    sed -i "s/ONBOOT=no/ONBOOT=yes/g" /etc/sysconfig/network-scripts/ifcfg-enp0s3
    systemctl restart network
}


function backup_block_devices() 

{
echo "#########################################################"
echo "backup disque (LUKS / GPT / LVM)"
echo "#########################################################"

    if [ ! -f ./luks_header.bin ]; then
        cryptsetup luksHeaderBackup /dev/sda3 --header-backup-file ./luks_header.bin
    fi

    sgdisk --backup ./gpt.bin /dev/sda
    vgcfgbackup -f ./lvm.txt VGCRYPT
}

function remove_swap() 

{
echo "#########################################################"
echo "suppresion de la partition SWAP"
echo "#########################################################"

    if grep swap /etc/fstab > /dev/null 2>&1; then
        swapoff -U /dev/mapper/VGCRYPT-lv_swap
        lvremove -y VGCRYPT/lv_swap
        sed -i 's|rd.lvm.lv=VGCRYPT/lv_swap ||g' /etc/default/grub
        grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
    fi
}


function setup_zram() 

{
echo "#########################################################"
echo "Mise en place du Zram"
echo "#########################################################"

    if [ ! -d /etc/zram ]; then
        mkdir /etc/zram
    fi

    cat > /etc/zram/run.sh << EOF
#!/bin/bash
modprobe zram
echo lzo > /sys/block/zram0/comp_algorithm
echo 100M > /sys/block/zram0/disksize
mkswap --label zram0 /dev/zram0
swapon --priority 100 /dev/zram0
EOF
    chmod u+x /etc/zram/run.sh

    cat > /etc/systemd/system/zram.service << EOF
[Unit]
Description=Create swap on /dev/zram0
After=local-fs.target
DefaultDependencies=false

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/etc/zram/run.sh
ExecStop=/usr/bin/swapoff /dev/zram0

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable --now zram
}

function secure_grub ()

{
echo "#########################################################"
echo "Securisation du grub par mot de passe"
echo "#########################################################"

        echo "### Initilisation du mot de passe grub ###"
        grub2-setpassword
        cp /boot/efi/EFI/centos/grub.cfg /boot/efi/EFI/grub.cfg.bak
        sed -i "s/--unrestricted/ /g" /boot/efi/EFI/centos/grub.cfg

}


function main ()

{
	install_utils
	sleep 15
	create_users
	sleep 15
	add_ssh_keys
	sleep 15
	configure_ssh_config
	sleep 15
	root_alias
	skel_alias
	user_alias devuser
	sleep 15
	configure_banner
	sleep 15
	configure_firewall
	sleep 15
	harden_fstab
	sleep 15
	configure_network
	sleep 15
	backup_block_devices
	sleep 15
	remove_swap
	sleep 15
	setup_zram
	sleep 15
	secure_grub

echo "this is the end"

sleep 15
#reboot

}

main