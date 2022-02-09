# CentOS安装xrdp

xrdp需要安装桌面环境。

```bash
sudo yum group install "Server with GUI"
```

安装xrdp

```bash
sudo yum install xrdp
sudo systemctl enable --now xrdp
echo 'exec gnome-session' >> /etc/xrdp/xrdp.ini
sudo systemctl restart xrdp
```