#!/bin/bash -e

#### Equivalent to ansible-pull for v4.0.0 (https://github.com/maxnz/GAC-Systems-image/blob/master/updates/4.0.0.yaml)

# Enable VNC Server

on_chroot << EOF
systemctl enable wayvnc.service
EOF
echo "Enabled VNC server"

#Set Resolution to DMT Mode 82 1920x1080 60Hz 16:9
sed -i 's/#hdmi_force_hotplug=1/hdmi_force_hotplug=1/g' "${ROOTFS_DIR}/boot/config.txt"
sed -i 's/#hdmi_group=1/hdmi_group=2/g' "${ROOTFS_DIR}/boot/config.txt"
sed -i 's/#hdmi_mode=1/hdmi_mode=82/g' "${ROOTFS_DIR}/boot/config.txt"
echo "Set Resolution to DMT Mode 82 1920x1080 60Hz 16:9"

# GACSystems Files

install -m 777 -d "${ROOTFS_DIR}/usr/GACSystems"
echo "Created GACSystems Directory"

install -m 666 files/version "${ROOTFS_DIR}/usr/GACSystems"
install -m 777 files/gac-systems-image.bash "${ROOTFS_DIR}/usr/GACSystems"
install -m 777 files/get-info.bash "${ROOTFS_DIR}/usr/GACSystems"
echo "Populated GACSystems directory"

ln -f -s "/usr/GACSystems/gac-systems-image.bash" "${ROOTFS_DIR}/usr/bin/gac-systems-image"
echo "Created gac-systems-image symlink"

install -m 644 files/Updater.service "${ROOTFS_DIR}/lib/systemd/system/Updater.service"
echo "Added Updater service"

on_chroot << EOF
systemctl enable Updater
EOF
echo "Enabled Updater service"

# Set Keyboard Locale

cat << EOF >> "${ROOTFS_DIR}/etc/default/keyboard"
XKBMODEL=pc105
XKBLAYOUT=us
XKBVARIANT=
XKBOPTIONS=
BACKSPACE=guess
EOF


# Temporary workaround for https://github.com/RPi-Distro/pi-gen/issues/414 until it's updated

# echo 0 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-3f300000.mmcnr:wlan"
# echo 0 > "${ROOTFS_DIR}/var/lib/systemd/rfkill/platform-fe300000.mmcnr:wlan"
