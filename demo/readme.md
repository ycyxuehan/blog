# demo

这是一个由go语言编写的基本http服务，用于各种测试。

## 编译

```bash
CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main main.go
```

## 打包

```bash
docker build -t demo:1.0 .
```

