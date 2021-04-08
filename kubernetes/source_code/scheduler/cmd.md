# Scheduler cmd

***本文档是阅读源码时的一些个人理解，未必全部正确，如有错误，请指正。***

scheduler 使用[cobra](../../../go/commandline/cobra/readme.md)来处理参数。

## main()

```go
rand.Seed(time.Now().UnixNano())
pflag.CommandLine.SetNormalizeFunc(cliflag.WordSepNormalizeFunc)
command := app.NewSchedulerCommand()
logs.InitLogs()
defer logs.FlushLogs()
if err := command.Execute(); err != nil {
    os.Exit(1)
}
```

- `pflag.CommandLine.SetNormalizeFunc(cliflag.WordSepNormalizeFunc)` 将参数中的`_`替换成`-`
- `command := app.NewSchedulerCommand()` 创建了一个[`cobra.Command`](../../../go/commandline/cobra/readme.md)对象
- 初始化日志
- 执行`command`， 即处理参数，执行`command`的回调方法`Run`

## NewSchedulerCommand()

`NewSchedulerCommand`接受一个`Option`类型的参数列表(...参数)，但在`main()`中未传入参数。

`NewSchedulerCommand` 返回了一个`cobra.Command`对象的引用。这个对象回调执行`runCommnad`方法

***`NewSchedulerCommand`对`cobra.Command`进行了一些自定义配置，如`usage`, `help`信息***

创建一个Options并将flags绑定到options

```go
opts, err := options.NewOptions()
//...
fs := cmd.Flags()
namedFlagSets := opts.Flags()
verflag.AddFlags(namedFlagSets.FlagSet("global"))
globalflag.AddGlobalFlags(namedFlagSets.FlagSet("global"), cmd.Name())
for _, f := range namedFlagSets.FlagSets {
    fs.AddFlagSet(f)
}
```

### Run回调

调用了方法runCommand，并传递`cmd`, `opts`, `registryOptions...` 三个参数。这里的opts是已经处理过的

```go
Run: func(cmd *cobra.Command, args []string) {
    if err := runCommand(cmd, opts, registryOptions...); err != nil {
        fmt.Fprintf(os.Stderr, "%v\n", err)
        os.Exit(1)
    }
},
```

### Option类型

```go
type Option func(runtime.Registry) error
```
Option用于配置`framework.Registry`

## runCommand()

```go
func runCommand(cmd *cobra.Command, opts *options.Options, registryOptions ...Option) error {
	verflag.PrintAndExitIfRequested()
	cliflag.PrintFlags(cmd.Flags())

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	cc, sched, err := Setup(ctx, opts, registryOptions...)
	if err != nil {
		return err
	}

	return Run(ctx, cc, sched)
}
```

runCommand 运行接受`*options.Options` 参数，并依据此options调用Setup方法创建scheduler，之后调用`Run`方法运行scheduler

## Setup()

`Setup` 主要是处理参数，创建`Scheduler`对象

## Run()

`Run` 运行`Setup`创建的`Scheduler`对象

### 设置组件配置

```go
	// Configz registration.
	if cz, err := configz.New("componentconfig"); err == nil {
		cz.Set(cc.ComponentConfig)
	} else {
		return fmt.Errorf("unable to register configz: %s", err)
	}

```

### 准备事件广播

```go
	// Prepare the event broadcaster.
	cc.EventBroadcaster.StartRecordingToSink(ctx.Done())

```

### 设置安全检查

```
	// Setup healthz checks.
	var checks []healthz.HealthChecker
	if cc.ComponentConfig.LeaderElection.LeaderElect {
		checks = append(checks, cc.LeaderElection.WatchDog)
	}
```

### 设置leader

***用于leader选举，暂时还不明白这个主要作用***

```go
	waitingForLeader := make(chan struct{})
	isLeader := func() bool {
		select {
		case _, ok := <-waitingForLeader:
			// if channel is closed, we are leading
			return !ok
		default:
			// channel is open, we are waiting for a leader
			return false
		}
	}
```

