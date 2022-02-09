# 为节点添加扩展资源

## 启用apiserver代理

启用apiserver代理，以便发送请求

```bash
kubectl proxy
```

## 添加扩展资源

```bash
export NODE=k8snode1
curl --header "Content-Type: application/json-patch+json" \
  --request PATCH \
  --data '[{"op": "add", "path": "/status/capacity/bing89.com~1demo", "value": "4"}]' \
  http://localhost:8001/api/v1/nodes/${NODE}/status
```

输出显示该节点的当前资源容量

```json
"capacity": {
    "bing89.com/demo": "4",
    "cpu": "2",
    "ephemeral-storage": "17394Mi",
    "hugepages-2Mi": "0",
    "memory": "4045168Ki",
    "pods": "110"
}
```

显示节点信息

```bash
kubectl describe node ${NODE}
```

输出

```bash
Capacity:
  bing89.com/demo:    4
  cpu:                2
  ephemeral-storage:  17394Mi
  hugepages-2Mi:      0
  memory:             4045168Ki
  pods:               110
```

## 测试

创建一个申请demo资源的[pod](../apiresources/yaml/pod/demo-extend-resouce.yaml)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo-extend-resource
spec:
  containers:
  - name: demo-extend-resource
    image: registry.bing89.com/tools/demo:1.0
    ports:
    - containerPort: 8080
      name: http-port
    resources:
      requests:
        cpu: 50m
        bing89.com/demo: 1
      limits:
        cpu: 100m
        bing89.com/demo: 1
  restartPolicy: OnFailure
```

```bash
kubectl -n mem-demo apply -f kubernetes/apiresources/yaml/pod/demo-extend-resouce.yaml
```

查看pod

```bash
kubectl -n mem-demo get pod -o wide
```

现在，pod已经被分配到有资源的`${NODE}(k8snode1)`

```bash
NAME                   READY   STATUS    RESTARTS   AGE    IP              NODE       NOMINATED NODE   READINESS GATES
demo                   1/1     Running   0          2d1h   172.16.98.195   k8snode3   <none>           <none>
demo-extend-resource   1/1     Running   0          25s    172.16.249.5    k8snode1   <none>           <none>
```

## 清理扩展资源

```bash
curl --header "Content-Type: application/json-patch+json" \
--request PATCH \
--data '[{"op": "remove", "path": "/status/capacity/bing89.com~1demo"}]' \
http://localhost:8001/api/v1/nodes/${NODE}/status
```

验证是否已经被移除

```bash
kubectl describe node ${NODE} | grep demo
```