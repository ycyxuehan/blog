# scheduler

***本文档是阅读源码时的一些个人理解，未必全部正确，如有错误，请指正。***

## Scheduler

```go
type Scheduler struct {
	// It is expected that changes made via SchedulerCache will be observed
	// by NodeLister and Algorithm.
	SchedulerCache internalcache.Cache

	Algorithm core.ScheduleAlgorithm

	// NextPod should be a function that blocks until the next pod
	// is available. We don't use a channel for this, because scheduling
	// a pod may take some amount of time and we don't want pods to get
	// stale while they sit in a channel.
	NextPod func() *framework.QueuedPodInfo

	// Error is called if there is an error. It is passed the pod in
	// question, and the error
	Error func(*framework.QueuedPodInfo, error)

	// Close this to shut down the scheduler.
	StopEverything <-chan struct{}

	// SchedulingQueue holds pods to be scheduled
	SchedulingQueue internalqueue.SchedulingQueue

	// Profiles are the scheduling profiles.
	Profiles profile.Map

	client clientset.Interface
}

```

***kubernetes不仅代码写的牛逼，注释也写得牛逼***

### SchedulerCache

`SchedulerCache` 负责缓存节点信息，Pod(assumed)列表，pod状态信息，镜像状态信息。

### Algorithm

`Algorithm` 是调度算法，是一个包含Schedule和Extenders两个方法的interface，这个设计可以方便使用不同的调度算法。 从后面的代码中可以看出，这个算法是可以通过配置来使用不同的算法。

### NextPod

`NextPod` 是一个方法，返回队列中下一个需要调度的pod的信息。因为pod调度需要花费时间，所以`NextPod`会阻塞直至下一个pod可用(参见注释).

### StopEverything

`StopEverything` 是一个channel，接收停止信号，停止scheduler及相关服务。

### SchedulingQueue

`SchedulingQueue` 是一个储存需要调度的pod的队列

### Profiles

`Profiles` 是一个调度配置表，真正类型是`map[string]framework.Framework`, `framework.Framework` 管理调度框架使用的插件集，已配置的插件会在调度上下文的指定点被调用

### client

`client`是`apiserver`的client，用于与`apiserver`交互

## New()

`New()` 创建一个Scheduler对象

```go
func New(client clientset.Interface,
	informerFactory informers.SharedInformerFactory,
	recorderFactory profile.RecorderFactory,
	stopCh <-chan struct{},
	opts ...Option) (*Scheduler, error)
```

