#!/bin/sh

# Log file path
LOG_FILE="/var/log/usb_rndis.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Starting USB gadget configuration..."

sleep 1

USB_FUNCTIONS_DIR=/sys/kernel/config/usb_gadget/g1/functions
USB_CONFIGS_DIR=/sys/kernel/config/usb_gadget/g1/configs/b.1

log_message "Setting up USB hardware registers..."
io -4 0xfd5d4010 0x000c000c

log_message "Switching USB controller to device mode..."
echo device > /sys/kernel/debug/usb/fc400000.usb/mode

log_message "Preparing USB FFS and configfs..."
mkdir /dev/usb-ffs
mount -t configfs none /sys/kernel/config

mkdir -p /sys/kernel/config/usb_gadget/g1
mkdir -p /sys/kernel/config/usb_gadget/g1/strings/0x409
mkdir -p ${USB_CONFIGS_DIR}/strings/0x409

log_message "Configuring USB device descriptors..."
echo 0x2207 > /sys/kernel/config/usb_gadget/g1/idVendor
echo 0x0310 > /sys/kernel/config/usb_gadget/g1/bcdDevice
echo 0x0300 > /sys/kernel/config/usb_gadget/g1/bcdUSB
echo 239 > /sys/kernel/config/usb_gadget/g1/bDeviceClass
echo 2 > /sys/kernel/config/usb_gadget/g1/bDeviceSubClass
echo 1 > /sys/kernel/config/usb_gadget/g1/bDeviceProtocol

SERIAL_NUM=`cat /proc/cpuinfo |grep Serial | awk -F ":" '{print $2}'`
log_message "Device serial number: $SERIAL_NUM"
echo $SERIAL_NUM > /sys/kernel/config/usb_gadget/g1/strings/0x409/serialnumber
echo "g1" > /sys/kernel/config/usb_gadget/g1/strings/0x409/manufacturer
echo "UVC" > /sys/kernel/config/usb_gadget/g1/strings/0x409/product

echo 0x1 > /sys/kernel/config/usb_gadget/g1/os_desc/b_vendor_code
echo "MSFT100" > /sys/kernel/config/usb_gadget/g1/os_desc/qw_sign
echo 500 > /sys/kernel/config/usb_gadget/g1/configs/b.1/MaxPower

echo 0x0016 > /sys/kernel/config/usb_gadget/g1/idProduct

log_message "Creating RNDIS function..."
mkdir /sys/kernel/config/usb_gadget/g1/functions/rndis.gs0
echo "rndis" > ${USB_CONFIGS_DIR}/strings/0x409/configuration
ln -s ${USB_FUNCTIONS_DIR}/rndis.gs0 ${USB_CONFIGS_DIR}/f2

log_message "Enabling USB device controller..."
echo "fc400000.usb" > /sys/kernel/config/usb_gadget/g1/UDC

log_message "Configuring usb0 network interface..."
mac=$(otp read| awk -F': ' '/^MAC:/ {print $2}')
sn=$(cat /etc/SN)
crc=$(echo -n "$sn" | cksum | awk '{print $1}')
x=$(( (crc >> 8) & 0xFF ))
y=$(( crc & 0xFF ))
ip addr add 10.$x.$y.1/24 dev usb0
if [ "$mac" != "00:00:00:00:00:00" ]; then
    ip link set usb0 address "$mac"
fi
ip link set usb0 up

log_message "USB gadget configuration completed successfully."

CONFIG="/etc/dnsmasq.conf"
SEARCH="10.$x.$y.2"
REPLACE="dhcp-range=usb0,10.$x.$y.2,10.$x.$y.255,255.255.255.0,12h"

if ! grep -q "$SEARCH" "$CONFIG"; then
        sed -i "s/^dhcp-range=usb0.*/$REPLACE/" "$CONFIG"
        rc-service dnsmasq restart
        log_message "Replace the DHCP gateway"
fi
