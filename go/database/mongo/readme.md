# GO 操作 mongodb

go 使用官方驱动[`go.mongodb.org/mongo-driver/mongo`](https://github.com/mongodb/mongo-go-driver)来操作mongo数据库。

## 安装

```bash
go get go.mongodb.org/mongo-driver/mongo
```

## 使用

连接

```go
import (
    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"
    "go.mongodb.org/mongo-driver/mongo/readpref"
)

ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
defer cancel()
client, err := mongo.Connect(ctx, options.Client().ApplyURI("mongodb://localhost:27017"))
defer func() {
    if err = client.Disconnect(ctx); err != nil {
        panic(err)
    }
}()
```

测试连接

```go
ctx, cancel = context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()
err = client.Ping(ctx, readpref.Primary())
```

获取collection

```go
collection := client.Database("testing").Collection("numbers")
```

## 特殊类型

包 `go.mongodb.org/mongo-driver/bson/primitive` 转换一些数据到mongo类型

### `ISODate`

```go
t, err := time.Parse("2006-01-02T15:04:05.999", "2021-04-21T11:30:58.883")
if err != nil {
    log.Fatal(err)
}
t1 := primitive.NewDateTimeFromTime(t.Add(-8 * time.Hour))
```

## 复杂查询

```js
db.numbers.find({   "order_source" : 1, "order_history": { $elemMatch: {  "order_status": "27", "change_at": { $gte: ISODate("2021-04-21T11:30:58.883+08:00"),$lte: ISODate("2021-04-21T11:43:58.883+08:00")} } } })
```

```go
t, err := time.Parse("2006-01-02T15:04:05.999+08:00", "2021-04-21T11:30:58.883+08:00")
if err != nil {
    log.Fatal(err)
}
t1 := primitive.NewDateTimeFromTime(t.Add(-8 * time.Hour)) //
t, err = time.Parse("2006-01-02T15:04:05.999+08:00", "2021-04-21T11:43:58.883+08:00")
if err != nil {
    log.Fatal(err)
}
t2 := primitive.NewDateTimeFromTime(t.Add(-8 * time.Hour)) //
filter := bson.M{
    "order_source" : 1,
    "order_history": bson.M{
        "$elemMatch": bson.M{
            "order_status": "27", 
            "change_at": bson.M{ "$gte": t1,"$lte": t2},
        },
    },
}
ctx, cancel = context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()
collection.find(ctx, filter)
```

查询排序

```bash
opt := options.FindOptions{}
opt.SetSort(bson.D{{"order_no",1}})
ctx, cancel = context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()
collection.find(ctx, filter, &opt)
```