# centos 8 安装kde5

本安装方法适用于 centos8， rockylinux8

kde5 并未包含在系统软件仓库中，需要添加epel源

```bash
yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
```

或者

```bash
dnf install epel-release
```

开启epel-extra包

```bash
dnf config-manager --set-enabled powertools
```

安装kde5

```bash
yum group install 'KDE Plasma Workspaces'
systemctl set-default graphical.target
systemctl enable sddm
```

重启电脑

```bash
reboot
```