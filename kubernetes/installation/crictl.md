# crictl
crictl 是一个开源的container runtime 管理工具。

## 安装crictl

crictl是kubeadmin的依赖包，安装kubeadm会自动安装cri-tools包

也可以安装指定版本

```bash
VERSION="v1.20.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz
```

***21-12-09更新，crictl 工具 1.19版(k8s1.23)已经无法兼容containerd 1.4，Redhat8库里面的是1.4无法正常使用，需要安装1.5版本***

## 配置crictl

配置文件位于`/etc/crictl.yaml`

docker

```bash
runtime-endpoint: unix:///var/run/dockershim.sock
image-endpoint: unix:///var/run/dockershim.sock
timeout: 2
debug: true
pull-image-on-create: false
```

containerd

```bash
cat <<EOF >/etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
```

## 创建pod

编写pod配置,需要两个json文件或两个yaml文件

pod.json

```json
{
    "metadata": {
        "name": "nginx-sandbox",
        "namespace": "default",
        "attempt": 1,
        "uid": "hdishd83djaidwnduwk28bcsb"
    },
    "log_directory": "/tmp",
    "linux": {
    }
}
```

container.json

```json
{
  "metadata": {
      "name": "busybox"
  },
  "image":{
      "image": "busybox"
  },
  "command": [
      "top"
  ],
  "log_path":"busybox.0.log",
  "linux": {
  }
}
```
pod.yaml

```yaml
metadata:
  attempt: 1
  name: busybox-sandbox
  namespace: default
  uid: hdishd83djaidwnduwk28bcsb
log_directory: /tmp
linux:
  namespaces:
    options: {}
```

container.yaml

```yaml
metadata:
  name: busybox
image:
  image: busybox:latest
command:
- top
log_path: busybox.0.log
```

执行命令

```bash
crictl runp container.json pod.json
#crictl runp container.yaml pod.yaml
```

## nginx

container.yaml

```yaml
metadata:
  name: nginx
image:
  image: nginx:1.19
log_path: nginx.0.log
mounts:
- container_path: /etc/nginx/nginx.conf
  host_path: /etc/nginx/nginx.conf
  readonly: true
- container_path: /etc/nginx/conf.d
  host_path: /etc/nginx/conf.d
  readonly: true
linux:
  namespaces:
    options: {}
```

pod.yaml

```yaml
metadata:
  attempt: 1
  name: nginx-pod
  namespace: default
log_directory: /tmp/nginx
linux:
  namespaces:
    options: {}
port_mappings:
- host_port: 80
  container_port: 80
  host_ip: 0.0.0.0
- host_port: 443
  container_port: 443
  host_ip: 0.0.0.0
```