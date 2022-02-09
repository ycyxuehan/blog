#!/bin/bash

##
HAPASSWORD="4orLcyKqDFWrmGlQ"

init_etcd(){
    echo "init etcd cluster: $@"
    echo "create config files..."
    kubeadm reset -f
    if [ ! -d /tmp/kubelet.service.d ];then
        mkdir /tmp/kubelet.service.d
    fi
    cat << EOF > /tmp/kubelet.service.d/20-etcd-service-manager.conf
[Service]
ExecStart=
#  Replace "systemd" with the cgroup driver of your container runtime. The default value in the kubelet is "cgroupfs".
ExecStart=/usr/bin/kubelet --container-runtime=remote --container-runtime-endpoint=unix:///run/containerd/containerd.sock  --address=127.0.0.1 --pod-manifest-path=/etc/kubernetes/manifests --pod-infra-container-image=registry.bing89.com/kubernetes/pause:3.2
Restart=always
EOF
    if [[ -f etc/kubernetes/pki/etcd/ca.crt ]] && [[ -f etc/kubernetes/pki/etcd/ca.key ]];then
        echo 'using exists key.'
    else
        if [[ -f etc/kubernetes/pki/etcd/ca.crt ]] || [[ -f etc/kubernetes/pki/etcd/ca.key ]]; then
            echo 'ssl key config error, maybe there one key is exists. exit '
            exit 2
        fi
        echo 'init kubernetes ssh keys'
        kubeadm init phase certs etcd-ca
    fi
    NAME_PREFIX="infra"
    INDEX=0
    INIT_CLUSTERS=""
    for ETCD_HOST in $@; do
        if [ "x${INIT_CLUSTERS}" == "x" ]; then
            INIT_CLUSTERS="${NAME_PREFIX}${INDEX}=https://${ETCD_HOST}:2380"
        else
            INIT_CLUSTERS="${INIT_CLUSTERS},${NAME_PREFIX}${INDEX}=https://${ETCD_HOST}:2380"
        fi
        INDEX=$(expr ${INDEX} + 1)
    done
    echo "init_clusters: ${INIT_CLUSTERS}"
    INDEX=0
    for HOST in ${@};
    do
        if [ ! -d /tmp/${HOST} ];then
            mkdir /tmp/${HOST}
        else
            rm -rf /tmp/${HOST}/*
        fi
        cat <<EOF >/tmp/${HOST}/etcdcfg.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
---
apiVersion: "kubeadm.k8s.io/v1beta2"
kind: ClusterConfiguration
imageRepository: registry.bing89.com/kubernetes
etcd:
    local:
        serverCertSANs:
        - "${HOST}"
        peerCertSANs:
        - "${HOST}"
        extraArgs:
            initial-cluster: ${INIT_CLUSTERS}
            initial-cluster-state: new
            name: ${NAME_PREFIX}${INDEX}
            listen-peer-urls: https://${HOST}:2380
            listen-client-urls: https://${HOST}:2379
            advertise-client-urls: https://${HOST}:2379
            initial-advertise-peer-urls: https://${HOST}:2380
EOF
        
        kubeadm init phase certs etcd-server --config=/tmp/${HOST}/etcdcfg.yaml
        kubeadm init phase certs etcd-peer --config=/tmp/${HOST}/etcdcfg.yaml
        kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST}/etcdcfg.yaml
        kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST}/etcdcfg.yaml
        cp -R /etc/kubernetes/pki /tmp/${HOST}/
        # 清理不可重复使用的证书
        find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete
        # 清理不应从此主机复制的证书
        if [ "x${INDEX}" != "x0" ];then
            find /tmp/${HOST} -name ca.key -type f -delete
        fi
        INDEX=$(expr ${INDEX} + 1)
    done
    echo "configure etcd hosts"
    for HOST in ${@};
    do
        scp -r /tmp/kubelet.service.d ${HOST}:/etc/systemd/system/
        scp -r /tmp/${HOST}/* ${HOST}:/tmp
        ssh ${HOST} "systemctl daemon-reload"
        ssh ${HOST} "kubeadm reset -f && rsync -ivhPr /tmp/pki /etc/kubernetes/"
        ssh ${HOST} "systemctl restart kubelet && kubeadm init phase etcd local --config=/tmp/etcdcfg.yaml"
    done
    echo "cluster init finished. use this command to check cluster status"
    echo "docker run --rm -it --net host -v /etc/kubernetes:/etc/kubernetes registry.bing89.com/kubernetes/etcd:3.4.13-0 etcdctl --cert /etc/kubernetes/pki/etcd/peer.crt --key /etc/kubernetes/pki/etcd/peer.key --cacert /etc/kubernetes/pki/etcd/ca.crt --endpoints https://${HOST}:2379 endpoint health --cluster"
}

init_controller(){
    echo "init controller: $@"
    echo "warning: your kubelet will reset"
    echo "backup ha pod if exists"
    if [ -f /etc/kubernetes/manifests/haproxy.yaml ];then
        cp /etc/kubernetes/manifests/haproxy.yaml /tmp/haproxy.yaml.backup
    fi


    echo "creating kubeadm config file"
    ENDPOINTS="["
    for ETCD_HOST in ${ETCD_HOSTS[@]}; do
        if [ "x${ENDPOINTS}" == "x[" ];then
            ENDPOINTS="${ENDPOINTS}\"https://${ETCD_HOST}:2379\""
        else
            ENDPOINTS="${ENDPOINTS},\"https://${ETCD_HOST}:2379\""
        fi
    done
    ENDPOINTS="${ENDPOINTS}]"
    echo "etcd end points: ${ENDPOINTS}"
    APISERVERSANS="["
    for CONTROLLER_HOST in ${CONTROLLER_HOSTS[@]}
    do
        if [ "x${APISERVERSANS}" == "x[" ];then
            APISERVERSANS="${APISERVERSANS}\"${CONTROLLER_HOST}\""
        else
            APISERVERSANS="${APISERVERSANS},\"${CONTROLLER_HOST}\""
        fi
    done
    APISERVERSANS="${APISERVERSANS}]"
    cat <<EOF >/tmp/kubeadmcfg.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: "${APIHOST}:8443"
imageRepository: registry.bing89.com/kubernetes
etcd:
    external:
        endpoints: ${ENDPOINTS}
        caFile: /etc/kubernetes/pki/etcd/ca.crt
        certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
        keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key
apiServer:
  certSANs: ${APISERVERSANS}
EOF

    kubeadm reset -f
    echo "restore ha pod if exists"
    if [ -f /tmp/haproxy.yaml.backup ];then
        cp /tmp/haproxy.yaml.backup /etc/kubernetes/manifests/haproxy.yaml
        systemctl restart kubelet
    fi
    mkdir /etc/kubernetes/pki/etcd/
    scp /tmp/$1/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/ca.crt
    scp /tmp/$1/pki/apiserver-etcd-client.crt /etc/kubernetes/pki/apiserver-etcd-client.crt
    scp /tmp/$1/pki/apiserver-etcd-client.key /etc/kubernetes/pki/apiserver-etcd-client.key
    kubeadm init --config /tmp/kubeadmcfg.yaml --upload-certs
}

init_haproxy(){
    echo 'init haproxy'
    echo 'install pcs'
    for HOST in ${HA_HOSTS[@]}
    do
        ssh ${HOST}  "yum install corosync pacemaker pcs fence-agents resource-agents -y && systemctl enable --now pcsd"
    done
    echo 'config pcs'
    for HOST in ${HA_HOSTS[@]}
    do
        ssh ${HOST}  "echo ${HAPASSWORD} | passwd --stdin hacluster && pcs cluster auth -u hacluster -p ${HAPASSWORD} ${HA_HOSTS}"
        ssh ${HOST}  "pcs cluster setup --start --name k8s_cluster ${HA_HOSTS}"
        ssh ${HOST}  "pcs cluster enable --all && pcs cluster start  --all && pcs cluster status && pcs status corosync"
        ssh ${HOST}  "pcs property set stonith-enabled=false && pcs property set no-quorum-policy=ignore && crm_verify -L -V"
    done
    ssh ${HA_HOSTS[0]}  "pcs resource create vip ocf:heartbeat:IPaddr2 ip=${APIHOSTS} cidr_netmask=28 op monitor interval=28s"

    echo 'write haproxy config...'
    APISERVERS=""
    INDEX=1
    PREFIX="k8smaster"

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
    echo "        server ${HOST} ${CONTROLLER_HOSTS[${INDEX}]}:6443 weight 1 maxconn 1000 check inter 2000 rise 2 fall 3\n" >> /tmp/haproxy.cfg
    INDEX=$(expr ${INDEX} + 1)
done
echo "write haproxy pod yaml"
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
status: {}
EOF
    for HOST in ${CONTROLLER_HOSTS[@]}
    do
        ssh ${HOST} "if [ ! -d /etc/haproxy ];then mkdir /etc/haproxy; fi"
        scp /tmp/haproxy.cfg ${HOST}:/etc/haproxy/haproxy.cfg
        scp /tmp/haproxy.yaml  ${HOST}:/etc/kubernetes/manifests/haproxy.yaml
    done
    echo 'init haproxy finished'
}

init_kube_vip(){
    echo "init kube_vip..."
    echo "exit"
    exit 0
    for HOST in ${CONTROLLER_HOSTS[@]}
    do
        if [ ! -d /tmp/${HOST}/kube-vip ]; then
            mkdir -p /tmp/${HOST}/kube-vip
        fi
    done
}

init_network(){
    echo "init cni: $@"

}

USAGE_EXITS(){
    echo "this is help message."
    exit 1
}

check_args(){
    if [ "x${ETCD_HOSTS}" == "x" ];then
        USAGE_EXITS
    fi
     if [ "x${CONTROLLER_HOSTS}" == "x" ];then
         USAGE_EXITS
     fi
    if [ "x${APIHOST}" == "x" ];then
        USAGE_EXITS
    fi
}
main(){
    COMMAND=$1
    shift
    while getopts "c:e:n:a:p:h" arg
    do
        case ${arg} in 
            e)
                ETCD_HOSTS=(${OPTARG//,/ })
                ;;
            c)
                CONTROLLER_HOSTS=(${OPTARG//,/ })
                ;;
            n)
                NETWORK_CNI=${OPTARG}
                ;;
            a)
                APIHOST=${OPTARG}
                ;;
            p)
                HA_HOSTS=(${OPTARG//,/ })
                ;;
            h)
                USAGE_EXITS
                ;;
        esac
    done
    check_args
    case ${COMMAND} in
    etcd)
        # echo ${ETCD_HOSTS[0]}
        init_etcd ${ETCD_HOSTS[@]}
        ;;
    controllplane)
        init_controller ${ETCD_HOSTS}
        ;;
    network)
        init_network ${NETWORK_CNI}
        ;;
    haproxy)
        init_haproxy
        ;;
    kubevip)
        init_kube_vip
        ;;
    help)
        USAGE_EXITS
        ;;
    *)
        USAGE_EXITS
        ;;
    esac
}

main $@
