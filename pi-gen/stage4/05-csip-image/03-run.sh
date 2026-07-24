#!/bin/bash -e

#### Equivalent to ansible-pull for v3.0.2 (https://github.com/babatana/csinparallel-image/blob/master/updates/3.0.2.yaml)

# Add CSinParallel directory
git clone https://github.com/csinparallel/virtual20-code.git "${ROOTFS_DIR}/etc/skel/CSinParallel"
echo "Cloned csinparallel/virtual20-code.git"

git clone https://github.com/csinparallel/virtual20-code.git "${ROOTFS_DIR}/home/pi/CSinParallel"
on_chroot << EOF
chown -R pi:pi "/home/pi/CSinParallel"
EOF
echo "Add CSinParallel directory to pi user"


# Add update check to the bashrc files

cat << EOF >> "${ROOTFS_DIR}/home/pi/.bashrc"
if [ -e /usr/s12/.updated ]
then 
    cowsay Systems 1 & 2 Image has been updated to v\$(cat /usr/s12/version)
    rm /usr/s12/.updated
fi
EOF

cat << EOF >> "${ROOTFS_DIR}/etc/skel/.bashrc"
if [ -e /usr/s12/.updated ]
then 
    cowsay Systems 1 & 2 has been updated to v\$(cat /usr/s12/version)
    rm /usr/s12/.updated
fi
EOF
echo "Add update check to the bashrc files" 
