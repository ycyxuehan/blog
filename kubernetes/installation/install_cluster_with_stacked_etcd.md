# 使用kubeadm安装基于堆叠etcd的kubernetes

安装之前，请确认已经按要求准备好正确数量的节点(最低3个，推荐6个)并已经根据[配置运行环境](config_run_env.md)完成了环境配置。

## 安装配置haproxy

kubernetes可以使用keepalived、haproxy、kube-vip来实现apiserver的高可用，这里使用haproxy。

参考[haproxy安装与配置](install_haproxy.md)完成haproxy的配置。

## 创建配置

参照[kubeadm 配置示例](kubeadm_config_example.md)创建与准备好的节点符合的配置，每个节点都有各自的配置。配置创建好之后放置于`/tmp/${HOST_IP}`目录下

## 初始化第一个controlplane

备份并重置节点

```bash
if [ -f /etc/kubernetes/manifests/haproxy.yaml ];then
    cp /etc/kubernetes/manifests/haproxy.yaml /tmp/haproxy.yaml.backup
fi
kubeadm reset -f
```

初始化controlplane

```bash
kubeadm init --config /tmp/kubeadmcfg.yaml
```

还原haproxy 并重启kubelet

```bash
if [ -f /tmp/haproxy.yaml.backup ];then
    cp /tmp/haproxy.yaml.backup /etc/kubernetes/manifests/haproxy.yaml
    systemctl restart kubelet
fi
```

## 初始化其他节点

备份并重置节点

```bash
if [ -f /etc/kubernetes/manifests/haproxy.yaml ];then
    cp /etc/kubernetes/manifests/haproxy.yaml /tmp/haproxy.yaml.backup
fi
kubeadm reset -f
```

使用kubeadm join... 指令加入集群

还原haproxy 并重启kubelet

```bash
if [ -f /tmp/haproxy.yaml.backup ];then
    cp /tmp/haproxy.yaml.backup /etc/kubernetes/manifests/haproxy.yaml
    systemctl restart kubelet
fi
```

