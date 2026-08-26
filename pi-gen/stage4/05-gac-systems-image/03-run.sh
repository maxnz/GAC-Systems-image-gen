#!/bin/bash -e

#### Equivalent to ansible-pull for v3.0.2 (https://github.com/maxnz/GAC-Systems-image/blob/master/updates/4.0.2.yaml)

# Add CSinParallel directory
# git clone https://github.com/csinparallel/virtual20-code.git "${ROOTFS_DIR}/etc/skel/CSinParallel"
# echo "Cloned csinparallel/virtual20-code.git"

# git clone https://github.com/csinparallel/virtual20-code.git "${ROOTFS_DIR}/home/pi/CSinParallel"
# on_chroot << EOF
# chown -R pi:pi "/home/pi/CSinParallel"
# EOF
# echo "Add CSinParallel directory to pi user"


# Add update check to the bashrc files

cat << EOF >> "${ROOTFS_DIR}/home/pi/.bashrc"
if [ -e /usr/GACSystems/.updated ]
then 
    cowsay GAC Systems Image has been updated to v\$(cat /usr/GACSystems/version)
    rm /usr/GACSystems/.updated
fi
EOF

cat << EOF >> "${ROOTFS_DIR}/etc/skel/.bashrc"
if [ -e /usr/GACSystems/.updated ]
then 
    cowsay GAC Systems Image has been updated to v\$(cat /usr/GACSystems/version)
    rm /usr/GACSystems/.updated
fi
EOF
echo "Add update check to the bashrc files"

on_chroot << EOF
systemctl set-default graphical.target
EOF
ln -fs "/lib/systemd/system/getty@.service" "${ROOTFS_DIR}/etc/systemd/system/getty.target.wants/getty@tty1.service"
echo "Link Getty service"

install -m 644 files/autologin.conf "${ROOTFS_DIR}/etc/systemd/system/getty@tty1.service.d/autologin.conf"
echo "Add autologin config"

on_chroot << EOF
sed /etc/lightdm/lightdm.conf -i -e "s/^\(#\|\)autologin-user=.*/autologin-user=pi/"
EOF
echo "Edit lightdm config"