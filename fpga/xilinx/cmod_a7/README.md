本目录包含FPGA约束文件，vivado tcl脚本和顶层文件。

```
constrs：包含FPGA约束文件
scripts：包含vivado tcl脚本
tinyriscv_soc_top.sv：整个SOC的顶层文件
```

根据vivado的安装路径，修改Makefile文件。

生成bit文件：

`make bit`

即可在out目录下生成bit文件。

