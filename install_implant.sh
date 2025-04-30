#!/bin/bash

set -e
echo "[+] Deploying network implant..."

# 1. Install required packages
REQUIRED_PKGS=(bridge-utils ifupdown isc-dhcp-client)
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "    [-] $pkg missing, installing..."
        apt-get update && apt-get install -y "$pkg"
    else
        echo "    [+] $pkg already installed"
    fi
done

# 2. Set wlan0 metric to 100 in /etc/network/interfaces
if grep -q "iface wlan0" /etc/network/interfaces; then
    sed -i '/iface wlan0 inet dhcp/!b;n;c\    metric 100' /etc/network/interfaces
else
    echo -e "\nauto wlan0\niface wlan0 inet dhcp\n    metric 100" >> /etc/network/interfaces
fi

# 3. Create /usr/local/sbin/setup_bridge.sh
cat << 'EOF' > /usr/local/sbin/setup_bridge.sh
#!/bin/bash

set -e

# Bring up physical interfaces
ip link set eth0 up
ip link set eth1 up

# Flush existing IPs (if any)
ip addr flush dev eth0
ip addr flush dev eth1

# Remove previous bridge if exists
ip link delete br0 type bridge 2>/dev/null || true

# Create and configure bridge
brctl addbr br0
brctl addif br0 eth0
brctl addif br0 eth1

ip link set br0 up
ip link set eth0 promisc on
ip link set eth1 promisc on
ip link set br0 promisc on

# Remove all default routes except wlan0
ip route | grep ^default | grep -v wlan0 | while read -r _ _ _ dev _; do
    ip route del default dev "$dev"
done

# Ensure br0 has metric 200
if ! grep -q "metric 200" /etc/network/interfaces; then
    sed -i '/iface br0 inet dhcp/a\    metric 200' /etc/network/interfaces
fi

# Launch DHCP only on br0
dhclient -1 br0
EOF

chmod +x /usr/local/sbin/setup_bridge.sh
echo "[+] Script /usr/local/sbin/setup_bridge.sh created."

# 4. Create systemd service
cat << 'EOF' > /etc/systemd/system/setup-bridge.service
[Unit]
Description=Setup bridge br0 at boot
After=network.target
Wants=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/setup_bridge.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

echo "[+] Systemd service setup-bridge.service created."

# 5. Configure NetworkManager to ignore eth0 and eth1
NM_CONF="/etc/NetworkManager/NetworkManager.conf"
echo "[+] Configuring NetworkManager to ignore eth0 and eth1..."
if ! grep -q "\[keyfile\]" "$NM_CONF"; then
    echo -e "\n[keyfile]" >> "$NM_CONF"
fi
if grep -q "unmanaged-devices=" "$NM_CONF"; then
    sed -i '/unmanaged-devices=/c\unmanaged-devices=interface-name:eth0;interface-name:eth1' "$NM_CONF"
else
    echo "unmanaged-devices=interface-name:eth0;interface-name:eth1" >> "$NM_CONF"
fi

systemctl restart NetworkManager
echo "[+] NetworkManager restarted."

# 6. Enable bridge service at boot
systemctl daemon-reload
systemctl enable setup-bridge.service
echo "[+] setup-bridge.service enabled."

# 7. Self-delete this script
INSTALLER_PATH=$(readlink -f "$0")
echo "[+] Deleting installer script: $INSTALLER_PATH"
rm -f "$INSTALLER_PATH"

echo "[✓] Installation complete. Reboot the machine : sudo reboot."
