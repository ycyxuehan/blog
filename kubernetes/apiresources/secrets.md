# Secrets

创建一个镜像下载secrets

```bash
 kubectl create secret generic registry-bing89 --from-file=.dockerconfigjson=/root/.docker/config.json --type=kubernetes.io/dockerconfigjson
```