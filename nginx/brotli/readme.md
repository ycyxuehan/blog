# nginx开启br压缩

参考项目[brotli](https://github.com/google/ngx_brotli)

**br压缩只能在https中开启。**

## 编译模块

下载nginx源码用于编译模块, 不需要编译nginx，源码需要与运行的nginx版本对应。

```bash
wget http://nginx.org/download/nginx-1.21.6.tar.gz
tar xf nginx-1.21.6.tar.gz
```
下载项目源码

```bash
git clone https://github.com/google/ngx_brotli.git
```

安装依赖包

```bash
yum install brotli brotli-devel pcre2-devel
```

配置并编译

```
cd nginx-1.21.6
./configure --with-compat --add-dynamic-module=/home/kun1h/git/ngx_brotli/
make modules
```

编译好的模块在objs目录。

## 运行并加载模块

使用docker运行nginx

```bash
sudo docker run --name nginx -p 80:80 -v /data/nginx/modules:/usr/lib/nginx/modules/extend -v /data/nginx/conf.d:/etc/nginx/conf.d -v /data/nginx/html:/var/www/html -v /data/nginx/logs:/var/log/nginx -v /data/nginx/nginx.conf:/etc/nginx/nginx.conf -d nginx:1.21
```

配置nginx.conf。添加以下内容到nginx.conf的顶部

```bash
#for modules
load_module modules/extend/ngx_http_brotli_filter_module.so;
load_module modules/extend/ngx_http_brotli_static_module.so;

```

配置必须位于 `event {}` 与 `http {}`之前