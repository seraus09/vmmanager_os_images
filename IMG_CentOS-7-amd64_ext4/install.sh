#!/bin/sh
 
clean_files() {
        rm -f /etc/ssh/*key*
        sed -r -i '/sh \/dev\/sda/d' /etc/rc.d/rc.local
        chmod -x /etc/rc.d/rc.local
}
 
 
disk_format() {
        growpart /dev/vda 2 -u auto
}

resize_fs() {
        cat >> /etc/init.d/resize_fs << EOF
#!/bin/bash
#
# Resize fs
#
### BEGIN INIT INFO
# Default-Start:        1 2 3 4 5
# Default-Stop:         0 6
# Required-Start:
# Required-Stop?
# Short-Description:    Resize root filesystem
# Description:          Resize root filesystem
# Provides:             resize_fs
### END INIT INFO
 
. /etc/init.d/functions
 
case "\$1" in
        start|reload)
                resize2fs /dev/vda2
                chkconfig --del resize_fs
                rm -f /etc/init.d/resize_fs
                exit 0
                ;;
        *)
                echo "service resize_fs start"
                exit 2
esac
 
EOF
chmod +x /etc/init.d/resize_fs
chkconfig --add resize_fs
}
 
network_configure() {
        echo "" > /etc/sysconfig/network-scripts/ifcfg-eth0
        IPv4=($IPv4)
        NETMASK=($NETMASKv4)
        GATEWAYv4=($GATEWAYv4)
        IPv6=($IPv6)
        PREFIX=($NETMASKv6)
        GATEWAYv6=($GATEWAYv6)
        HOSTNAME=($HOSTNAME)

        HSHORT=$(echo "($HOSTNAME)" | cut -d. -f1)
        HSLAST=$(echo "($HOSTNAME)" | sed "s/${HSHORT}\.//")
        echo "($HOSTNAME)" > /etc/hostname
        sed -r -i "s/search.*/search ${HSLAST}/" /etc/resolv.conf
        #echo "options timeout:3 attempts:3" >> /etc/resolv.conf

cat <<EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF
        grep -q "($HOSTNAME)" /etc/hosts || echo "($IP) ($HOSTNAME)" >> /etc/hosts

 
        if [ -n "${GATEWAYv4}" ]; then
                GATEWAY=${GATEWAYv4}
        else
                GATEWAY=${GATEWAYv6}
        fi

        if [ "($NAMESERVERS)" != "" ] && [ "($NAMESERVERS)" != "()" ]; then
        nslist="($NAMESERVERS)"
        sed -i -r '/^nameserver\s/d' /etc/resolv.conf
        for ns in ${nslist}; do
                echo "nameserver ${ns}" >> /etc/resolv.conf
        done
        fi

        # Removing udev rules
        # rm -f /etc/udev/rules.d/70-persistent-net.rules
 
 
        # Configuring network
#        sed -r -i '/HOSTNAME=.+/d; /GATEWAY=.+/d' /etc/sysconfig/network
# cat >> /etc/sysconfig/network << EOF
# HOSTNAME=${HOSTNAME}
# GATEWAY=${GATEWAY}
# EOF


        ETHDEV=$(ip route show | grep default | grep -Eo 'dev\ .+\ ' | awk '{print $2}'| head -1)
        HWADDR=$(ip link show eth0 | awk '/link\/ether/ {print $2}' | tr [:lower:] [:upper:])
        UUID=$(uuidgen eth0)


if [ "($TMPIPv4)" != "" ] && [ "($TMPIPv4)" != "()" ]; then
        # Это новая схема, тут могут быть 2 ip адреса
        TMPIPv4="($TMPIPv4)"
        MULTIIP=true
else
        if [ -n "($IPv6)" ]; then
                TMPIPv4=true
        else
                TMPIPv4=false
        fi
        MULTIIP=false
fi

if [ "($NEXTHOPIPv4)" != "" ] && [ "($NEXTHOPIPv4)" != "()" ]; then
        VPU4=true
fi


if [ -n "($IPv6)" ]; then
        if [ "#${MULTIIP}" = "#false" ] || [ "#${TMPIPv4}" = "#true" ] && [ -z "${VPU4}" ]; then
                # либо старая схема, либо временный IPv4
                echo "NETWORKING=yes" > /etc/sysconfig/network
                echo "HOSTNAME=($HOSTNAME)" >> /etc/sysconfig/network

                cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="static"
DNS1="($NAMESERVERv6)"
HWADDR="${HWADDR}"
NM_CONTROLLED="no"
ONBOOT="yes"
TYPE="Ethernet"
UUID="${UUID}"
EOF
    fi

cat >> /etc/sysconfig/network << EOF
NETWORKING_IPV6=yes
IPV6_DEFAULTGW=($GATEWAYv6)
EOF

cat >> /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
IPV6ADDR="($IPv6)/($NETMASKv6)"
IPV6INIT="yes"
IPV6_AUTOCONF="no"
IPV6_DEFAULTGW="($GATEWAYv6)"
EOF

        if [ "($NEXTHOPIPv6)" != "" ] && [ "($NEXTHOPIPv6)" != "()" ]; then
                echo "SCOPE=\"peer ($NEXTHOPIPv6)\"" >> /etc/sysconfig/network-scripts/ifcfg-eth0
                echo "ADDRESS0=0.0.0.0" > /etc/sysconfig/network-scripts/route-eth0
                echo "NETMASK0=0.0.0.0" >> /etc/sysconfig/network-scripts/route-eth0
                echo "GATEWAY0=($NEXTHOPIPv6)" >> /etc/sysconfig/network-scripts/route-eth0
        fi
fi

if [ "($NEXTHOPIPv4)" != "" ] && [ "($NEXTHOPIPv4)" != "()" ] && [ "($IP)" != "($IPv6)" ]; then
        cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="static"
HWADDR="${HWADDR}"
NM_CONTROLLED="no"
ONBOOT="yes"
TYPE="Ethernet"
UUID="${UUID}"

IPADDR=($IP)
NETMASK=255.255.255.255
EOF

        echo "SCOPE=\"peer ($NEXTHOPIPv4)\"" >> /etc/sysconfig/network-scripts/ifcfg-eth0
        echo "ADDRESS0=0.0.0.0" > /etc/sysconfig/network-scripts/route-eth0
        echo "NETMASK0=0.0.0.0" >> /etc/sysconfig/network-scripts/route-eth0
        echo "GATEWAY0=($NEXTHOPIPv4)" >> /etc/sysconfig/network-scripts/route-eth0
fi

if [ "($IP)" != "($IPv6)" ]; then
        cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
UUID="${UUID}"
IPADDR="($IP)"
NETMASK="($NETMASK)"
GATEWAY="($GATEWAY)"
BOOTPROTO="static"
DEVICE="eth0"
ONBOOT="yes"
IPV6INIT="yes"
EOF

fi

if [ "#${MULTIIP}" = "#true" ]; then
        if [ "($IPv4ALIASES)" != "" ] && [ "($IPv4ALIASES)" != "()" ]; then
                ipnum=1
                IPv4ALIASES="($IPv4ALIASES)"
                for ipv4alias in ${IPv4ALIASES}; do
                        echo "DEVICE=eth0:${ipnum}" > /etc/sysconfig/network-scripts/ifcfg-eth0:${ipnum}
                        echo "IPADDR=${ipv4alias}" >> /etc/sysconfig/network-scripts/ifcfg-eth0:${ipnum}
                        echo "NETMASK=255.255.255.255" >> /etc/sysconfig/network-scripts/ifcfg-eth0:${ipnum}
                        ipnum=$(expr ${ipnum} + 1)
                done
        fi
        if [ "($IPv6ALIASES)" != "" ] && [ "($IPv6ALIASES)" != "()" ]; then
                echo "IPV6ADDR_SECONDARIES=\"($IPv6ALIASES)\"" >> /etc/sysconfig/network-scripts/ifcfg-eth0
        fi
fi

# DNS start
if [ "($NAMESERVERS)" != "" ] && [ "($NAMESERVERS)" != "()" ]; then
        nslist="($NAMESERVERS)"
        sed -i -r '/DNS1=/d' /etc/sysconfig/network-scripts/ifcfg-eth0
        num=0
        for ns in ${nslist}; do
                num=$((num + 1))
                echo "DNS${num}=${ns}" >> /etc/sysconfig/network-scripts/ifcfg-eth0
        done
fi
# DNS end

        #ifup eth0
        systemctl restart network
}

ssh_keys_add() {
cat >> /root/.ssh/authorized_keys << EOF
($SSHPUBKEYS)
EOF
}

clean_files
disk_format
resize_fs
echo "($PASS)" | passwd --stdin root
network_configure
ssh_keys_add
wget -q -O /dev/null --no-check-certificate "($FINISH)"
reboot
