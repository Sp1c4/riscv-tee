## 12 MHz Clock Signal
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { clk_12m_i }]; #IO_L12P_T1_MRCC_14 Sch=gclk
create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports {clk_12m_i}]

## 复位引脚
set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports rst_ext_i]; #IO_L19P_T3_16 Sch=btn[1]

## CPU停住指示引脚
set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports halted_ind_pin]; #IO_L12N_T1_MRCC_16 Sch=led[1]

## 串口引脚
# UART0 TX
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports {io_pins[0]}]; #IO_L7N_T1_D10_14 Sch=uart_rxd_out
# UART0 RX
set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports {io_pins[3]}]; #IO_L7P_T1_D09_14 Sch=uart_txd_in

## I2C引脚(EEPROM)
# I2C0 SCL引脚
set_property -dict { PACKAGE_PIN L1   IOSTANDARD LVCMOS33 } [get_ports {io_pins[6]}]; #IO_L6N_T0_VREF_35 Sch=pio[13]
# I2C0 SDA引脚
set_property -dict { PACKAGE_PIN L2   IOSTANDARD LVCMOS33 } [get_ports {io_pins[8]}]; #IO_L5N_T0_AD13N_35 Sch=pio[14]

## DS18B20
set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33 } [get_ports {io_pins[5]}]; #IO_L11P_T1_SRCC_16 Sch=pio[05]

## WS2812
set_property -dict { PACKAGE_PIN P1    IOSTANDARD LVCMOS33 } [get_ports {io_pins[4]}]; #IO_L19N_T3_VREF_35 Sch=pio[23]

## USER KEY
# KEY1
set_property -dict { PACKAGE_PIN U4    IOSTANDARD LVCMOS33 } [get_ports {io_pins[1]}]; #IO_L11P_T1_SRCC_34 Sch=pio[38]
# KEY2
set_property -dict { PACKAGE_PIN V5    IOSTANDARD LVCMOS33 } [get_ports {io_pins[2]}]; #IO_L16N_T2_34 Sch=pio[39]

## ANI
# PWM_V
set_property -dict { PACKAGE_PIN M3    IOSTANDARD LVCMOS33 } [get_ports {io_pins[7]}]; #IO_L8N_T1_AD14N_35 Sch=pio[01]
# C_OUT
set_property -dict { PACKAGE_PIN L3    IOSTANDARD LVCMOS33 } [get_ports {io_pins[9]}]; #IO_L8P_T1_AD14P_35 Sch=pio[02]

## LED
# LED4
#set_property -dict { PACKAGE_PIN R3    IOSTANDARD LVCMOS33 } [get_ports {io_pins[10]}]; #IO_L2P_T0_34 Sch=pio[26]
# LED5
#set_property -dict { PACKAGE_PIN T3    IOSTANDARD LVCMOS33 } [get_ports {io_pins[11]}]; #IO_L2N_T0_34 Sch=pio[27]
# LED6
#set_property -dict { PACKAGE_PIN R2    IOSTANDARD LVCMOS33 } [get_ports {io_pins[12]}]; #IO_L1P_T0_34 Sch=pio[28]
# LED7
#set_property -dict { PACKAGE_PIN T1    IOSTANDARD LVCMOS33 } [get_ports {io_pins[13]}]; #IO_L3P_T0_DQS_34 Sch=pio[29]

## GPIO
#set_property -dict { PACKAGE_PIN T2    IOSTANDARD LVCMOS33 } [get_ports {io_pins[14]}]; #IO_L1N_T0_34 Sch=pio[30]
#set_property -dict { PACKAGE_PIN U1    IOSTANDARD LVCMOS33 } [get_ports {io_pins[15]}]; #IO_L3N_T0_DQS_34 Sch=pio[31]

## SPI
# SS
set_property -dict { PACKAGE_PIN M1    IOSTANDARD LVCMOS33 } [get_ports {io_pins[11]}]; #IO_L9N_T1_DQS_AD7N_35 Sch=pio[17]
# DQ1
set_property -dict { PACKAGE_PIN N3    IOSTANDARD LVCMOS33 } [get_ports {io_pins[13]}]; #IO_L12P_T1_MRCC_35 Sch=pio[18]
# DQ2
set_property -dict { PACKAGE_PIN P3    IOSTANDARD LVCMOS33 } [get_ports {io_pins[14]}]; #IO_L12N_T1_MRCC_35 Sch=pio[19]
# DQ3
set_property -dict { PACKAGE_PIN M2    IOSTANDARD LVCMOS33 } [get_ports {io_pins[15]}]; #IO_L9P_T1_DQS_AD7P_35 Sch=pio[20]
# SCK
set_property -dict { PACKAGE_PIN N1    IOSTANDARD LVCMOS33 } [get_ports {io_pins[10]}]; #IO_L10N_T1_AD15N_35 Sch=pio[21]
# DQ0
set_property -dict { PACKAGE_PIN N2    IOSTANDARD LVCMOS33 } [get_ports {io_pins[12]}]; #IO_L10P_T1_AD15P_35 Sch=pio[22]

## QSPI Flash引脚(存放程序)
# CLK
set_property -dict { PACKAGE_PIN J1  IOSTANDARD LVCMOS33 } [get_ports flash_spi_clk_pin]; #IO_L3N_T0_DQS_AD5N_35 Sch=pio[11]
# SS
set_property -dict { PACKAGE_PIN A15  IOSTANDARD LVCMOS33 } [get_ports flash_spi_ss_pin]; #IO_L6N_T0_VREF_16 Sch=pio[07]
# DQ0
set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports {flash_spi_dq_pin[0]}]; #IO_L5P_T0_AD13P_35 Sch=pio[12]
# DQ1
set_property -dict { PACKAGE_PIN B15  IOSTANDARD LVCMOS33 } [get_ports {flash_spi_dq_pin[1]}]; #IO_L11N_T1_SRCC_16 Sch=pio[08]
# DQ2
set_property -dict { PACKAGE_PIN A14  IOSTANDARD LVCMOS33 } [get_ports {flash_spi_dq_pin[2]}]; #IO_L6P_T0_16 Sch=pio[09]
# DQ3
set_property -dict { PACKAGE_PIN J3  IOSTANDARD LVCMOS33 } [get_ports {flash_spi_dq_pin[3]}]; #IO_L7P_T1_AD6P_35 Sch=pio[10]

## JTAG引脚
# JTAG TCK引脚
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets jtag_TCK_pin]
set_property -dict { PACKAGE_PIN W7   IOSTANDARD LVCMOS33 } [get_ports jtag_TCK_pin]; #IO_L13P_T2_MRCC_34 Sch=pio[46]
# JTAG TMS引脚
set_property -dict { PACKAGE_PIN U8   IOSTANDARD LVCMOS33 } [get_ports jtag_TMS_pin]; #IO_L14P_T2_SRCC_34 Sch=pio[47]
# JTAG TDI引脚
set_property -dict { PACKAGE_PIN V8   IOSTANDARD LVCMOS33 } [get_ports jtag_TDI_pin]; #IO_L14N_T2_SRCC_34 Sch=pio[48]
# JTAG TDO引脚
set_property -dict { PACKAGE_PIN U7   IOSTANDARD LVCMOS33 } [get_ports jtag_TDO_pin]; #IO_L19P_T3_34 Sch=pio[45]

## Set unused pin pullnone
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullnone [current_design]

set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]  
set_property CONFIG_MODE SPIx4 [current_design] 
set_property BITSTREAM.CONFIG.CONFIGRATE 6 [current_design]
