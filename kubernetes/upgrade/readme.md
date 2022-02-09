# Kubernetes集群升级

只能从一个次版本升级到下一个次版本，或者在次版本相同时升级补丁版本。 也就是说，升级时不可以跳过次版本。 例如，你只能从 1.y 升级到 1.y+1，而不能从 1.y 升级到 1.y+2。

## 升级control plane

必须先升级第一个controlplane

升级`kubeadm`

```bash
export VERSION="1.20.1"
yum install -y kubeadm-${VERSION}-0 --disableexcludes=kubernetes
```

腾空controlplane

```bash
export NODE="k8smaster1"
kubectl drain ${NODE} --ignore-daemonsets
```

查看是否可以升级以及可升级的版本

```bash
kubeadm upgrade plan
```

升级到指定版本

```bash
kubeadm upgrade apply v${VERSION}
```

取消控制面节点的保护

```bash
kubectl uncordon ${NODE}
```

升级其他controlplane, 参考[升级node](##升级node)

## 升级node

升级之前，请确保control plane已经升级，建议一次只升级1个或部分节点，避免影响服务。

升级`kubeadm`，在node执行

```bash
export VERSION="1.20.1-0"
yum install -y kubeadm-${VERSION} --disableexcludes=kubernetes
```

将节点标记为不可调度并逐出工作负载，为维护做好准备。在control执行

```bash
export NODE="k8snode1"
kubectl drain ${NODE} --ignore-daemonsets
```

输出类似下文

```bash
node/k8snode1 already cordoned
WARNING: ignoring DaemonSet-managed Pods: kube-system/calico-node-jcpf2, kube-system/kube-proxy-rsskt
evicting pod kube-system/calico-kube-controllers-744cfdf676-g86dz
pod/calico-kube-controllers-744cfdf676-g86dz evicted
node/k8snode1 evicted
```

升级kubelet配置，在node执行

```bash
kubeadm upgrade node
```

升级kubelet服务，在node执行

```bash
yum install -y kubelet-${VERSION} kubectl-${VERSION} --disableexcludes=kubernetes
```

重启服务

```bash
systemctl daemon-reload
systemctl restart kubelet
```

将节点标记为可调度，让节点重新上线

```bash
kubectl uncordon ${NODE}
```