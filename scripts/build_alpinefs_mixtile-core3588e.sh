#! /bin/bash

set -euo pipefail

ROOTFS_PAK="alpine.tar.gz"
ROOTFS_DIR="$TOP_DIR/build/alpine"
#MODULE_DIR="$TOP_DIR/build/_module"
PACKAGES_DIR="$TOP_DIR/packages/alpine"
PACKAGES_CONFIG_DIR="$TOP_DIR/packages/configs"
PACKAGE=$1

if [ ! -f "$ROOTFS_PAK" ]; then
    wget -O $ROOTFS_PAK https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/aarch64/alpine-minirootfs-3.22.0-aarch64.tar.gz
    mkdir -p $ROOTFS_DIR
    tar -xvf $ROOTFS_PAK -C $ROOTFS_DIR
fi

export NEW_HOSTNAME="$BOARD"
export VERSION="$BOARD-${CI_VERSION:-dev}"
PLATFORM="${BOARD#mixtile-}"
echo "build version: $VERSION"

sudo cp $PACKAGES_DIR/* $ROOTFS_DIR -a
#fuse-overlayfs   docker-dep
sudo chroot $ROOTFS_DIR /bin/sh -c "apk update && \
			apk add --no-cache alpine-base openssh-server chrony acpid-openrc dhcpcd lsblk openssl\
			eudev usbutils  util-linux iptables ip6tables avahi avahi-tools dbus watchdog \
			json-glib curl bzip2-dev rsyslog && \
			rc-update add sshd default && \
			rc-update add networking default && \
			rc-update add sysctl boot && \
			rc-update add hostname boot && \
			rc-update add chronyd boot && \
			rc-update add acpid default && \
			rc-update add dhcpcd default && \
			rc-update add dbus default && \
			rc-update add rsyslog default && \
			rc-update add avahi-daemon default && \
			rc-update add local default && \
			rc-update add watchdog default"


sudo mkdir -p $ROOTFS_DIR/boot
sed -i '/^tty/d'  "$ROOTFS_DIR/etc/inittab"
sed -i '/^console/d'  "$ROOTFS_DIR/etc/inittab"
echo ttyFIQ0 | sudo tee -a $ROOTFS_DIR/etc/securetty

cat << EOF | sudo chroot $ROOTFS_DIR /bin/sh
chmod a+x /etc/init.d/*
chmod a+x /usr/bin/*


echo "" >  /etc/local.d/start-server.start
chmod a+x  /etc/local.d/start-server.start
echo "auto_set_mac.sh &" >> /etc/local.d/start-server.start
echo "link_part.sh &" >> /etc/local.d/start-server.start
echo "updateAB.sh &" >> /etc/local.d/start-server.start
echo "print-ip &" >> /etc/local.d/start-server.start
echo "fix-solt &" >> /etc/local.d/start-server.start
echo "save-dmesg.sh &" >> /etc/local.d/start-server.start


chmod a+x /usr/bin/hawkbit-updater /etc/init.d/hawkbit-updater /usr/bin/hawkbit-updater-start
rc-update add hawkbit-updater default
rc-update add crond default

# set root passwd
echo "root:root" | chpasswd

# hostname
echo $NEW_HOSTNAME > /etc/hostname
sed -i 's/^\(127\.0\.0\.1\|\:\:1\)[[:space:]]\+localhost[[:space:]]\+.*$/\1\tlocalhost /' /etc/hosts
sed -i 's/^::1\t/::1\t\t/' /etc/hosts

echo $VERSION | tee /etc/version

mkdir -p /userdata && chmod 777 /userdata

# /etc/fstab
sed -i '/[[:space:]]\/tmp[[:space:]]/d' /etc/fstab
echo 'tmpfs   /tmp    tmpfs   defaults,size=100%  0  0' | tee -a /etc/fstab

# ssh
chown root:root /var/empty
chmod 711 /var/empty
ssh-keygen -A

EOF


if [[ "$PACKAGE" == true ]]; then
  echo "Package alpine rootfs"
  tar czf $TOP_DIR/build/$PLATFORM-alpine-rootfs.tar.gz -C $TOP_DIR/build alpine
  mv $TOP_DIR/build/$PLATFORM-alpine-rootfs.tar.gz /$TOP_DIR/build/output
fi
