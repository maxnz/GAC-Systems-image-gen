#!/bin/bash

# Check the git health of the Pi
function get_git_health() {
    if gac-systems-image git-fsck &> /dev/null
    then
        echo "Good"
    else
        echo "Errors Found"
    fi
}

# Get the current version of the image
function get_image_version() {
    cat /usr/GACSystems/version
}

# Get the IP for a specific interface
function get_ip() {
    if [ $# -ne 1 ]
    then
        return 1
    else
        ip address show $1 | grep "inet " | sed 's/  \+/ /g' | cut -d ' ' -f 3 | cut -d '/' -f 1
    fi
}

# Get the MAC address for a specific interface
function get_mac() {
    if [ $# -ne 1 ]
    then
        return 1
    else
        ip address show $1 | grep "link/ether" | sed 's/  \+/ /g' | cut -d ' ' -f 3
    fi
}

# Get the owner of the Pi as specified by /etc/owner
function get_owner() {
    cat /etc/owner
}

# Get the Pi revision
function get_pi_rev() {
    cat /proc/cpuinfo | grep Revision | cut -d ' ' -f 2
}

# Get the Pi's serial number
function get_pi_serial() {
    cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2
}

# Get the SD Card's serial number
function get_sd_serial() {
    cat /sys/block/mmcblk0/device/cid
}

