#!/bin/bash

# gac-systems-image: a tool for managing the GAC Systems Image
# Created by Max Narvaez

IMAGEVER=`cat /usr/GACSystems/version`
BRANCH=

show_help() {
    echo "GAC Systems Image Tool $IMAGEVER"
    echo
    echo "A tool for managing your GAC Systems image"
    echo
    echo "Usage: gac-systems-image [-h|-v|info|update|git-fsck|reset-wallpaper]"
    echo "Options:"
    echo "-h                show this help message"
    echo "-v                show the current version of the image"
    echo
    echo "info              show information about this Pi"
    echo "update            check for image updates"
    echo
    echo "change-owner      update the contents of /etc/owner"
    echo "change-boot-user  set autologon to specified user"
    echo
    echo "git-fsck          check all git repositories for errors"
    exit 0
}

show_update_help() {
    echo "GAC Systems Image Tool $IMAGEVER"
    echo
    echo "Update your GAC Systems image"
    echo
    echo "Usage: gac-systems-image update [-h] [--branch BRANCH]" 
    echo "                         [--version-override VERSION]"
    echo "Options:"
    echo "-h                Show this help message"
    echo "-b BRANCH, --branch BRANCH"
    echo "                  Set the branch to update from"
    echo "-v VERSION, --version-override VERSION"
    echo "                  Override the version number"
    exit 0
}

missing_argument() {
    echo "Missing argument for $1"
    exit 1
}

info() {
    SERIAL=`cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2`
    IPv4=`ifconfig wlan0 | grep "inet " | sed 's/  \+/ /g' | cut -d ' ' -f 3`
    MAC=`ifconfig wlan0 | grep ether | sed 's/  \+/ /g' | cut -d ' ' -f 3`
    SDSERIAL=`cat /sys/block/mmcblk0/device/cid`
    HARDREV=`cat /proc/cpuinfo | grep Revision | cut -d ' ' -f 2`

    echo "Image Version:        $IMAGEVER"
    echo "Hardware Revision:    $HARDREV"
    echo "Pi Serial Number:     $SERIAL"
    echo "SD Serial Number:     $SDSERIAL"
    echo "WiFi IP:              $IPv4"
    echo "WiFi MAC:             $MAC"
}

git_fsck() {
    GITDIRS=`find /home -name .git 2> /dev/null`
    GITCHK=0
    for d in $GITDIRS
    do
        cd $d/..
        echo $d
        if ! /usr/bin/git fsck
        then
            GITCHK=1
        fi
        echo
    done
}

# Check the git health of the Pi
get_git_health() {
    GIT_ERRS=$(git_fsck)
    if [ -z "$GIT_ERRS" ]
    then
        echo "Good"
    else
        echo "Errors Found: $(echo $GIT_ERRS)"
    fi
}

update() {
    # Test for internet connection
    tries=0
    while ! ping -c 1 -W 2 8.8.8.8 &> /dev/null
    do
        if [ $tries -gt 3 ]
        then
            /usr/bin/logger -t gac-systems-image "Could not connect to internet"
            exit 1
        fi
        sleep 10
        let "tries++"
    done

    /usr/bin/ansible-pull \
    -U https://github.com/maxnz/GAC-Systems-image.git \
    -e imgVersion=$(cat /usr/HD/version) -C ${BRANCH:-main}
}

change_owner() {
    USERNAME="$1"
    
    # Check that a proper username is specified, otherwise ask until provided one
    while /bin/true
    do
        if [ -z $USERNAME ]
        then
            echo -n "Enter your username: "
            read USERNAME
        elif [[ "${USERNAME,,}" == "none" ]]
        then
            echo "Nice try, but that's not a username"
            echo -n "Enter your username: "
            read USERNAME
        elif [[ "${USERNAME,,}" == "username" ]]
        then
            echo "Nice try, but we want your username, not the literal string 'username'"
            echo -n "Enter your username: "
            read USERNAME
        elif [[ "${USERNAME,,}" == "pi" ]]
        then
            echo "We would like your St. Olaf username or some other identifying string, not 'pi'"
            echo -n "Enter your username: "
            read USERNAME
        else
            break
        fi
    done

    echo $USERNAME > /etc/owner
    echo "Owner has been set to $USERNAME"
}

change_boot_user() {
    if [ "$EUID" -ne 0 ]
    then
        echo "Please run as sudo hd-image change-boot-user"
        return
    fi

    USER="$1"

    # Check that a username is specified, otherwise ask until provided one
    while [ -z $USER ]
    do
        echo -n "Enter your username: "
        read USER
    done

    # Check that user has a home directory
    ## Otherwise the desktop will not load and the user select screen will be shown
    if [[ -d /home/$USER ]]
    then
        # Taken from raspi-config's do_boot_behaviour method (https://github.com/RPi-Distro/raspi-config/blob/master/raspi-config)
        systemctl set-default graphical.target

        ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
        cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF
        sed /etc/lightdm/lightdm.conf -i -e "s/^\(#\|\)autologin-user=.*/autologin-user=$USER/"
        echo "SUCCESS: Will boot to $USER's desktop on next boot"
    else
        echo -e "\e[31mERROR: Specified user does not have a home directory\e[0m"
    fi
}

if test $# -eq 0
then
    show_help
fi    

while test $# -gt 0
do
    case "$1" in
        -h|help)
            show_help
            ;;
        -v|version)
            shift
            echo "Image version is: $IMAGEVER"
            echo
            exit 0
            ;;
        change-boot-user)
            shift
            change_boot_user
            exit 0
            ;;
        change-owner)
            shift
            change_owner
            exit 0
            ;;
        update)
            shift
            while test $# -gt 0
            do
                case "$1" in
                    -h|help)
                        show_update_help
                        ;;
                    -b|--branch)
                        shift
                        if test $# -gt 0
                        then
                            BRANCH=$1
                            shift
                        else
                            missing_argument "-b"
                        fi
                        ;;
                    -v|--version-override)
                        shift
                        if test $# -gt 0
                        then
                            IMAGEVER=$1
                            shift
                        else
                            missing_argument "-v"
                        fi
                        ;;
                    *)
                        show_update_help
                        ;;
                esac
            done
            update
            exit 0
            ;;
        info)
            shift
            info
            exit 0
            ;;
        git-fsck)
            shift
            git_fsck
            exit $GITCHK
            ;;
        *)
            show_help
            ;;
    esac
    exit 0
done
