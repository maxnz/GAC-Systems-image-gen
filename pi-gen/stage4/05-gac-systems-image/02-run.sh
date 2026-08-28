#!/bin/bash -e

#### Equivalent to ansible-pull for v3.0.1 (https://github.com/maxnz/GAC-Systems-image/blob/master/updates/4.0.1.yaml)

# Set static IP

install -m 600 files/Wired.nmconnection "${ROOTFS_DIR}/etc/NetworkManager/system-connections/Wired.nmconnection"
echo "Set static IP"


# Set WiFi connections

install -m 600 files/GustavusLegacy.nmconnection "${ROOTFS_DIR}/etc/NetworkManager/system-connections/GustavusLegacy.nmconnection"
echo "Set GustavusLegacy WiFi"

install -m 600 files/Gustavus-Legacy.nmconnection "${ROOTFS_DIR}/etc/NetworkManager/system-connections/Gustavus-Legacy.nmconnection"
echo "Set Gustavus-Legacy WiFi"


# Add eth0 to DHCP server

sed -i 's/INTERFACESv4=""/INTERFACESv4="eth0"/g' "${ROOTFS_DIR}/etc/default/isc-dhcp-server" 
echo "Add eth0 to DHCP server"


# Configure DHCP server

sed -i 's/option domain-name \"example.org\";//g' "${ROOTFS_DIR}/etc/dhcp/dhcpd.conf"
echo "Configure DHCP server Part 1"

sed -i 's/option domain-name-servers ns1.example.org, ns2.example.org;//g' "${ROOTFS_DIR}/etc/dhcp/dhcpd.conf"
echo "Configure DHCP server Part 2"

cat << EOF >> "${ROOTFS_DIR}/etc/dhcp/dhcpd.conf"
subnet 172.27.0.0 netmask 255.255.255.0 {
    default-lease-time 600;
    max-lease-time 7200;
    option subnet-mask 255.255.255.0;
    option broadcast-address 172.27.0.255;
    option routers 172.27.0.254;
    option domain-name-servers 172.27.0.1;

    range 172.27.0.2 172.27.0.253;
}
EOF
echo "Configure DHCP server Part 3"


# Configure DHCP server service

install -m 644 files/isc-dhcp-server.service "${ROOTFS_DIR}/etc/systemd/system/isc-dhcp-server.service"
echo "Configure DHCP server service"


# Enable dhcp server

on_chroot << EOF
systemctl enable isc-dhcp-server
EOF
echo "Enable dhcp server"
