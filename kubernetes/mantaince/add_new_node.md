# kubeadm添加一个新的节点

首先获取证书的hash值， 这个值用于 `--discovery-token-ca-cert-hash`

```bash
HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
```

获取token, 这个值用于 `--token`

```bash
kubeadm token list
```

如果没有任何token列出，创建一个

```bash
TOKEN=$(kubeadm token create)
```

添加节点到集群

```bash
kubeadm join k8smaster:6443 --token ${TOKEN} --discovery-token-ca-cert-hash sha256:${HASH}
```
