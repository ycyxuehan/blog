# 创建bridge

centos 7.6 之后没有brctl了

```bash
nmcli connection
nmcli connection add type bridge con-name vir0 ifname vir0 autoconnect yes
sudo nmcli connection add type bridge con-name vir0 ifname vir0 autoconnect yes
nmcli connection
sudo nmcli connection add type bridge-slave ifname enp4s0 master vir0 && sudo nmcli connection down enp4s0 && sudo nmcli connection up vir0 && nmcli connection
```