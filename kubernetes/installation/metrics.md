# 安装metrics server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

如果出现错误`unable to fully scrape metrics from node`, 在配置文件中添加启动参数`--kubelet-insecure-tls`

```yaml
spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --kubelet-insecure-tls #这里是新增的
        image: registry.bing89.com/kubernetes/metrics-server:v0.4.1
```