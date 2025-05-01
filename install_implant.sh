#!/bin/bash
set -e

echo "[+] Deploying NetCowImplant..."

DISTRO=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
echo "[+] Detected distro: $DISTRO"

REQUIRED_PKGS=(bridge-utils isc-dhcp-client curl tar openssh-server)
[[ "$DISTRO" == "debian" ]] && REQUIRED_PKGS+=(ifupdown)

for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        echo "    [o] $pkg missing, installing..."
        apt-get update && apt-get install -y "$pkg"
    else
        echo "    [✓] $pkg already installed"
    fi
done

systemctl enable ssh
systemctl start ssh
echo "[✓] SSH is now active."

if [[ "$DISTRO" == "debian" ]]; then
    sed -i '/iface wlan0/,/^$/d' /etc/network/interfaces || true
    sed -i '/auto wlan0/d' /etc/network/interfaces || true
    echo "[✓] Cleaned /etc/network/interfaces (Debian)."
else
    echo "[✓] Skipped /etc/network/interfaces cleanup (Ubuntu)."
fi

cat << 'EOF' > /usr/local/sbin/setup_bridge.sh
#!/bin/bash
set -e

IFACE1="eth0"
IFACE2=$(ip -o link show | awk -F': ' '{print $2}' | grep -Ev 'lo|wlan0|tailscale0|eth0' | grep -E '^e' | head -n1)

if [ -z "$IFACE2" ]; then
    echo "[!] No secondary interface found. Aborting bridge setup."
    exit 1
fi

echo "[+] Found second interface: $IFACE2"

ip link set "$IFACE1" up
ip link set "$IFACE2" up

ip addr flush dev "$IFACE1"
ip addr flush dev "$IFACE2"

ip link delete br0 type bridge 2>/dev/null || true

brctl addbr br0
brctl addif br0 "$IFACE1"
brctl addif br0 "$IFACE2"

ip link set br0 up
ip link set "$IFACE1" promisc on
ip link set "$IFACE2" promisc on
ip link set br0 promisc on

echo 'interface "br0" { supersede interface-metric 800; }' > /etc/dhcp/dhclient.conf

ip route | grep ^default | grep -v wlan0 | while read -r _ _ _ dev _; do
    ip route del default dev "$dev"
done

dhclient -1 br0
ip route del default dev br0 2>/dev/null || true
EOF

chmod +x /usr/local/sbin/setup_bridge.sh
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

echo "[✓] systemd service setup-bridge.service created."

systemctl daemon-reexec
systemctl enable setup-bridge.service

if ! command -v tailscale >/dev/null 2>&1; then
    echo "[+] Installing Tailscale via official script..."
    curl -fsSL https://tailscale.com/install.sh | sh
else
    echo "[✓] Tailscale already installed."
fi

systemctl enable tailscaled
systemctl start tailscaled
echo "[✓] Tailscale ready to use."

echo "[+] Downloading Ligolo-ng agent..."
mkdir -p /opt/ligolo
curl -sSL https://github.com/nicocha30/ligolo-ng/releases/download/v0.8/ligolo-ng_agent_0.8_linux_arm64.tar.gz -o /opt/ligolo/ligolo-agent.tar.gz
tar -xvzf /opt/ligolo/ligolo-agent.tar.gz -C /opt/ligolo/
rm -f /opt/ligolo/LICENSE /opt/ligolo/README.md /opt/ligolo/ligolo-agent.tar.gz
chmod +x /opt/ligolo/agent
ln -sf /opt/ligolo/agent /usr/local/bin/ligolo
echo "[✓] Ligolo-ng agent ready to use as 'ligolo'"

INSTALLER_PATH=$(readlink -f "$0")
echo "[✓] Deleting installer script: $INSTALLER_PATH"
rm -f "$INSTALLER_PATH"

echo
echo "[✓] NetCowImplant - Installation complete!"
echo
echo "[!] Finish setup with:"
echo "    sudo tailscale up --authkey tskey-xxxxxxxxxxxxxxxx"
echo "    sudo reboot"
echo
echo "[📶] Wi-Fi help:"
echo "    nmcli device wifi list"
echo "    nmcli device wifi connect '<SSID>' password '<PASSWORD>'"
echo "    nmcli connection modify '<SSID>' connection.autoconnect yes"
echo
