#! /bin/sh
# 进入 configfs
mkdir -p /sys/kernel/config/usb_gadget/g1
cd /sys/kernel/config/usb_gadget/g1

# 设置设备信息
echo 0x1d6b > idVendor  # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget (NCM)
echo 0x0100 > bcdDevice
echo 0x0200 > bcdUSB

# 设置字符串
mkdir strings/0x409
echo "deadbeef12345678" > strings/0x409/serialnumber
echo "AlpineLinux" > strings/0x409/manufacturer
echo "USB NCM Gadget" > strings/0x409/product

# 创建配置
mkdir configs/c.1
mkdir configs/c.1/strings/0x409
echo "CDC NCM config" > configs/c.1/strings/0x409/configuration
echo 120 > configs/c.1/MaxPower

# 创建 NCM function
mkdir functions/ncm.usb0
ln -s functions/ncm.usb0 configs/c.1/

# 绑定 UDC
ls /sys/class/udc > UDC

sleep 5

ip link set usb0 up
ip addr add 192.168.7.1/24 dev usb0
