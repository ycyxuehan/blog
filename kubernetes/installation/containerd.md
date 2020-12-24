# Containerd 安装配置与管理

使用[containerd](https://github.com/containerd/cri)的内置CRI插件作为kubernetes CRI

## 安装

```bash
#使用aliyun的docker-ce镜像源，方便快速安装最新版containerd
yum install -y yum-utils   device-mapper-persistent-data   lvm2
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install -y containerd.io
```
## 配置

containerd 的配置文件位于`/etc/containerd/config.toml`，若系统种还没有这个文件，执行以下命令生成

```bash
containerd config dump >/etc/containerd/config.toml
```

### 配置 cri

1. cgroup driver 为systemd

2. sandbox image为私有仓库镜像

3. 私有镜像仓库不验证证书

```bash
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "registry.bing89.com/kubernetes/pause:3.2"
    systemd_cgroup = true
    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.bing89.com"]
          endpoint = ["https://registry.bing89.com"]
      [plugins."io.containerd.grpc.v1.cri".registry.configs]
        [plugins."io.containerd.grpc.v1.cri".registry.configs."registry.bing89.com".tls]
          insecure_skip_verify = true
        [plugins."io.containerd.grpc.v1.cri".registry.configs."registry.bing89.com".auth]
          username = "xxxx"
          password = "xxxx"
```
### 配置cni

创建网桥

```bash
cat <<EOF >/etc/sysconfig/network-scripts/ifcfg-brcontainerd0
TYPE="Bridge"
UUID="ba72d9bd-9be9-4a87-a587-ee9e070052d2"
DEVICE="brcontainer0"
ONBOOT="yes"
BOOTPROTO="none"
EOF
#重启network
systemctl restart network
```

添加cni网络配置

```bash
cat <<EOF >/etc/cni/net.d/172-my.conf
{
    "cniVersion": "0.2.0",
    "name": "mynet",
    "type": "bridge",
    "bridge": "brcontainer0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "subnet": "172.17.0.0/16",
        "routes": [
            { "dst": "0.0.0.0/0" }
        ],
     "dataDir": "/run/ipam-state"
    },
    "dns": {
      "nameservers": [ "223.5.5.5", "223.6.6.6", "114.114.114.114" ]
    }
}
EOF
```
### 应用配置

重启containerd使配置生效

```bash
systemctl daemon-reload && systemctl restart containerd
```

### 配置critrl

crictl是containerd的管理工具，类似于docker

```bash
cat <<EOF >/etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
```