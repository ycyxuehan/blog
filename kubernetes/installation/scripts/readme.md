# install.sh 使用帮助

```bash
install.sh [command] -c [controlplane_hosts] -e [etcd_hosts] -n [network_name] -a [apiserver_host] [-p [haproxy_hosts]] [-h]
```
## command

现在脚本支持以下命令

- etcd 初始化etcd集群 必须使用-e指定etcd集群的节点列表
- controlplane 初始化controlplane 必须使用-e指定etcd集群的节点列表，-c 指定controlplane节点列表，-a 指定apiserver的IP地址或域名
- network 安装网络，必须使用-n指定要安装的网络名称，***该功能暂未开发完成***
- haproxy 初始化haproxy， 必须-c 指定controlplane节点列表， -p 指定haproxy节点列表，***暂时配置为haproxy与controlplane位于同一节点，所以两个列表需要一一对应。***

## args

节点列表使用`,`分隔，例如`192.168.1.2,192.168.1.3`或`node1,node2`