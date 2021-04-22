# 创建Docker镜像下载secret

创建一个镜像下载secret

```bash
 kubectl create secret generic registry-bing89 --from-file=.dockerconfigjson=/root/.docker/config.json --type=kubernetes.io/dockerconfigjson
```
或者

```bash
kubectl create secret docker-registry myregistrykey --docker-server=registry.bing89.com --docker-username=admin --docker-password=abcd1234 --docker-email=kun1.huang@outlook.com
```