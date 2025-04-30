####🐮 NetCowImplant

NetCowImplant is a stealthy transparent implant designed to bridge into an existing wired network while preserving full network functionality for a victim device.

###It provides:
    Ethernet bridging (eth0 <--> eth1)
    Out-of-band remote control via Tailscale VPN
    Outbound Internet traffic routed via Wi-Fi or 4G
    Full persistence at boot
    Auto-installation with one command

###✅ Requirements
    Raspberry Pi 4 (or NanoPi R2S)
    (Optional) 4G USB modem (wwan0)
    Connected Wi-Fi network (wlan0) with Internet
    USB-Ethernet adapter (for second interface)
    Tailscale account

###🌐 Tailscale Setup (Control Channel)
```https://tailscale.com/```

###🚀 Quick Install (1-line auto-setup)
```curl -sSL https://raw.githubusercontent.com/TheLaughingCow/NetCowImplant/main/install_implant.sh | sudo bash```

Authenticate to tailscale using your authkey (or normal login):
```sudo tailscale up --authkey tskey-auth-xxxxxxxxxxxxxxxx```

###Tested and validated on:
    ✅ Raspberry Pi 4 (Kali Linux GUI)
    ❌ Raspberry Pi 4 (Debian)
    ❌ NanoPi R2S (with 4G USB modem, optional)

###ToDo
    Support 4G LTE
    Support 
