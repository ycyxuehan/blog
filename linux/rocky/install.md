# 安装 rocky

## 配置rocky使用国内源

```bash
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.sjtug.sjtu.edu.cn/rocky|g' \
    -i.bak \
    /etc/yum.repos.d/Rocky-*.repo
```