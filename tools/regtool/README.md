# 使用方法

安装依赖。
```
$ pip3 install --user hjson
$ pip3 install --user mistletoe
$ pip3 install --user mako
```

## 1.生成RTL文件

```
regtool.py -r -t . xxx.hjson
```

其中.表示在当前目录生成。

## 2.生成C语言头文件

```
regtool.py -D -o xxx.h xxx.hjson
```

表示在当前目录生成xxx.h头文件。



详细说明文档见[这里](https://docs.opentitan.org/doc/rm/register_tool/)。