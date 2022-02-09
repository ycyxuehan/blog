# Secret 的静态加密

kubernetes 集群中，secret默认是明文存储(base64编码)。可以通过开启静态加密来对secret进行加密。

## 开启静态加密

通过配置apiserver来开启静态加密功能。

### 创建静态加密配置

开启静态加密需要一个配置文件。以下是配置示例：

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
    - secrets
    providers:
    - identity: {}
    - aesgcm:
        keys:
        - name: key1
          secret: c2VjcmV0IGlzIHNlY3VyZQ==
        - name: key2
          secret: dGhpcyBpcyBwYXNzd29yZA==
    - aescbc:
        keys:
        - name: key1
          secret: c2VjcmV0IGlzIHNlY3VyZQ==
        - name: key2
          secret: dGhpcyBpcyBwYXNzd29yZA==
    - secretbox:
        keys:
        - name: key1
          secret: YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY=
```

***这个配置示例是从官方文档复制来的。这是一个包含许多类型的配置，直接使用是无法加密的(可能是因为`- identity: {}`是列表第一项)，使用时请参考后面的配置***

kubernetes 支持 `identity`、`aescbc`、`secretbox`、`aesgcm`、`kms` 这几种加密方式，其中`aescbc`为官方推荐加密类型，`aesgcm`为不推荐加密类型，`kms`需要第三方工具管理。

加密密钥获取方式

```bash
head -c 32 /dev/urandom | base64
```
此命令会获得一个随机的32位密钥

***只提供需要的加密类型的配置***

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
    - secrets
    providers:
    - aescbc:
        keys:
        - name: key1
          secret: eGy+iOygy5lN1jWWYRVtVXywe5HDc1Op9lUgR5MRaPo=
    - identity: {}
```

### 配置apiserver

编辑文件`kube-apiserver.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  ...
spec:
  containers:
  - command:
    - kube-apiserver
    ...
    - --experimental-encryption-provider-config=/etc/kubernetes/pki/encryption.yaml
```

***如果是kubeadm安装的集群，配置文件位于`/etc/kubernetes/manifests/kube-apiserver.yaml`***

**注意：这里的加密配置文件放在`/etc/kubernetes/pki/encryption.yaml`，因为这个目录是默认挂载到apiserver的pod里的，也可以放在其他目录并修改挂载选项挂载进去**

**注意：必须先写好配置文件，在修改apiserver的配置，否则apiserver可能需要多次重启**

配置文件修改完成后，apiserver的pod会自动重启。

现在，新创建的secret会自动加密了。

## 验证

创建一个secret

```bash
kubectl create secret generic secret1 -n default --from-literal=mykey=mydata
```

使用 etcdctl 命令行，从 etcd 中读取 secret：

```bash
ETCD_POD=$(kubectl -n kube-system get pod -l component=etcd  -o name)
kubectl -n kube-system exec -it ${ETCD_POD} -- etcdctl get /registry/secrets/default/secret1 --endpoints=localhost:2379 --cert=/etc/kubernetes/pki/etcd/peer.crt --key=/etc/kubernetes/pki/etcd/peer.key --cacert=/etc/kubernetes/pki/etcd/ca.crt |hexdump -C
```
***这个是从官方文档改成kubectl的命令，原命令`ETCDCTL_API=3 etcdctl get /registry/secrets/default/secret1 [你的参数] | hexdump -C`***

可以在结果中找到`1..k8s:enc:aescb`表示加密成功，这是文件的其他内容都是乱码

```text
00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
                                                                              00000010  73 2f 64 65 66 61 75 6c  74 2f 73 65 63 72 65 74  |s/default/secret|
                                                                                                                                                            00000020  31 0d 0a 6b 38 73 3a 65  6e 63 3a 61 65 73 63 62  |1..k8s:enc:aescb|
                       00000030  63 3a 76 31 3a 6b 65 79  31 3a c6 76 5c ca d4 9a  |c:v1:key1:.v\...|
                                                                                                     00000040  ee 49 87 86 98 7e d9 22  30 42 16 c7 9a 7e e1 08  |.I...~."0B...~..|
                                                                                                                                                                                   00000050  71 e1 8b 1d bc 57 44 ae  04 77 5f 8f 5c f6 29 ee  |q....WD..w_.\.).|
                                              00000060  8f 3c ed 2b cc 8a cb d2  25 fd b2 ba 3a c3 c5 5e  |.<.+....%...:..^|
                                                                                                                            00000070  70 99 03 6e 0d 0a e9 c4  90 a4 cb e3 09 92 ec de  |p..n............|
                                                                                                                                                                                                          00000080  2f 20 eb 35 b7 be 93 f0  09 a1 84 48 8c 3a ed 43  |/ .5.......H.:.C|
                                                                     00000090  47 b6 cf 96 cc 25 7e 54  f3 c2 93 34 cc 0c 25 6d  |G....%~T...4..%m|
                                                                                                                                                   000000a0  d9 df ca f3 ed a1 d8 8e  55 1b 26 58 d9 3f f2 fc  |........U.&X.?..|
              000000b0  58 ed a1 0f 4d 4b e9 11  bf ba e0 52 4f 74 8e 5b  |X...MK.....ROt.[|
                                                                                            000000c0  47 c3 68 db f9 6c e9 b5  f5 3c 1c 64 a4 49 9b 68  |G.h..l...<.d.I.h|
                                                                                                                                                                          000000d0  18 30 de d9 1c 36 fb 43  e2 d7 0f 18 84 09 2d 46  |.0...6.C......-F|
                                     000000e0  b1 97 31 87 0f eb 68 83  2c 4f 0b 42 1c 01 d0 ca  |..1...h.,O.B....|
                                                                                                                   000000f0  e2 88 b9 0c 97 cf 77 8d  d1 73 83 ed 1d c2 19 57  |......w..s.....W|
                                                                                                                                                                                                 00000100  2f f0 cd 5e 39 19 d6 67  fd 73 88 ab 09 bf 90 09  |/..^9..g.s......|
                                                            00000110  78 69 1e 60 22 60 97 b9  83 c4 38 0c ea e2 02 9a  |xi.`"`....8.....|
                                                                                                                                          00000120  16 ac 6e ca 3e c1 28 77  21 32 4a 7a 5a a0 11 4f  |..n.>.(w!2JzZ..O|
     00000130  d4 1f 2b a8 6b 85 43 47  fb 43 ea 0d 0a           |..+.k.CG.C...|
0000013d
```

通过api查看

```bash
kubectl describe secret secret1 -n default
```