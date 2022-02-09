# nfs 使用问题

## `unexpected error getting claim reference: selfLink was empty, can't make reference` 导致pvc无法绑定挂载

编辑文件 `/etc/kubernetes/manifests/kube-apiserver.yaml` 添加内容 `--feature-gates=RemoveSelfLink=false`

```yaml
- command:
....
- --feature-gates=RemoveSelfLink=false
image: registry.aliyuncs.com/k8sxio/kube-apiserver:v1.21.2
```

参见 [isuse](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/issues/25)

