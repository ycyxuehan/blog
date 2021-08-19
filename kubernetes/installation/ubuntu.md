# ubuntu下安装kubernetes

添加key

```bash
https_proxy=192.168.0.11:1080 curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
```

添加源

```bash
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.tuna.tsinghua.edu.cn/kubernetes/apt kubernetes-xenial main
EOF
```

安装

```bash
apt update && apt install docker.io kubelet kubectl kubeadm -y
```