`New()` 的参数列表：
参数|类型|说明
--|--|--
`client`|`clientset.Interface`|连接apiserver的client
`informerFactory`|`informers.SharedInformerFactory`|为所有已知apigroup的资源提供共享情报(`informers`)
`recorderFactory`|`profile.RecorderFactory`|为给定的调度器名称建立一个事件记录
`stopCh`|`<-chan struct{}`|只读channel，用于停止服务([StopEverything](###StopEverything))
`opts`|`...Option`|配置选项，其实是`func(*schedulerOptions)`，这是一个`...`参数，即可以接受不限数量的这一类型参数

### 处理服务终止channel

```go
stopEverything := stopCh
if stopEverything == nil {
    stopEverything = wait.NeverStop
}
```

### 生成配置

```go
	options := defaultSchedulerOptions
	for _, opt := range opts {
		opt(&options)
	}
```

### 创建调度缓存

```go
schedulerCache := internalcache.New(30*time.Second, stopEverything)
```

这里的`internalcache.New`会启动一个goroutinel来管理假定(assumed)pod是否期满，第一个参数是期限(`30*time.Second`)，一个pod会先标记为assumed pod，然后进行实际调度，这个期限就是标记之后到实际调度的时间，第二个参数(`stopEverything`)用于终止服务。

### 合并插件

```go
	registry := frameworkplugins.NewInTreeRegistry()
	if err := registry.Merge(options.frameworkOutOfTreeRegistry); err != nil {
		return nil, err
	}
```

这里先使用树内(in-tree)插件创建注册表，运行完树插件的`scheduler`可以通过`WithFrameWorkAutoftreeRegistry`选项注册其他插件。之后调用`Merge()`注册`options`提供的插件。

***树内插件(in-tree)即内部插件，树外(out-of-tree)插件即附加插件，额外提供的插件***

### 创建快照

```go
snapshot := internalcache.NewEmptySnapshot()
```

`snapshort`是一个有序节点树列表及所有节点信息的快照，每一个调度循环都会首先创建`snapshort`并使用其作为调度依据。

### 创建配置器

```go
	configurator := &Configurator{
		client:                   client,
		recorderFactory:          recorderFactory,
		informerFactory:          informerFactory,
		schedulerCache:           schedulerCache,
		StopEverything:           stopEverything,
		percentageOfNodesToScore: options.percentageOfNodesToScore,
		podInitialBackoffSeconds: options.podInitialBackoffSeconds,
		podMaxBackoffSeconds:     options.podMaxBackoffSeconds,
		profiles:                 append([]schedulerapi.KubeSchedulerProfile(nil), options.profiles...),
		registry:                 registry,
		nodeInfoSnapshot:         snapshot,
		extenders:                options.extenders,
		frameworkCapturer:        options.frameworkCapturer,
		parallellism:             options.parallelism,
	}
```

`Configurator` 定义了 `I/O`、缓存以及其他创建调度器的必要功能。

### 注册metrics

```go
metrics.Register()
```

### 创建调度器

```go
	var sched *Scheduler
	source := options.schedulerAlgorithmSource
	switch {
	case source.Provider != nil:
		// Create the config from a named algorithm provider.
		sc, err := configurator.createFromProvider(*source.Provider)
		if err != nil {
			return nil, fmt.Errorf("couldn't create scheduler using provider %q: %v", *source.Provider, err)
		}
		sched = sc
	case source.Policy != nil:
		// Create the config from a user specified policy source.
		policy := &schedulerapi.Policy{}
		switch {
		case source.Policy.File != nil:
			if err := initPolicyFromFile(source.Policy.File.Path, policy); err != nil {
				return nil, err
			}
		case source.Policy.ConfigMap != nil:
			if err := initPolicyFromConfigMap(client, source.Policy.ConfigMap, policy); err != nil {
				return nil, err
			}
		}
		// Set extenders on the configurator now that we've decoded the policy
		// In this case, c.extenders should be nil since we're using a policy (and therefore not componentconfig,
		// which would have set extenders in the above instantiation of Configurator from CC options)
		configurator.extenders = policy.Extenders
		sc, err := configurator.createFromConfig(*policy)
		if err != nil {
			return nil, fmt.Errorf("couldn't create scheduler from policy: %v", err)
		}
		sched = sc
	default:
		return nil, fmt.Errorf("unsupported algorithm source: %v", source)
	}
	// Additional tweaks to the config produced by the configurator.
	sched.StopEverything = stopEverything
	sched.client = client
```

如果调度算法资源(`options.schedulerAlgorithmSource`)配置了调度算法提供程序名称(`source.Provider`)，则依据此算法提供程序创建调度器。

如果调度算法资源(`options.schedulerAlgorithmSource`)配置了算法配置策略(`source.Policy`),则依据此策略创建调度器。算法配置策略有两种，`File` 和 `ConfigMap`。首先根据这两个配置策略(`ConfigMap`优先)初始化配置，再依据配置创建调度器

### 为调度器添加事件处理程序

```go
addAllEventHandlers(sched, informerFactory)
```

## addAllEventHandlers()

[addAllEventHandlers](eventhandlers.md)为调度器添加事件处理程序, 对各种通知(`informers`)事件进行测试及调度。

```go
func addAllEventHandlers(
	sched *Scheduler,
	informerFactory informers.SharedInformerFactory,
)
```

该方法为调度器添加了以下事件处理程序：

资源|动作|apigroup|备注
--|--|--|--
Pods|add/update/delete|core|已调度pod缓存
Pods|add/update/delete|core|未调度pod队列
Nodes|add/update/delete|core| 
CSINodes|add/update|storage|
PersistentVolumes|add/update|core|
PersistentVolumeClaims|add/update|core|
Services|add/update/delete|core|
StorageClasses|add|storage|

详情请参考[eventhandlers](eventhandlers.md)

## Run()

开始监听及调度

```go
// Run begins watching and scheduling. It starts scheduling and blocked until the context is done.
func (sched *Scheduler) Run(ctx context.Context) {
	sched.SchedulingQueue.Run()
	wait.UntilWithContext(ctx, sched.scheduleOne, 0)
	sched.SchedulingQueue.Close()
}
```

