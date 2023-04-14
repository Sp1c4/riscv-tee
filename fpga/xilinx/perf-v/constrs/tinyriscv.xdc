
# 时钟引脚
set_property IOSTANDARD LVCMOS33 [get_ports clk_50m_i]
set_property PACKAGE_PIN N14 [get_ports clk_50m_i]

# 时钟约束50MHz
create_clock -add -name SYS_CLK -period 20.00 [get_ports clk_50m_i]

# 复位引脚
set_property IOSTANDARD LVCMOS33 [get_ports rst_ext_ni]
set_property PACKAGE_PIN L13 [get_ports rst_ext_ni]

# CPU停住指示引脚
set_property IOSTANDARD LVCMOS33 [get_ports halted_ind_pin]
set_property PACKAGE_PIN P15 [get_ports halted_ind_pin]

# 串口发送引脚
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[0]}]
set_property PACKAGE_PIN M6 [get_ports {io_pins[0]}]

# 串口接收引脚
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[3]}]
set_property PACKAGE_PIN N6 [get_ports {io_pins[3]}]

# I2C0 SCL引脚
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[6]}]
set_property PACKAGE_PIN R10 [get_ports {io_pins[6]}]

# I2C0 SDA引脚
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[8]}]
set_property PACKAGE_PIN R11 [get_ports {io_pins[8]}]

# SPI DQ3引脚
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[15]}]
set_property PACKAGE_PIN T14 [get_ports {io_pins[15]}]

# SPI DQ2引脚
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[14]}]
set_property PACKAGE_PIN R16 [get_ports {io_pins[14]}]

# SPI DQ1引脚
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[13]}]
set_property PACKAGE_PIN R15 [get_ports {io_pins[13]}]

# SPI DQ0引脚
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[12]}]
set_property PACKAGE_PIN K13 [get_ports {io_pins[12]}]

# SPI SS引脚
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[11]}]
set_property PACKAGE_PIN L14 [get_ports {io_pins[11]}]

# SPI CLK引脚
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[10]}]
set_property PACKAGE_PIN M14 [get_ports {io_pins[10]}]

# GPIO0引脚
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[7]}]
set_property PACKAGE_PIN P16 [get_ports {io_pins[7]}]

# GPIO1引脚
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[9]}]
set_property PACKAGE_PIN T15 [get_ports {io_pins[9]}]


set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[2]}]
set_property PACKAGE_PIN T13 [get_ports {io_pins[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[1]}]
set_property PACKAGE_PIN R13 [get_ports {io_pins[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[4]}]
set_property PACKAGE_PIN R7 [get_ports {io_pins[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {io_pins[5]}]
set_property PACKAGE_PIN R6 [get_ports {io_pins[5]}]


# SPI Flash引脚
# CLK
set_property IOSTANDARD LVCMOS33 [get_ports flash_spi_clk_pin]
set_property PACKAGE_PIN N4 [get_ports flash_spi_clk_pin]
# SS
set_property IOSTANDARD LVCMOS33 [get_ports flash_spi_ss_pin]
set_property PACKAGE_PIN M5 [get_ports flash_spi_ss_pin]
# DQ0
set_property IOSTANDARD LVCMOS33 [get_ports {flash_spi_dq_pin[0]}]
set_property PACKAGE_PIN N1 [get_ports {flash_spi_dq_pin[0]}]
# DQ1
set_property IOSTANDARD LVCMOS33 [get_ports {flash_spi_dq_pin[1]}]
set_property PACKAGE_PIN P1 [get_ports {flash_spi_dq_pin[1]}]
# DQ2
set_property IOSTANDARD LVCMOS33 [get_ports {flash_spi_dq_pin[2]}]
set_property PACKAGE_PIN P4 [get_ports {flash_spi_dq_pin[2]}]
# DQ3
set_property IOSTANDARD LVCMOS33 [get_ports {flash_spi_dq_pin[3]}]
set_property PACKAGE_PIN P3 [get_ports {flash_spi_dq_pin[3]}]


# JTAG TCK引脚
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TCK_pin]
set_property PACKAGE_PIN N11 [get_ports jtag_TCK_pin]

# 1MHZ
#create_clock -name JTAG_CLK -period 1000 [get_ports jtag_TCK_pin]

# JTAG TMS引脚
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TMS_pin]
set_property PACKAGE_PIN N3 [get_ports jtag_TMS_pin]
#set_input_delay -clock JTAG_CLK 500 [get_ports jtag_TMS_pin]

# JTAG TDI引脚
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TDI_pin]
set_property PACKAGE_PIN N2 [get_ports jtag_TDI_pin]
#set_input_delay -clock JTAG_CLK 500 [get_ports jtag_TDI_pin]

# JTAG TDO引脚
set_property IOSTANDARD LVCMOS33 [get_ports jtag_TDO_pin]
set_property PACKAGE_PIN M1 [get_ports jtag_TDO_pin]
#set_output_delay -clock JTAG_CLK 500 [get_ports jtag_TDO_pin]

set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]  
set_property CONFIG_MODE SPIx4 [current_design] 
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
