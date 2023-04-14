# 1.概述

介绍如何将tinyriscv移植到FPGA平台上和如何通过JTAG下载程序到FPGA。

1.软件：xilinx vivado(以2018.1版本为例)开发环境。

2.FPGA：xilinx Artix-7 35T。

3.调试器：CMSIS-DAP或者DAPLink（要带JTAG功能）。

这里只是以Xilinx平台为例，实际上可以移植到任何FPGA平台（只要资源足够）。

# 2.FPGA移植步骤

## 2.1创建工程

首先打开vivado软件，新建工程，方法如下图所示：

![](./images/create_prj_1.png)

或者通过File菜单新建工程，如下图所示：

![](./images/create_prj_2.png)

然后进入下一步，如下图所示：

![](./images/create_prj_3.png)

直接点击Next按钮，进入下一步，如下图所示：

![](./images/create_prj_4.png)

输入工程名字和工程路径，勾选上Create project subdirectiry选项，然后点击Next按钮，如下图所示：

![](./images/create_prj_5.png)

选择RTL Project，并勾选上Do not specify sources at this time，然后点击Next按钮，如下图所示：

![](./images/create_prj_6.png)

在Search框里输入256-1，然后选中xc7a35tftg256-1这个型号，然后点击Next按钮，如下图所示：

![](./images/create_prj_7.png)

直接点击Finish按钮。

至此，工程创建完成。

## 2.2添加RTL源文件

在工程主界面，点击左侧的Add Sources按钮，如下图所示：

![](./images/add_src_1.png)

进入到如下图的界面：

![](./images/add_src_2.png)

选中第二项Add or create design sources，然后点击Next按钮，如下图所示：

![](./images/add_src_3.png)

点击Add Directories按钮，选择tinyriscv项目里的整个rtl文件夹，如下图所示：

![](./images/add_src_4.png)

勾选上红色框里那两项，然后点击Finish按钮。

最后，还要添加顶层文件，即fpga/xilinx/perf-v/tinyriscv_soc_top.sv文件。

至此，RTL源文件添加完成。

## 2.3添加约束文件

在工程主界面，点击左侧的Add Sources按钮，如下图所示：

![](./images/add_src_1.png)

进入到如下图的界面：

![](./images/add_src_5.png)

选择第一项Add or create constraints，然后点击Next按钮，如下图所示：

![](./images/add_src_6.png)

点击Add Files按钮，选择tinyriscv项目里的fpga/xilinx/perf-v/constrs/tinyriscv.xdc文件，如下图所示：

![](./images/add_src_7.png)

勾选上Copy constraints files into project，然后点击Finish按钮。

**注意：如果你的开发板和我的不一样，则需要将约束文件里的引脚配置改成你的开发板上对应的引脚**。

至此，约束文件添加完成。

## 2.4生成Bitstream文件

点击下图所示的Generate Bitstream按钮，即可开始生成Bitstream文件。

这包括综合、实现(布局布线)等过程，因此时间会比较长。

![](./images/add_src_8.png)

## 2.5下载Bitstream文件到FPGA

连接好下载器和FPGA开发板，将下载器插入PC，然后给板子上电，接着点击vivado主界面的左下角的Open Hardware Manager按钮，如下图所示：

![](./images/download_1.png)

接着，点击Open target按钮，然后选择Auto Connect，如下图所示：

![](./images/download_2.png)

连接成功后，点击Program device按钮，如下图所示：

![](./images/download_3.png)

弹出如下界面，然后直接点击Program按钮。

![](./images/download_4.png)

至此，即可将Bitstream文件下载到FPGA。

## 2.6固化软核到FPGA

对于下载Bitstream文件到FPGA这种方式，当断电后再上电就要重新下载，因此可以将tinyriscv软核固化到FPGA，这样每次上电后就不需要重新下载Bitstream文件了，只需要下载bin文件就可以。

点击vivado工具栏的Tools-->Generate Memory Configuration File...选项后会出现以下界面：

![config_mcs](./images/config_mcs.png)

按照图中红色框来设置，然后点击确定。

然后点击Open Hardware Manager，按下图选择：

![add_mcs_device](./images/add_mcs_device.png)

然后按下图设置：

![select_spi](./images/select_spi.png)

弹出如下对话框，点击确定。

![mcs_ok](./images/mcs_ok.png)

最后按下图设置：

![mcs_prog](./images/mcs_prog.png)

点击确定后开始固化。固化过程比下载Bitstream文件的时间要长，耐心等待一下即可。

# 3.下载程序到FPGA

## 3.1通过JTAG方式下载

将CMSIS-DAP调试器连接好FPGA板子和PC电脑。

打开一个CMD窗口，然后cd进入到tinyriscv项目的tools/openocd目录，执行命令：

`openocd_win.exe -f tinyriscv_cmsisdap_jtag.cfg`

如果执行成功的话则会如下图所示（由于项目一直在更新，图片上的信息可能会跟实际的不一致，以文字描述为准）：

![openocd](./images/openocd.png)

然后打开另一个CMD窗口，执行以下命令来连接openocd，注意电脑要启用telnet host服务。

`telnet localhost 4444`

然后在这个CMD窗口下使用load_bin命令将固件下载到FPGA的ROM里（掉电会消失），这里以freertos.bin文件为例，如下所示：

`load_bin D:/gitee/open/tinyriscv/tests/example/FreeRTOS/Demo/tinyriscv_GCC/freertos.bin 0x0 1`

load_bin命令用法：

`load_bin file address verify[0|1]`

file：表示要下载的bin文件

address：表示要下载的地址

verify：表示是否检验，1：校验，0：不校验

最后执行以下命令让程序跑起来：

`resume 0`

或者

`reset`

或者短按一下开发板上的复位按键。

**注意：每次下载程序前记得先执行halt命令停住CPU。**

