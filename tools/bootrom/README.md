Bootrom源码。

当从外部Flash启动时，需要先从此Bootrom启动（做一些初始化操作），然后通过Bootrom跳转到Flash地址空间，执行用户程序。

编译：

```
make
```

