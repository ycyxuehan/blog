# haproxy安装与配置

安装之前，请确认已经按要求准备好正确数量的节点并已经根据[配置运行环境](config_run_env.md)完成了环境配置。

**若无特别说明，本文档所述操作，均在第一个controlplane节点上执行。**

## 安装软件

```bash
export HA_HOSTS=(192.168.0.201 192.168.0.202 192.168.0.203)
export VIP=192.168.0.200
export HAPASSWORD="hapassword2020"
export HOST_PREFIX="k8smaster"
for HOST in ${HA_HOSTS[@]}
do
ssh ${HOST}  "yum install corosync pacemaker pcs fence-agents resource-agents -y && systemctl enable --now pcsd"
done
```

## 创建VIP

```bash
for HOST in ${HA_HOSTS[@]}
do
    ssh ${HOST}  "echo ${HAPASSWORD} | passwd --stdin hacluster && pcs cluster auth -u hacluster -p ${HAPASSWORD} ${HA_HOSTS}"
    ssh ${HOST}  "pcs cluster setup --start --name k8s_cluster ${HA_HOSTS}"
    ssh ${HOST}  "pcs cluster enable --all && pcs cluster start  --all && pcs cluster status && pcs status corosync"
    ssh ${HOST}  "pcs property set stonith-enabled=false && pcs property set no-quorum-policy=ignore && crm_verify -L -V"
done
ssh ${HA_HOSTS[0]}  "pcs resource create vip ocf:heartbeat:IPaddr2 ip=${VIP} cidr_netmask=28 op monitor interval=28s"
```

## 创建haproxy配置

```bash
#haproxy 配置
cat <<EOF >/tmp/haproxy.cfg
# /etc/haproxy/haproxy.cfg
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 1
    timeout http-request    10s
    timeout queue           20s
    timeout connect         5s
    timeout client          20s
    timeout server          20s
    timeout http-keep-alive 10s
    timeout check           10s

#---------------------------------------------------------------------
# apiserver frontend which proxys to the masters
#---------------------------------------------------------------------
frontend apiserver
    bind *:8443
    mode tcp
    option tcplog
    default_backend apiserver

#---------------------------------------------------------------------
# round robin balancing for apiserver
#---------------------------------------------------------------------
backend apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
EOF
INDEX=0
for HOST in ${HA_HOSTS[@]}
do
    echo "        server ${HOST} ${HOST_PREFIX}${INDEX}:6443 weight 1 maxconn 1000 check inter 2000 rise 2 fall 3\n" >> /tmp/haproxy.cfg
    INDEX=$(expr ${INDEX} + 1)
done
#haproxy pod配置
cat <<EOF >/tmp/haproxy.yaml
apiVersion: v1
kind: Pod
metadata:
  name: haproxy
  namespace: kube-system
spec:
  containers:
  - image: registry.bing89.com/dockerhub/haproxy:lts-alpine
    name: haproxy
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: localhost
        path: /healthz
        port: 8443
        scheme: HTTPS
    volumeMounts:
    - mountPath: /usr/local/etc/haproxy/haproxy.cfg
      name: haproxyconf
      readOnly: true
  hostNetwork: true
  volumes:
  - hostPath:
      path: /etc/haproxy/haproxy.cfg
      type: FileOrCreate
    name: haproxyconf
EOF
```

## 配置并启动haproxy

```bash
    for HOST in ${HA_HOSTS[@]}
    do
        ssh ${HOST} "if [ ! -d /etc/haproxy ];then mkdir /etc/haproxy; fi"
        scp /tmp/haproxy.cfg ${HOST}:/etc/haproxy/haproxy.cfg
        scp /tmp/haproxy.yaml  ${HOST}:/etc/kubernetes/manifests/haproxy.yaml
        ssh ${HOST} "systemctl restart kubelet"
    done
```