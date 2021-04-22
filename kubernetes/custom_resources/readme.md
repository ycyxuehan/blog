# 定制Kubernetes资源

[定制资源(Custom Resource)](https://kubernetes.io/zh/docs/concepts/extend-kubernetes/api-extension/custom-resources/) 是对 Kubernetes API 的扩展，可以开发定制的资源及控制器，这些资源仍旧可以通过kubernetes api来访问。

可以单独开发定制资源，也可以连定制同控制器一起开发。

## 准备

开发定制资源(CRD)需要安装controller-gen、kubebuilder、kustomize这三个工具。

***这里所有工具都默认安装到`${HOME}/go/bin/`***

### controller-gen

[controller-gen](https://github.com/kubernetes-sigs/controller-tools) 用于生成crd controller的基础代码, 省去不少工作。

安装

```bash
git clone https://github.com/kubernetes-sigs/controller-tools.git
cd controller-tools/cmd/controller-gen/
go build -o ${HOME}/go/bin/controller-gen main.go
```

使用方法

```bash
# controller-gen crd --paths=[api code path]/... output:dir=[output dir]
controller-gen crd --paths=/git/demo/api/... output:dir=/git/demo/crd
```

### kubebuilder

[kubebuilder](https://github.com/kubernetes-sigs/kubebuilder)用于生成crd基础代码。

安装

```bash
wget https://github.com/kubernetes-sigs/kubebuilder/releases/download/v3.0.0-rc.0/kubebuilder_linux_amd64 -O ${HOME}/go/bin/kubebuilder
chmod +x ${HOME}/go/bin/kubebuilder
```

#### 使用方法

kubebuilder详细使用方法参见[官方文档](https://book.kubebuilder.io/)

创建一个项目

```bash
mkdir $GOPATH/src/example
cd $GOPATH/src/example
kubebuilder init --domain project.demo.io
```

创建一个api资源

```bash
kubebuilder create api --group project.demo.io --version v1 --kind Demo
```

***这个api资源就是project.demo.io/v1/demos***

### kustomize

[kustomize](https://github.com/kubernetes-sigs/kustomize)把简明的kustomization 模板转换成kubernetes的资源配置。kustomize 可以用于crd也可以用于内置资源(参见文档[manage-kubernetes-objects](https://kubernetes.io/zh/docs/tasks/manage-kubernetes-objects/kustomization/))的管理。

安装

```bash
go get sigs.k8s.io/kustomize/kustomize/v3
```

使用方法参见[官方指南](https://kubectl.docs.kubernetes.io/zh/guides)

## 开始

安装好相关工具之后，就可以开始愉快的玩耍了。

### 初始化项目

```bash
PROJECT_DIR=demo #
API_DOMAIN=demo
GO_MODULE_DOMAIN=crd.io
OWNER=bing
mkdir ${PROJECT_DIR}
cd ${PROJECT_DIR}
kubebuilder init --plugins go/v3 --domain ${API_DOMAIN} --owner ${OWNER} --repo ${GO_MODULE_DOMAIN} --skip-go-version-check
```

- `PROJECT_DIR` 是项目目录
- `GO_MODULE_DOMAIN` 是go mod 的名称， 也是api resource group的后缀，如果使用GOPATH则不需要配置
- `API_DOMAIN` 是api resource的域名，也是group名的一部分
- `OWNER` 是项目所有人

***最终`apiVersion:${API_DOMAIN}.${GO_MODULE_DOMAIN}`***

现在，`PROJECT_DIR` 目录下文件(夹)如下

```bash
config  Dockerfile  go.mod  go.sum  hack  main.go  Makefile  PROJECT
```

- `config` 存放kustomization配置
- `Dockerfile` 生产docker镜像的配置，这个文件包含了代码编译操作
- `hack` 这个文件夹存放了一个名为`boilerplate.go.txt`的文件
- `main.go` 程序入口文件,启动一个manager，负责管理crd
- `Makefile` `make`命令的配置文件
- `PROJECT` 项目配置文件

#### main.go

main.go 是manager启动的入口文件。

##### 处理启动参数

```go
flag.StringVar(&metricsAddr, "metrics-bind-address", ":8080", "The address the metric endpoint binds to.")
flag.StringVar(&probeAddr, "health-probe-bind-address", ":8081", "The address the probe endpoint binds to.")
flag.BoolVar(&enableLeaderElection, "leader-elect", false,
        "Enable leader election for controller manager. "+
                "Enabling this will ensure there is only one active controller manager.")
opts := zap.Options{
        Development: true,
}
opts.BindFlags(flag.CommandLine)
flag.Parse()
```

##### 创建manager

创建了一个manager `mgr`

```go
mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
    Scheme:                 scheme,
    MetricsBindAddress:     metricsAddr,
    Port:                   9443,
    HealthProbeBindAddress: probeAddr,
    LeaderElection:         enableLeaderElection,
    LeaderElectionID:       "e71592d6.demo",
})
```

##### 为manager添加healthy和ready检查

```go
//+kubebuilder:scaffold:builder

if err := mgr.AddHealthzCheck("healthz", healthz.Ping); err != nil {
        setupLog.Error(err, "unable to set up health check")
        os.Exit(1)
}
if err := mgr.AddReadyzCheck("readyz", healthz.Ping); err != nil {
        setupLog.Error(err, "unable to set up ready check")
        os.Exit(1)
}
```

***注意：注释`//+kubebuilder:scaffold:builder`也是代码的一部分。所有`//+kubebuilder:开头的注释都有他的特殊意义。***

##### 启动manager

```go
if err := mgr.Start(ctrl.SetupSignalHandler()); err != nil {
        setupLog.Error(err, "problem running manager")
        os.Exit(1)
}
```

### 创建一个CRD

```bash
kubebuilder create api --group ${API_DOMAIN} --version v1 --kind Demo
```

***创建时会询问是否创建resource及controller***

现在项目目录下多了几个文件夹

```bash
api  bin  config  controllers  Dockerfile  go.mod  go.sum  hack  main.go  Makefile  PROJECT
```

- `api` api resource 的代码目录，目录下是版本子目录，resource的代码文件位于版本子目录内

- `bin` `controller-gen` 可执行文件位于此处

- `controllers` controller的代码目录

#### main.go

看一下main.go的新增部分

```go
if err = (&controllers.DemoReconciler{
    Client: mgr.GetClient(),
    Log:    ctrl.Log.WithName("controllers").WithName("Demo"),
    Scheme: mgr.GetScheme(),
}).SetupWithManager(mgr); err != nil {
    setupLog.Error(err, "unable to create controller", "controller", "Demo")
    os.Exit(1)
}
```
创建一个对应的controller对象(`DemoReconciler`), 并设置这个controller的manager为`mgr`

#### `api/v1/demo_types.go`

定义Demo资源规约`DemoSpec`, 

```go
type DemoSpec struct {
        // INSERT ADDITIONAL SPEC FIELDS - desired state of cluster
        // Important: Run "make" to regenerate code after modifying this file

        // Foo is an example field of Demo. Edit demo_types.go to remove/update
        Foo string `json:"foo,omitempty"`
}
```

定义Demo状态

```go
type DemoStatus struct {
        // INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
        // Important: Run "make" to regenerate code after modifying this file
}
```

注册资源

```go
func init() {
    SchemeBuilder.Register(&Demo{}, &DemoList{})
}
```

#### `api/v1/groupversion_info.go`

api 资源组配置。

```go
// Package v1 contains API Schema definitions for the demo.io v1 API group
//+kubebuilder:object:generate=true
//+groupName=demo.crd.io
package v1

import (
        "k8s.io/apimachinery/pkg/runtime/schema"
        "sigs.k8s.io/controller-runtime/pkg/scheme"
)

var (
        // GroupVersion is group version used to register these objects
        GroupVersion = schema.GroupVersion{Group: "demo.crd.io", Version: "v1"}

        // SchemeBuilder is used to add go types to the GroupVersionKind scheme
        SchemeBuilder = &scheme.Builder{GroupVersion: GroupVersion}

        // AddToScheme adds the types in this group-version to the given scheme.
        AddToScheme = SchemeBuilder.AddToScheme
)
```

***注意：注释`+groupName=demo.crd.io`不可删除，与`+kubebuilder:object:generate=true`一样，有他的特殊意义。后续还能看到用于设定的很多注释***

#### `api/v1/zz_generated.deepcopy.go`

这是一个自动生成的深度复制的文件，不要随意修改此文件，除非明确知道要做什么。kubebuilder会自动配置及更新该文件。

#### `controllers/demo_controller.go`

资源demo的控制器文件。

##### DemoReconciler

`DemoReconciler`对象定义。一般来说，无需为其添加任何内容，除非有特别需求

```go

// DemoReconciler reconciles a Demo object
type DemoReconciler struct {
    client.Client
    Log    logr.Logger
    Scheme *runtime.Scheme
}
```
- `DemoReconciler`对象有三个成员，`client.Client` 是kubernetes client接口，提供如Get、Update、Create、Delete等方法。

- `Log` 统一的log处理

- `Scheme` 这个功能比较多，比如序列化与反序列化对象

##### Reconcile

处理程序。每一次CRD的变更都会调用此方法。

```go

//+kubebuilder:rbac:groups=demo.demo,resources=demoes,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=demo.demo,resources=demoes/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=demo.demo,resources=demoes/finalizers,verbs=update

func (r *DemoReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
        _ = r.Log.WithValues("demo", req.NamespacedName)

        // your logic here

        return ctrl.Result{}, nil
}
```

***注意：`+kubebuilder:rbac`是用于授权的注释，只有在此授权了的资源，才能够使用对应权限访问。`kustomize`会依据此配置生成`config/rbac`配置。***

##### SetupWithManager

设置controller的manager，通常不需要修改这部分代码就可以正常工作，但有时需要进行改动，比如watch其他资源的时候。

```go
// SetupWithManager sets up the controller with the Manager.
func (r *DemoReconciler) SetupWithManager(mgr ctrl.Manager) error {
    return ctrl.NewControllerManagedBy(mgr).
        For(&demov1.Demo{}).
        Complete(r)
}
```

### 为controller添加功能

#### 添加字段

首先为crd添加两个字段。一个规约字段`Bar`和一个状态字段`UpdatedAt`

```go
type DemoSpec struct {
    Foo string `json:"foo,omitempty"`
    Bar string `json:"Bar,omitempty"`
}

// DemoStatus defines the observed state of Demo
type DemoStatus struct {
    UpdatedAt *metav1.Time `json:"UpdatedAt,omitempty"`
}

```

#### 修改Reconcile

```go
import apiv1 "demo.crd.io/api/v1"

func (r *DemoReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
        _ = r.Log.WithValues("demo", req.NamespacedName)

        // your logic here
        demo := apiv1.Demo{}
        err := r.Get(context.Background(), req.NamespacedName, &demo)
        if err != nil {
            r.Log.Error(err, "get demo resource error")
            return ctrl.Result{}, nil
        }
        //更新操作
        if demo.ObjectMeta.DeletionTimestamp.IsZero() {
            //更新
            err = r.processUpdate(&demo)
        }
        return ctrl.Result{}, nil
}

//处理更新
func (r *DemoReconciler)processUpdate(demo *apiv1.Demo)error{
    r.Log.Info("the bar of %s is %s", demo.GetName(), demo.Spec.Bar)
    now := metav1.Now()
    demo.Status.UpdatedAt = &now
    err := r.Status().Update(context.Background(), demo)
    return err
}
```

这里首先获取到触发此次reconcile的对象`demo`, 然后通过`demo.ObjectMeta.DeletionTimestamp.IsZero()`来判断是删除操作还是更新操作(创建对象也是更新操作)。对于更新操作，执行方法`processUpdate`

在`processUpdate`中，先将`demo.Spec.Bar`打印到日志:`r.Log.Info("the bar of %s is %s", demo.GetName(), demo.Spec.Bar)`， 之后更新`demo.Status.UpdatedAt`字段。

这里使用了`r.Status().Update(context.Background(), demo)`，这需要有注释`// +kubebuilder:subresource:status` 默认已经添加了该注释，如果误删除了，需要添加上。

```go
//+kubebuilder:object:root=true
//+kubebuilder:subresource:status

// Demo is the Schema for the demoes API
type Demo struct {
```

**注意这里注释的位置和空行。**
