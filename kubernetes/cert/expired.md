# kubernetes 集群证书过期处理

## 查看证书到期时间

```bash
kubeadm alpha certs check-expiration
```

## 修改时间使证书暂时有效

```bash
date -s '0000-00-00'
```

## 重新分发证书

```bash
kubeadm alpha certs renew all
```

## 重启服务，重载证书

```bash
docker ps | grep -v pause | grep -E "etcd|scheduler|controller|apiserver" | awk '{print $1}' | awk '{print "docker","restart",$1}' | bash
ntpdate pool.ntp.org
```

## 更新用户配置

```bash
cp /etc/kubernetes/admin.conf ~/.kube/config
```