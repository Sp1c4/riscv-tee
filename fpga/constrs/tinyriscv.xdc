# 时钟约束50MHz
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports {clk}]; 
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 10} [get_ports {clk}];

# 时钟引脚
set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property PACKAGE_PIN U18 [get_ports clk]

# 复位引脚 KEY1
set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property PACKAGE_PIN M15 [get_ports rst]

# 程序执行完毕指示引脚 LED1
set_property IOSTANDARD LVCMOS33 [get_ports over]
set_property PACKAGE_PIN J14 [get_ports over]

# 程序执行成功指示引脚 LED2
set_property IOSTANDARD LVCMOS33 [get_ports succ]
set_property PACKAGE_PIN K14 [get_ports succ]

# CPU停住指示引脚 LED3
set_property IOSTANDARD LVCMOS33 [get_ports halted_ind]
set_property PACKAGE_PIN J18 [get_ports halted_ind]

# 串口下载使能引脚 pulldown
#set_property IOSTANDARD LVCMOS33 [get_ports uart_debug_pin]
#set_property PULLDOWN [get_ports uart_debug_pin]

# 串口发送引脚 32 T16
#set_property IOSTANDARD LVCMOS33 [get_ports uart_tx_pin]
#set_property PACKAGE_PIN T16 [get_ports uart_tx_pin]

# 串口接收引脚 30 N20
#set_property IOSTANDARD LVCMOS33 [get_ports uart_rx_pin]
#set_property PACKAGE_PIN N20 [get_ports uart_rx_pin]

# GPIO0引脚 LED4
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[0]}]
set_property PACKAGE_PIN H18 [get_ports {gpio[0]}]

# GPIO1引脚 KEY2
set_property IOSTANDARD LVCMOS33 [get_ports {gpio[1]}]
set_property PACKAGE_PIN M14 [get_ports {gpio[1]}]

# JTAG TCK引脚 34 T20
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TCK_0]
set_property PACKAGE_PIN T20  [get_ports jtag_TCK_0]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets jtag_TCK_0]

# JTAG TMS引脚 36 W15
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TMS_0]
set_property PACKAGE_PIN W15 [get_ports jtag_TMS_0]

# JTAG TDI引脚 26 W18
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TDI_0]
set_property PACKAGE_PIN W18 [get_ports jtag_TDI_0]

# JTAG TDO引脚 28 V20
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TDO_0]
set_property PACKAGE_PIN V20 [get_ports jtag_TDO_0]

# JTAG TCK引脚 33 U20
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TCK_1]
set_property PACKAGE_PIN U20  [get_ports jtag_TCK_1]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets jtag_TCK_1]

# JTAG TMS引脚 35 V15
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TMS_1]
set_property PACKAGE_PIN V15 [get_ports jtag_TMS_1]

# JTAG TDI引脚 25 W19
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TDI_1]
set_property PACKAGE_PIN W19 [get_ports jtag_TDI_1]

# JTAG TDO引脚 27 W20
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TDO_1]
set_property PACKAGE_PIN W20 [get_ports jtag_TDO_1]


# SPI MISO引脚 3
set_property IOSTANDARD LVCMOS33 [get_ports spi_miso]
set_property PACKAGE_PIN R14 [get_ports spi_miso]

# SPI MOSI引脚 5
set_property IOSTANDARD LVCMOS33 [get_ports spi_mosi]
set_property PACKAGE_PIN U12 [get_ports spi_mosi]

# SPI SS引脚 7
set_property IOSTANDARD LVCMOS33 [get_ports spi_ss]
set_property PACKAGE_PIN T15 [get_ports spi_ss]

# SPI CLK引脚 9
set_property IOSTANDARD LVCMOS33 [get_ports spi_clk]
set_property PACKAGE_PIN T11 [get_ports spi_clk]

set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]  
set_property CONFIG_MODE SPIx4 [current_design] 
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]