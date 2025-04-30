### 🐮 NetCowImplant

NetCowImplant is a stealthy, transparent implant designed to integrate into an existing wired network while preserving full network functionality for the bridged-through device

## It provides:
    Ethernet bridging (eth0 <--> eth1)
    Out-of-band remote control via Tailscale VPN
    Outbound Internet traffic routed via Wi-Fi
    Full persistence at boot
    Auto-installation with one command

## ✅ Requirements
    Raspberry Pi 4b
    Connected Wi-Fi network (wlan0) with Internet
    USB-Ethernet adapter (for second interface)
    Tailscale account
    Ligolo-ng

## 🌐 Tailscale Setup (Control Channel VPN)

```bash
https://tailscale.com/
```
<center>
<img src="https://github.com/TheLaughingCow/NetCowImplant/blob/main/tailscale01.png"/>
</center>

<center>
<img src="https://github.com/TheLaughingCow/NetCowImplant/blob/main/tailscale02.png"/>
</center>

## 🚀 Quick Install (auto-setup)
```bash
curl -sSL https://raw.githubusercontent.com/TheLaughingCow/NetCowImplant/main/install_implant.sh | sudo bash
```
<center>
<img src="https://github.com/TheLaughingCow/NetCowImplant/blob/main/NetCowImplant.gif"/>
</center>

Authenticate to tailscale using your authkey (or normal login):
```bash
sudo tailscale up --authkey tskey-auth-xxxxxxxxxxxxxxxx
```
Then:
```bash
sudo reboot
```

## Tested and validated on:
    ✅ Raspberry Pi 4b (Kali Linux GUI)
    ❌ Raspberry Pi 4b (Debian)
    ❌ NanoPi R2S

## ToDo
    Support Debian
    Support 4G LTE
    Support NanoPi R2S
    
## Contributing

***/!\ All contributions are welcome /!\***

If you wish to contribute to the project, please submit your changes via pull requests on our GitHub repository.
We welcome contributions in code, documentation, testing, or any other improvements.
