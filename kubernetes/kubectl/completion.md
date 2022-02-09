# kubectl 命令自动填充配置

安装依赖

```bash
yum install -y bash-completion
```

生成自动完成配置

```bash
kubectl completion bash >.kubectl
```

添加配置到profile

```bash
cat <<EOF >>~/.bashrc
if [ -f ~/.kubectl ];then
    . ~/.kubectl
fi
EOF
```