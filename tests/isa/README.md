RV32I instruction source code which copy from riscv(github).
I have modified it so can run on tinyriscv.
compile: type make under the cmd windows
recompile: type make after make clean under the cmd windows



编译方法：

1.修改Makefile里GNU工具链的路径：

```
RISCV_PREFIX ?= /opt/riscv32/bin/riscv32-unknown-elf-
```

2.修改Makefile里bin文件转men文件工具的路径：

```
BIN_TO_MEM    := $(src_dir)/../../tools/BinToMem.py
```

3.编译

```
make
```

4.重新编译

```
make clean
make
```

