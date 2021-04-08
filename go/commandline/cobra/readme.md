# cobra

[cobra](http://github.com/spf13/cobra) 是一个强大开源的go命令行包，很多开源项目都使用cobra实现启动入口，如kubernetes。

# 安装

```bash
go get github.com/spf13/cobra
```

# 使用

使用cobra需要先创建一个`Command`对象，然后执行这个对象的`Execute`方法

```go
cmd := cobra.Command{Use: "cobra"}
cmd.Execute()
```

上面的代码没有任何功能,任何参数都不进行处理。

现在来扩展一下

```go
cmd := cobra.Command{
    Use: "cobra",
    Short: "this is a cobra demo",
    Run: func(cmd *cobra.Command, args []string){
        fmt.Println("good! you run a cobra command!")
    },
}
cmd.Execute()
```

这里为cmd赋值了两个属性`Short` 和`Run`。 `Short` 就是帮助信息的简短说明，`Run` 就是命令行命中时执行的方法。 由于现在只有一个根命令，所以执行的话会打印`good! you run a cobra command!` 添加任何命参数(`-`开头)将会显示错误及usage信息。

下面为cmd添加一个子命令，并处理参数`-n`

```go
cmd := cobra.Command{
    Use: "cobra",
    Short: "this is a cobra demo",
    Run: func(cmd *cobra.Command, args []string){
        fmt.Println("good! you run a cobra command!")
    },
}
var newLine *bool
subCmd := cobra.Command{
    Use: "echo",
    Short: "echo your input",
    Run: func(cmd *cobra.Command, args []string){
        for _, arg := range args {
            if newLine != nil && *newLine{
                fmt.Println(arg)
            }else{
                fmt.Printf("%s ", arg)
            }
        }
        if newLine == nil || ! *newLine{
            fmt.Println()
        }
    },
}
newLine = subCmd.Flags().BoolP("newline", "n", false, "display one word per line")

cmd.AddCommand(&subCmd)
cmd.Execute()
```

这是一个简单的`echo`程序， cmd 拥有一个子命令 `subCmd`, `subCmd`通过`echo`(`Use: "echo"`)调用。`newLine = subCmd.Flags().BoolP("newline", "n", false, "display one word per line")` 为`subCmd` 添加了一个可选布尔型参数`-n`或`--newline`，这个参数的默认值是`false`。`newLine` 记录这个参数的值并在`Run`回调方法中使用。

运行结果

```bash
$ go run cobra.go echo aaa bbb
aaa bbb
```

```bash
$ go run cobra.go echo -n aaa bbb
aaa
bbb
```