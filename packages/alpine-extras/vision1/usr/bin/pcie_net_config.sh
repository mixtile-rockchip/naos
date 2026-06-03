#!/bin/sh
# pcie_net_config.sh
# Configure network interfaces based on PCIe addresses

echo "=== PCIe Network Interface Configuration ==="

# PCIe address to IP mapping
PCI_0000_01_00_0="192.168.9.1/24"    # Port A - pcie3x4
PCI_0002_21_00_0="192.168.10.1/24"   # Port B - pcie2x1l0
PCI_0001_11_00_0="192.168.11.1/24"   # Port C - pcie3x2
PCI_0003_31_00_0="192.168.12.1/24"   # Port D - pcie2x1l1

# Show PCIe network cards
echo "Scanning PCIe network cards..."
lspci -nn | grep -i "network" || lspci -nn | grep -i "ethernet"

echo ""
echo "Starting configuration..."

# Function to configure a PCIe interface
configure_pcie_interface() {
    pci_addr="$1"
    ip_addr="$2"
    
    echo ""
    echo "Processing $pci_addr -> $ip_addr"
    
    # Check if PCIe device exists
    if [ ! -d "/sys/bus/pci/devices/$pci_addr" ]; then
        echo "  Warning: PCIe device $pci_addr not found, skipping"
        return 1
    fi
    
    # Find network interface
    net_dir="/sys/bus/pci/devices/$pci_addr/net"
    if [ -d "$net_dir" ]; then
        # Get interface name (usually only one)
        iface=$(ls "$net_dir" 2>/dev/null | head -n1)
        
        if [ -n "$iface" ]; then
            echo "  Found interface: $iface"
            echo "  Configuring IP: $ip_addr"
            
            # Bring interface down
            ip link set dev "$iface" down 2>/dev/null
            
            # Clear old IP and set new IP
            ip addr flush dev "$iface" 2>/dev/null
            if ip addr add "$ip_addr" dev "$iface"; then
                # Bring interface up
                if ip link set dev "$iface" up; then
                    # Verify configuration
                    if ip addr show dev "$iface" | grep -q "$ip_addr"; then
                        echo "  Success: $iface configured with $ip_addr"
                        return 0
                    else
                        echo "  Error: IP verification failed for $iface"
                        return 1
                    fi
                else
                    echo "  Error: Failed to bring up $iface"
                    return 1
                fi
            else
                echo "  Error: Failed to set IP on $iface"
                return 1
            fi
        else
            echo "  Error: No network interface found for $pci_addr"
            return 1
        fi
    else
        echo "  Error: No network interface directory for $pci_addr"
        return 1
    fi
}

# Configure each PCIe interface
configure_pcie_interface "0000:01:00.0" "$PCI_0000_01_00_0"
configure_pcie_interface "0002:21:00.0" "$PCI_0002_21_00_0"
configure_pcie_interface "0001:11:00.0" "$PCI_0001_11_00_0"
configure_pcie_interface "0003:31:00.0" "$PCI_0003_31_00_0"

echo ""
echo "=== Current Network Configuration ==="
ip addr show | grep -E "^[0-9]+:" | while read line; do
    ifname=$(echo "$line" | awk -F: '{print $2}' | sed 's/ //')
    echo "Interface: $ifname"
done

ip addr show | grep -E "inet " | grep -v "127.0.0.1" | while read line; do
    echo "  $line"
done

echo ""
echo "=== Configuration Complete ==="
exit 0
