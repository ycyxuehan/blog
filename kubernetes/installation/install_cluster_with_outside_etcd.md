# 使用kubeadm安装基于外部etcd集群的kubernetes

安装之前，请确认已经按要求准备好正确数量的节点(最低6个，推荐9个)并已经根据[配置运行环境](config_run_env.md)完成了环境配置。

**注意：本文档所有安装操作均在第一个controllplane节点完成**

## 使用kubeadm安装配置外部etcd集群

### 创建配置

参照[kubeadm 配置示例](kubeadm_config_example.md)创建与准备好的节点符合的配置，每个节点都有各自的配置。配置创建好之后放置于`/tmp/${HOST_IP}`目录下

### 创建证书

需要为每个节点创建证书。

重置当前节点，避免有未清理干净的以前安装的集群

```bash
kubeadm reset -f
```

生成证书颁发机构

```bash
kubeadm init phase certs etcd-ca
```

为每个节点创建证书

```bash
ETCD_HOSTS=(192.168.0.211 192.168.0.212 192.168.0.213)
for HOST in ${ETCD_HOSTS[@]};
do
kubeadm init phase certs etcd-server --config=/tmp/${HOST}/etcdcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${HOST}/etcdcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST}/etcdcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST}/etcdcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${HOST}/
# 清理不可重复使用的证书
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete
# 清理不应从此主机复制的证书
find /tmp/${HOST} -name ca.key -type f -delete
done
```

### 初始化etcd

```bash
scp -r /tmp/kubelet.service.d ${HOST}:/etc/systemd/system/
scp -r /tmp/${HOST}/* ${HOST}:/tmp
ssh ${HOST} "systemctl daemon-reload"
ssh ${HOST} "kubeadm reset -f && rsync -ivhPr /tmp/pki /etc/kubernetes/"
ssh ${HOST} "systemctl restart kubelet && kubeadm init phase etcd local --config=/tmp/etcdcfg.yaml"
```

### 验证安装

```bash
docker run --rm -it --net host -v /etc/kubernetes:/etc/kubernetes registry.bing89.com/kubernetes/etcd:3.4.13-0 etcdctl --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert /etc/kubernetes/pki/etcd/ca.crt --endpoints https://192.168.0.211:2379 endpoint health --cluster
```

***如果没有安装docker，可能需要创建pod的json配置，并使用crictl(参考[Containerd 安装配置与管理](containerd.md))来验证***

## 安装配置haproxy

kubernetes可以使用keepalived、haproxy、kube-vip来实现apiserver的高可用，这里使用haproxy。

参考[haproxy安装与配置](install_haproxy.md)完成haproxy的配置。

## 初始化第一个ControlPlane节点

### 创建controlplane节点配置

参照[kubeadm 配置示例](kubeadm_config_example.md)创建与准备好的节点符合的配置，只需要一份配置。

### 备份并重置节点

```bash
if [ -f /etc/kubernetes/manifests/haproxy.yaml ];then
    cp /etc/kubernetes/manifests/haproxy.yaml /tmp/haproxy.yaml.backup
fi
if [ -f /etc/kubernetes/pki/ca.crt ];then
    cp /etc/kubernetes/pki/ca.crt  /tmp/ca.crt.backup
fi
if [ -f /etc/kubernetes/pki/ca.key ];then
    cp /etc/kubernetes/pki/ca.key /tmp/ca.key.backup
fi
kubeadm reset -f
```

### 复制etcd证书

```bash
ETCD_HOST1=192.168.0.211
if [ ! -d /etc/kubernetes/pki/etcd]
    mkdir /etc/kubernetes/pki/etcd
fi
scp /tmp/${ETCD_HOST1}/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/ca.crt
scp /tmp/${ETCD_HOST1}/pki/apiserver-etcd-client.crt /etc/kubernetes/pki/apiserver-etcd-client.crt
scp /tmp/${ETCD_HOST1}/pki/apiserver-etcd-client.key /etc/kubernetes/pki/apiserver-etcd-client.key
scp /tmp/ca.key /etc/kubernetes/pki/ca.key 
scp /tmp/ca.crt /etc/kubernetes/pki/ca.crt 
```

### 初始化controlplane

```bash
kubeadm init --config /tmp/kubeadmcfg.yaml --upload-certs
```

### 还原haproxy 并重启kubelet

```bash
if [ -f /tmp/haproxy.yaml.backup ];then
    cp /tmp/haproxy.yaml.backup /etc/kubernetes/manifests/haproxy.yaml
    systemctl restart kubelet
fi
```

## 加入其他controlplane节点

备份并重置节点

```bash
if [ -f /etc/kubernetes/manifests/haproxy.yaml ];then
    cp /etc/kubernetes/manifests/haproxy.yaml /tmp/haproxy.yaml.backup
fi
kubeadm reset -f
```

使用kubeadm join... 指令加入集群

还原haproxy 并重启kubelet

```
if [ -f /tmp/haproxy.yaml.backup ];then
    cp /tmp/haproxy.yaml.backup /etc/kubernetes/manifests/haproxy.yaml
    systemctl restart kubelet
fi
```