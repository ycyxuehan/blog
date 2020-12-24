# kubeadm 配置示例

## 单ControlPlane节点

```yaml
# 配置kubelet使用systemd作为cgroups驱动
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: "192.168.0.200:8443"
imageRepository: registry.bing89.com/kubernetes
networking:
  podSubnet: 10.244.0.0/16
```

## 基于堆叠etcd的cluster

```yaml
# 配置kubelet使用systemd作为cgroups驱动
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: stable
imageRepository: registry.bing89.com/kubernetes
controlPlaneEndpoint: 192.168.0.200:8443
apiServer:
  certSANs:
  - "k8smaster1"
  - "k8smaster2"
  - "k8smaster3"
  - "192.168.0.200"
  - "192.168.0.201"
  - "192.168.0.202"
  - "192.168.0.203"
networking:
  podSubnet: 10.244.0.0/16

---
#配置kubeproxy使用ipvs。似乎不配置也行
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
EOF
```

## 基于外部etcd集群的cluster

```yaml
# 配置kubelet使用systemd作为cgroups驱动
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: "192.168.0.200:8443"
imageRepository: registry.bing89.com/kubernetes
etcd:
    external:
        endpoints: ["https://192.168.0.211:2379","https://192.168.0.212:2379","https://192.168.0.213:2379"]
        caFile: /etc/kubernetes/pki/etcd/ca.crt
        certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
        keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key
apiServer:
  certSANs: ["192.168.0.201","192.168.0.202","192.168.0.203"]
```

## 外部etcd集群配置

```yaml
# 配置kubelet使用systemd作为cgroups驱动
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
---
apiVersion: "kubeadm.k8s.io/v1beta2"
kind: ClusterConfiguration
imageRepository: registry.bing89.com/kubernetes
etcd:
    local:
        serverCertSANs:
        - "192.168.0.211"
        peerCertSANs:
        - "192.168.0.211"
        extraArgs:
            initial-cluster: infra0=https://192.168.0.211:2380,infra1=https://192.168.0.212:2380,infra2=https://192.168.0.213:2380
            initial-cluster-state: new
            name: infra0
            listen-peer-urls: https://192.168.0.211:2380
            listen-client-urls: https://192.168.0.211:2379
            advertise-client-urls: https://192.168.0.211:2379
            initial-advertise-peer-urls: https://192.168.0.211:2380
```