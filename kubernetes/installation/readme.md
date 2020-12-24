# 安装kubernetes集群

本文档使用centos7.2009作为基础操作系统，使用kubeadm为安装工具。可以使用本文档逐步操作安装kubernetes集群，也可使用自动化安装脚本[autoinstall.sh](autoinstall.md)来快速安装。

安装不同配置的集群需要不同的节点数，每节点CPU核心不低于2，内存不少于2GB，至多需要9个节点。

本文档使用192.168.0.0/24 为节点网络。

## 环境配置

使用[配置运行环境](config_run_env.md)文档来配置运行环境，建议所有节点使用完全一致的配置。

## 创建kubeadm配置

参照[kubeadm配置示例](kubeadm_config_example.md)创建正确的集群配置。

## 初始化集群

### 初始化单controlplane节点集群

```bash
kubeadm init --config /etc/kubernetes/kubeadmcfg.yaml
```
如果只为集群准备了一个节点，需要取消节点的污点标记，用于调度pod。

```bash
kubectl taint nodes --all node-role.kubernetes.io/master-
```

### 初始化基于堆叠etcd的集群

参照[使用kubeadm安装基于堆叠etcd的kubernetes](install_cluster_with_stacked_etcd.md)

### 初始化基于外部etcd集群的集群

参照[使用kubeadm安装基于外部etcd集群的kubernetes](install_cluster_with_outside_etcd.md)

## 安装网络

### 安装calico

```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```