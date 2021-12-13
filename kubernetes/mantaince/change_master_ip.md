# 修改主节点IP地址

***本文只在单master节点上测试通过***

首先修改etcd和api-server的地址

```bash
OLD_IP=""
NEW_IP=""
sed -e "s/${OLD_IP}/${NEW_IP}/g" -i /etc/kubernetes/manifests/etcd.yaml
sed -e "s/${OLD_IP}/${NEW_IP}/g" -i /etc/kubernetes/manifests/kube-apiserver.yaml
```

生成新的conf

```bash
kubeadm init phase kubeconfig admin --apiserver-advertise-address ${NEW_IP}
```

生成新的证书

```bash
mv /etc/kubernetes/pki/apiserver.key /etc/kubernetes/pki/apiserver.key.bak
mv /etc/kubernetes/pki/apiserver.crt /etc/kubernetes/pki/apiserver.crt.bak
kubeadm init phase certs apiserver  --apiserver-advertise-address 192.168.0.31
```

重启服务

***由于docker已被kubernetes抛弃，这里使用的containerd，使用docker的旧版kubernetes要重启docker***

```bash
systemctl restart containerd kubelet
```

更新kubectl的管理conf

```bash
rm -f ~/.kube/config
cp /etc/kubernetes/admin.conf ~/.kube/config
```