### 初始化并启动健康检查接口服务

这是一个insecure接口，会与sig-auth不兼容，已经被弃用。

```go
	// Start up the healthz server.
	if cc.InsecureServing != nil {
		separateMetrics := cc.InsecureMetricsServing != nil
		handler := buildHandlerChain(newHealthzHandler(&cc.ComponentConfig, cc.InformerFactory, isLeader, separateMetrics, checks...), nil, nil)
		if err := cc.InsecureServing.Serve(handler, 0, ctx.Done()); err != nil {
			return fmt.Errorf("failed to start healthz server: %v", err)
		}
	}

```
`newHealthzHandler` 依据给定参数返回一个http.Handler对象

`buildHandlerChain` 类似于中间件，为http.Handler添加一些filter

`InsecureServing` 是 `DeprecatedInsecureServingInfo` 类型的对象，官方注释如下：

```go
// DeprecatedInsecureServingInfo is the main context object for the insecure http server.
// HTTP does NOT include authentication or authorization.
// You shouldn't be using this.  It makes sig-auth sad.
```

### 初始化并启动metrics接口服务

这是一个insecure接口，会与sig-auth不兼容，已经被弃用。

```go
	if cc.InsecureMetricsServing != nil {
		handler := buildHandlerChain(newMetricsHandler(&cc.ComponentConfig, cc.InformerFactory, isLeader), nil, nil)
		if err := cc.InsecureMetricsServing.Serve(handler, 0, ctx.Done()); err != nil {
			return fmt.Errorf("failed to start metrics server: %v", err)
		}
	}

```
`newMetricsHandler` 依据给定参数返回一个http.Handler对象

`buildHandlerChain` 类似于中间件，为http.Handler添加一些filter

`InsecureMetricsServing` 是 `DeprecatedInsecureServingInfo` 类型的对象，官方注释如下：

```go
// DeprecatedInsecureServingInfo is the main context object for the insecure http server.
// HTTP does NOT include authentication or authorization.
// You shouldn't be using this.  It makes sig-auth sad.
```

## 初始化并启动安全的健康检查服务

```go
	if cc.SecureServing != nil {
		handler := buildHandlerChain(newHealthzHandler(&cc.ComponentConfig, cc.InformerFactory, isLeader, false, checks...), cc.Authentication.Authenticator, cc.Authorization.Authorizer)
		// TODO: handle stoppedCh returned by c.SecureServing.Serve
		if _, err := cc.SecureServing.Serve(handler, 0, ctx.Done()); err != nil {
			// fail early for secure handlers, removing the old error loop from above
			return fmt.Errorf("failed to start secure server: %v", err)
		}
	}
```

## 启动缓存工厂并等待同步完成

```go
	// Start all informers.
	cc.InformerFactory.Start(ctx.Done())

	// Wait for all caches to sync before scheduling.
	cc.InformerFactory.WaitForCacheSync(ctx.Done())

```

## 启动Scheduler

```go
	// If leader election is enabled, runCommand via LeaderElector until done and exit.
	if cc.LeaderElection != nil {
		cc.LeaderElection.Callbacks = leaderelection.LeaderCallbacks{
			OnStartedLeading: func(ctx context.Context) {
				close(waitingForLeader)
				sched.Run(ctx)
			},
			OnStoppedLeading: func() {
				klog.Fatalf("leaderelection lost")
			},
		}
		leaderElector, err := leaderelection.NewLeaderElector(*cc.LeaderElection)
		if err != nil {
			return fmt.Errorf("couldn't create leader elector: %v", err)
		}

		leaderElector.Run(ctx)

		return fmt.Errorf("lost lease")
	}

	// Leader election is disabled, so runCommand inline until done.
	close(waitingForLeader)
	sched.Run(ctx)
	return fmt.Errorf("finished without leader elect")
}

```

到这里，scheduler启动就完成了。