# 安装Prometheus监控

使用项目 ：[kube-prometheus](https://github.com/prometheus-operator/kube-prometheus.git)

选择版本可用的release版本。

执行命令

```bash
kubectl create -f manifests/setup
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
kubectl create -f manifests/
```
