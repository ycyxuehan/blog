# 限制pod访问

## 前期准备

创建一个pod

```bash
kubectl create deployment nginx --image=nginx
```

暴露端口

```
kubectl expose deployment nginx --port=80
```

测试访问

```
kubectl run busybox --rm -i --image=busybox /bin/sh
wget --spider --timeout=1 nginx
```

## 配置策略

nginx-policy.yaml

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: access-nginx
spec:
  podSelector:
    matchLabels:
      app: nginx
  ingress:
  - from:
    - podSelector:
        matchLabels:
          access: "true"
```

应用策略

```
kubectl apply -f nginx-policy.yaml
```

***使用之前的测试方法，已经无法访问。***

测试访问

```bash
kubectl run busybox --rm -ti --labels="access=true" --image=busybox -- /bin/sh
```