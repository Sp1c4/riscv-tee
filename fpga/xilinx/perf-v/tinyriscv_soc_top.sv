 /*                                                                      
 Copyright 2020 Blue Liang, liangkangnan@163.com
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
 Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */

`include "../../../rtl/core/defines.sv"
`include "../../../rtl/debug/jtag_def.sv"

// tinyriscv soc顶层模块
module tinyriscv_soc_top #(
    parameter bit          TRACE_ENABLE         = 1'b0,
    parameter int          GPIO_NUM             = 16,
    parameter int          I2C_NUM              = 2,
    parameter int          UART_NUM             = 3,
    parameter int          SPI_NUM              = 1
    )(
    input  wire               clk_50m_i,               // 时钟引脚
    input  wire               rst_ext_ni,              // 复位引脚，低电平有效

    output wire               halted_ind_pin,          // jtag是否已经halt住CPU，高电平有效

    inout  wire[GPIO_NUM-1:0] io_pins,                 // IO引脚，1bit代表一个IO

    output wire               flash_spi_clk_pin,       // flash spi clk引脚
    output wire               flash_spi_ss_pin,        // flash spi ss引脚
    inout  wire [3:0]         flash_spi_dq_pin,        // flash spi dq引脚

    input  wire               jtag_TCK_pin,            // JTAG TCK引脚
    input  wire               jtag_TMS_pin,            // JTAG TMS引脚
    input  wire               jtag_TDI_pin,            // JTAG TDI引脚
    output wire               jtag_TDO_pin             // JTAG TDO引脚
    );

    localparam int MASTERS      = 3;  // Number of master ports
    localparam int SLAVES       = 16; // Number of slave ports

    // masters
    localparam int JtagHost     = 0;
    localparam int CoreD        = 1;
    localparam int CoreI        = 2;

    // slaves
    localparam int Rom          = 0;
    localparam int Ram          = 1;
    localparam int JtagDevice   = 2;
    localparam int Timer0       = 3;
    localparam int Gpio         = 4;
    localparam int Uart0        = 5;
    localparam int Rvic         = 6;
    localparam int I2c0         = 7;
    localparam int Spi0         = 8;
    localparam int Pinmux       = 9;
    localparam int Uart1        = 10;
    localparam int Uart2        = 11;
    localparam int I2c1         = 12;
    localparam int Timer1       = 13;
    localparam int Timer2       = 14;
    localparam int FlashCtrl    = 15;

    wire           master_req       [MASTERS];
    wire           master_gnt       [MASTERS];
    wire           master_rvalid    [MASTERS];
    wire [31:0]    master_addr      [MASTERS];
    wire           master_we        [MASTERS];
    wire [ 3:0]    master_be        [MASTERS];
    wire [31:0]    master_rdata     [MASTERS];
    wire [31:0]    master_wdata     [MASTERS];

    wire           slave_req        [SLAVES];
    wire           slave_gnt        [SLAVES];
    wire           slave_rvalid     [SLAVES];
    wire [31:0]    slave_addr       [SLAVES];
    wire           slave_we         [SLAVES];
    wire [ 3:0]    slave_be         [SLAVES];
    wire [31:0]    slave_rdata      [SLAVES];
    wire [31:0]    slave_wdata      [SLAVES];

    wire [31:0]    slave_addr_mask  [SLAVES];
    wire [31:0]    slave_addr_base  [SLAVES];

    wire clk;
    wire ndmreset;
    wire ndmreset_n;
    wire debug_req;
    wire core_halted;

    reg[31:0] irq_src;
    wire int_req;
    wire[7:0] int_id;

    wire timer0_irq;
    wire timer1_irq;
    wire timer2_irq;
    wire uart0_irq;
    wire uart1_irq;
    wire uart2_irq;
    wire gpio0_irq;
    wire gpio1_irq;
    wire i2c0_irq;
    wire i2c1_irq;
    wire spi0_irq;
    wire gpio2_4_irq;
    wire gpio5_7_irq;
    wire gpio8_irq;
    wire gpio9_irq;
    wire gpio10_12_irq;
    wire gpio13_15_irq;

    wire[GPIO_NUM-1:0] gpio_data_in;
    wire[GPIO_NUM-1:0] gpio_oe;
    wire[GPIO_NUM-1:0] gpio_data_out;

    wire[GPIO_NUM-1:0] io_data_in;
    wire[GPIO_NUM-1:0] io_oe;
    wire[GPIO_NUM-1:0] io_data_out;

    wire[I2C_NUM-1:0] i2c_scl_in;
    wire[I2C_NUM-1:0] i2c_scl_oe;
    wire[I2C_NUM-1:0] i2c_scl_out;
    wire[I2C_NUM-1:0] i2c_sda_in;
    wire[I2C_NUM-1:0] i2c_sda_oe;
    wire[I2C_NUM-1:0] i2c_sda_out;

    wire[UART_NUM-1:0] uart_tx;
    wire[UART_NUM-1:0] uart_rx;

    wire[SPI_NUM-1:0] spi_clk_in;
    wire[SPI_NUM-1:0] spi_clk_oe;
    wire[SPI_NUM-1:0] spi_clk_out;
    wire[SPI_NUM-1:0] spi_ss_in;
    wire[SPI_NUM-1:0] spi_ss_oe;
    wire[SPI_NUM-1:0] spi_ss_out;
    wire[3:0]         spi_dq_in[SPI_NUM-1:0];
    wire[3:0]         spi_dq_oe[SPI_NUM-1:0];
    wire[3:0]         spi_dq_out[SPI_NUM-1:0];

    wire[31:0]        core_instr_addr;
    wire[31:0]        core_data_addr;

    wire[3:0]         flash_spi_dq_in;
    wire[3:0]         flash_spi_dq_oe;
    wire[3:0]         flash_spi_dq_out;

    // 中断源
    always @ (*) begin
        irq_src     = 32'h0;
        irq_src[ 0] = timer0_irq;
        irq_src[ 1] = uart0_irq;
        irq_src[ 2] = gpio0_irq;
        irq_src[ 3] = gpio1_irq;
        irq_src[ 4] = i2c0_irq;
        irq_src[ 5] = spi0_irq;
        irq_src[ 6] = gpio2_4_irq;
        irq_src[ 7] = gpio5_7_irq;
        irq_src[ 8] = gpio8_irq;
        irq_src[ 9] = gpio9_irq;
        irq_src[10] = gpio10_12_irq;
        irq_src[11] = gpio13_15_irq;
        irq_src[12] = uart1_irq;
        irq_src[13] = uart2_irq;
        irq_src[14] = i2c1_irq;
        irq_src[15] = timer1_irq;
        irq_src[16] = timer2_irq;
    end

    // FPGA低电平点亮LED
    assign halted_ind_pin = ~core_halted;

    tinyriscv_core #(
        .DEBUG_HALT_ADDR(`DEBUG_ADDR_BASE + `HaltAddress),
        .DEBUG_EXCEPTION_ADDR(`DEBUG_ADDR_BASE + `ExceptionAddress),
        .BranchPredictor(1'b1),
        .TRACE_ENABLE(TRACE_ENABLE)
    ) u_tinyriscv_core (
        .clk            (clk),
        .rst_n          (ndmreset_n),

        .instr_req_o    (master_req[CoreI]),
        .instr_gnt_i    (master_gnt[CoreI]),
        .instr_rvalid_i (master_rvalid[CoreI]),
        .instr_addr_o   (core_instr_addr),
        .instr_rdata_i  (master_rdata[CoreI]),
        .instr_err_i    (1'b0),

        .data_req_o     (master_req[CoreD]),
        .data_gnt_i     (master_gnt[CoreD]),
        .data_rvalid_i  (master_rvalid[CoreD]),
        .data_we_o      (master_we[CoreD]),
        .data_be_o      (master_be[CoreD]),
        .data_addr_o    (core_data_addr),
        .data_wdata_o   (master_wdata[CoreD]),
        .data_rdata_i   (master_rdata[CoreD]),
        .data_err_i     (1'b0),

        .int_req_i      (int_req),
        .int_id_i       (int_id),

        .debug_req_i    (debug_req)
    );

    // 是否访问flash
    wire instr_access_flash;
    wire data_access_flash;

    assign instr_access_flash = ((core_instr_addr & (`FLASH_ADDR_MASK)) == `FLASH_ADDR_BASE);
    assign data_access_flash  = ((core_data_addr & (`FLASH_ADDR_MASK)) == `FLASH_ADDR_BASE);

    // 转换后的地址
    wire [31:0] instr_tran_addr;
    wire [31:0] data_tran_addr;

    assign instr_tran_addr = (core_instr_addr & (~(`FLASH_CTRL_ADDR_MASK))) | `FLASH_CTRL_ADDR_BASE;
    assign data_tran_addr  = (core_data_addr & (~(`FLASH_CTRL_ADDR_MASK))) | `FLASH_CTRL_ADDR_BASE;

    // 当访问flash空间时，转去访问flash ctrl模块
    assign master_addr[CoreI] = instr_access_flash ?  ({instr_tran_addr[31:24], 1'b1, instr_tran_addr[22:0]}) :
                                core_instr_addr;
    assign master_addr[CoreD] = data_access_flash ? ({data_tran_addr[31:24], 1'b1, data_tran_addr[22:0]}) :
                                core_data_addr;

    assign slave_addr_mask[Rom] = `ROM_ADDR_MASK;
    assign slave_addr_base[Rom] = `ROM_ADDR_BASE;
    // 1.指令存储器
    rom #(
        .DP(`ROM_DEPTH)
    ) u_rom (
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .req_i      (slave_req[Rom]),
        .addr_i     (slave_addr[Rom]),
        .data_i     (slave_wdata[Rom]),
        .be_i       (slave_be[Rom]),
        .we_i       (slave_we[Rom]),
        .gnt_o      (slave_gnt[Rom]),
        .rvalid_o   (slave_rvalid[Rom]),
        .data_o     (slave_rdata[Rom])
    );

    assign slave_addr_mask[Ram] = `RAM_ADDR_MASK;
    assign slave_addr_base[Ram] = `RAM_ADDR_BASE;
    // 2.数据存储器
    ram #(
        .DP(`RAM_DEPTH)
    ) u_ram (
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .req_i      (slave_req[Ram]),
        .addr_i     (slave_addr[Ram]),
        .data_i     (slave_wdata[Ram]),
        .be_i       (slave_be[Ram]),
        .we_i       (slave_we[Ram]),
        .gnt_o      (slave_gnt[Ram]),
        .rvalid_o   (slave_rvalid[Ram]),
        .data_o     (slave_rdata[Ram])
    );

    assign slave_addr_mask[Timer0] = `TIMER0_ADDR_MASK;
    assign slave_addr_base[Timer0] = `TIMER0_ADDR_BASE;
    // 3.定时器0模块
    timer_top timer0(
        .clk_i   (clk),
        .rst_ni  (ndmreset_n),
        .irq_o   (timer0_irq),
        .req_i   (slave_req[Timer0]),
        .we_i    (slave_we[Timer0]),
        .be_i    (slave_be[Timer0]),
        .addr_i  (slave_addr[Timer0]),
        .data_i  (slave_wdata[Timer0]),
        .gnt_o   (slave_gnt[Timer0]),
        .rvalid_o(slave_rvalid[Timer0]),
        .data_o  (slave_rdata[Timer0])
    );

    assign slave_addr_mask[Timer1] = `TIMER1_ADDR_MASK;
    assign slave_addr_base[Timer1] = `TIMER1_ADDR_BASE;
    // 4.定时器1模块
    timer_top timer1(
        .clk_i   (clk),
        .rst_ni  (ndmreset_n),
        .irq_o   (timer1_irq),
        .req_i   (slave_req[Timer1]),
        .we_i    (slave_we[Timer1]),
        .be_i    (slave_be[Timer1]),
        .addr_i  (slave_addr[Timer1]),
        .data_i  (slave_wdata[Timer1]),
        .gnt_o   (slave_gnt[Timer1]),
        .rvalid_o(slave_rvalid[Timer1]),
        .data_o  (slave_rdata[Timer1])
    );

    assign slave_addr_mask[Timer2] = `TIMER2_ADDR_MASK;
    assign slave_addr_base[Timer2] = `TIMER2_ADDR_BASE;
    // 5.定时器2模块
    timer_top timer2(
        .clk_i   (clk),
        .rst_ni  (ndmreset_n),
        .irq_o   (timer2_irq),
        .req_i   (slave_req[Timer2]),
        .we_i    (slave_we[Timer2]),
        .be_i    (slave_be[Timer2]),
        .addr_i  (slave_addr[Timer2]),
        .data_i  (slave_wdata[Timer2]),
        .gnt_o   (slave_gnt[Timer2]),
        .rvalid_o(slave_rvalid[Timer2]),
        .data_o  (slave_rdata[Timer2])
    );

    assign slave_addr_mask[Gpio] = `GPIO_ADDR_MASK;
    assign slave_addr_base[Gpio] = `GPIO_ADDR_BASE;
    // 6.GPIO模块
    gpio_top #(
        .GPIO_NUM(GPIO_NUM)
    ) u_gpio (
        .clk_i          (clk),
        .rst_ni         (ndmreset_n),
        .gpio_oe_o      (gpio_oe),
        .gpio_data_o    (gpio_data_out),
        .gpio_data_i    (gpio_data_in),
        .irq_gpio0_o    (gpio0_irq),
        .irq_gpio1_o    (gpio1_irq),
        .irq_gpio2_4_o  (gpio2_4_irq),
        .irq_gpio5_7_o  (gpio5_7_irq),
        .irq_gpio8_o    (gpio8_irq),
        .irq_gpio9_o    (gpio9_irq),
        .irq_gpio10_12_o(gpio10_12_irq),
        .irq_gpio13_15_o(gpio13_15_irq),
        .req_i          (slave_req[Gpio]),
        .we_i           (slave_we[Gpio]),
        .be_i           (slave_be[Gpio]),
        .addr_i         (slave_addr[Gpio]),
        .data_i         (slave_wdata[Gpio]),
        .gnt_o          (slave_gnt[Gpio]),
        .rvalid_o       (slave_rvalid[Gpio]),
        .data_o         (slave_rdata[Gpio])
    );

    assign slave_addr_mask[Uart0] = `UART0_ADDR_MASK;
    assign slave_addr_base[Uart0] = `UART0_ADDR_BASE;
    // 7.串口0模块
    uart_top uart0 (
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .rx_i       (uart_rx[0]),
        .tx_o       (uart_tx[0]),
        .irq_o      (uart0_irq),
        .req_i      (slave_req[Uart0]),
        .we_i       (slave_we[Uart0]),
        .be_i       (slave_be[Uart0]),
        .addr_i     (slave_addr[Uart0]),
        .data_i     (slave_wdata[Uart0]),
        .gnt_o      (slave_gnt[Uart0]),
        .rvalid_o   (slave_rvalid[Uart0]),
        .data_o     (slave_rdata[Uart0])
    );

    assign slave_addr_mask[Uart1] = `UART1_ADDR_MASK;
    assign slave_addr_base[Uart1] = `UART1_ADDR_BASE;
    // 8.串口1模块
    uart_top uart1 (
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .rx_i       (uart_rx[1]),
        .tx_o       (uart_tx[1]),
        .irq_o      (uart1_irq),
        .req_i      (slave_req[Uart1]),
        .we_i       (slave_we[Uart1]),
        .be_i       (slave_be[Uart1]),
        .addr_i     (slave_addr[Uart1]),
        .data_i     (slave_wdata[Uart1]),
        .gnt_o      (slave_gnt[Uart1]),
        .rvalid_o   (slave_rvalid[Uart1]),
        .data_o     (slave_rdata[Uart1])
    );

    assign slave_addr_mask[Uart2] = `UART2_ADDR_MASK;
    assign slave_addr_base[Uart2] = `UART2_ADDR_BASE;
    // 9.串口2模块
    uart_top uart2 (
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .rx_i       (uart_rx[2]),
        .tx_o       (uart_tx[2]),
        .irq_o      (uart2_irq),
        .req_i      (slave_req[Uart2]),
        .we_i       (slave_we[Uart2]),
        .be_i       (slave_be[Uart2]),
        .addr_i     (slave_addr[Uart2]),
        .data_i     (slave_wdata[Uart2]),
        .gnt_o      (slave_gnt[Uart2]),
        .rvalid_o   (slave_rvalid[Uart2]),
        .data_o     (slave_rdata[Uart2])
    );

    assign slave_addr_mask[Rvic] = `RVIC_ADDR_MASK;
    assign slave_addr_base[Rvic] = `RVIC_ADDR_BASE;
    // 10.中断控制器模块
    rvic_top u_rvic(
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .src_i      (irq_src),
        .irq_o      (int_req),
        .irq_id_o   (int_id),
        .req_i      (slave_req[Rvic]),
        .we_i       (slave_we[Rvic]),
        .be_i       (slave_be[Rvic]),
        .addr_i     (slave_addr[Rvic]),
        .data_i     (slave_wdata[Rvic]),
        .gnt_o      (slave_gnt[Rvic]),
        .rvalid_o   (slave_rvalid[Rvic]),
        .data_o     (slave_rdata[Rvic])
    );

    assign slave_addr_mask[I2c0] = `I2C0_ADDR_MASK;
    assign slave_addr_base[I2c0] = `I2C0_ADDR_BASE;
    // 11.I2C0模块
    i2c_top i2c0(
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .scl_o      (i2c_scl_out[0]),
        .scl_oe_o   (i2c_scl_oe[0]),
        .scl_i      (i2c_scl_in[0]),
        .sda_o      (i2c_sda_out[0]),
        .sda_oe_o   (i2c_sda_oe[0]),
        .sda_i      (i2c_sda_in[0]),
        .irq_o      (i2c0_irq),
        .req_i      (slave_req[I2c0]),
        .we_i       (slave_we[I2c0]),
        .be_i       (slave_be[I2c0]),
        .addr_i     (slave_addr[I2c0]),
        .data_i     (slave_wdata[I2c0]),
        .gnt_o      (slave_gnt[I2c0]),
        .rvalid_o   (slave_rvalid[I2c0]),
        .data_o     (slave_rdata[I2c0])
    );

    assign slave_addr_mask[I2c1] = `I2C1_ADDR_MASK;
    assign slave_addr_base[I2c1] = `I2C1_ADDR_BASE;
    // 12.I2C1模块
    i2c_top i2c1(
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .scl_o      (i2c_scl_out[1]),
        .scl_oe_o   (i2c_scl_oe[1]),
        .scl_i      (i2c_scl_in[1]),
        .sda_o      (i2c_sda_out[1]),
        .sda_oe_o   (i2c_sda_oe[1]),
        .sda_i      (i2c_sda_in[1]),
        .irq_o      (i2c1_irq),
        .req_i      (slave_req[I2c1]),
        .we_i       (slave_we[I2c1]),
        .be_i       (slave_be[I2c1]),
        .addr_i     (slave_addr[I2c1]),
        .data_i     (slave_wdata[I2c1]),
        .gnt_o      (slave_gnt[I2c1]),
        .rvalid_o   (slave_rvalid[I2c1]),
        .data_o     (slave_rdata[I2c1])
    );

    assign slave_addr_mask[Spi0] = `SPI0_ADDR_MASK;
    assign slave_addr_base[Spi0] = `SPI0_ADDR_BASE;
    // 13.SPI0模块
    spi_top spi0(
        .clk_i      (clk),
        .rst_ni     (ndmreset_n),
        .spi_clk_i  (spi_clk_in[0]),
        .spi_clk_o  (spi_clk_out[0]),
        .spi_clk_oe_o(spi_clk_oe[0]),
        .spi_ss_i   (spi_ss_in[0]),
        .spi_ss_o   (spi_ss_out[0]),
        .spi_ss_oe_o(spi_ss_oe[0]),
        .spi_dq0_i  (spi_dq_in[0][0]),
        .spi_dq0_o  (spi_dq_out[0][0]),
        .spi_dq0_oe_o(spi_dq_oe[0][0]),
        .spi_dq1_i  (spi_dq_in[0][1]),
        .spi_dq1_o  (spi_dq_out[0][1]),
        .spi_dq1_oe_o(spi_dq_oe[0][1]),
        .spi_dq2_i  (spi_dq_in[0][2]),
        .spi_dq2_o  (spi_dq_out[0][2]),
        .spi_dq2_oe_o(spi_dq_oe[0][2]),
        .spi_dq3_i  (spi_dq_in[0][3]),
        .spi_dq3_o  (spi_dq_out[0][3]),
        .spi_dq3_oe_o(spi_dq_oe[0][3]),
        .irq_o      (spi0_irq),
        .req_i      (slave_req[Spi0]),
        .we_i       (slave_we[Spi0]),
        .be_i       (slave_be[Spi0]),
        .addr_i     (slave_addr[Spi0]),
        .data_i     (slave_wdata[Spi0]),
        .gnt_o      (slave_gnt[Spi0]),
        .rvalid_o   (slave_rvalid[Spi0]),
        .data_o     (slave_rdata[Spi0])
    );

    for (genvar i = 0; i < GPIO_NUM; i = i + 1) begin : g_io_data
        assign io_pins[i] = io_oe[i] ? io_data_out[i] : 1'bz;
        assign io_data_in[i] = io_pins[i];
    end

    assign slave_addr_mask[Pinmux] = `PINMUX_ADDR_MASK;
    assign slave_addr_base[Pinmux] = `PINMUX_ADDR_BASE;
    // 14.PINMUX模块
    pinmux_top #(
        .GPIO_NUM(GPIO_NUM),
        .I2C_NUM(I2C_NUM),
        .UART_NUM(UART_NUM),
        .SPI_NUM(SPI_NUM)
    ) u_pinmux (
        .clk_i          (clk),
        .rst_ni         (ndmreset_n),
        .gpio_oe_i      (gpio_oe),
        .gpio_val_i     (gpio_data_out),
        .gpio_val_o     (gpio_data_in),
        .i2c_sda_oe_i   (i2c_sda_oe),
        .i2c_sda_val_i  (i2c_sda_out),
        .i2c_sda_val_o  (i2c_sda_in),
        .i2c_scl_oe_i   (i2c_scl_oe),
        .i2c_scl_val_i  (i2c_scl_out),
        .i2c_scl_val_o  (i2c_scl_in),
        .uart_tx_oe_i   ({UART_NUM{1'b1}}),
        .uart_tx_val_i  (uart_tx),
        .uart_tx_val_o  (),
        .uart_rx_oe_i   ({UART_NUM{1'b0}}),
        .uart_rx_val_i  (),
        .uart_rx_val_o  (uart_rx),
        .spi_clk_oe_i   (spi_clk_oe),
        .spi_clk_val_i  (spi_clk_out),
        .spi_clk_val_o  (spi_clk_in),
        .spi_ss_oe_i    (spi_ss_oe),
        .spi_ss_val_i   (spi_ss_out),
        .spi_ss_val_o   (spi_ss_in),
        .spi_dq_oe_i    (spi_dq_oe),
        .spi_dq_val_i   (spi_dq_out),
        .spi_dq_val_o   (spi_dq_in),
        .io_val_i       (io_data_in),
        .io_val_o       (io_data_out),
        .io_oe_o        (io_oe),
        .req_i          (slave_req[Pinmux]),
        .we_i           (slave_we[Pinmux]),
        .be_i           (slave_be[Pinmux]),
        .addr_i         (slave_addr[Pinmux]),
        .data_i         (slave_wdata[Pinmux]),
        .gnt_o          (slave_gnt[Pinmux]),
        .rvalid_o       (slave_rvalid[Pinmux]),
        .data_o         (slave_rdata[Pinmux])
    );

    for (genvar j = 0; j < 4; j = j + 1) begin : g_spi_pin_data
        assign flash_spi_dq_pin[j] = flash_spi_dq_oe[j] ? flash_spi_dq_out[j] : 1'bz;
        assign flash_spi_dq_in[j] = flash_spi_dq_pin[j];
    end

    assign slave_addr_mask[FlashCtrl] = `FLASH_CTRL_ADDR_MASK;
    assign slave_addr_base[FlashCtrl] = `FLASH_CTRL_ADDR_BASE;
    // 15.flash ctrl模块
    flash_ctrl_top flash_ctrl (
        .clk_i          (clk),
        .rst_ni         (ndmreset_n),
        .spi_clk_o      (flash_spi_clk_pin),
        .spi_clk_oe_o   (),
        .spi_ss_o       (flash_spi_ss_pin),
        .spi_ss_oe_o    (),
        .spi_dq0_i      (flash_spi_dq_in[0]),
        .spi_dq0_o      (flash_spi_dq_out[0]),
        .spi_dq0_oe_o   (flash_spi_dq_oe[0]),
        .spi_dq1_i      (flash_spi_dq_in[1]),
        .spi_dq1_o      (flash_spi_dq_out[1]),
        .spi_dq1_oe_o   (flash_spi_dq_oe[1]),
        .spi_dq2_i      (flash_spi_dq_in[2]),
        .spi_dq2_o      (flash_spi_dq_out[2]),
        .spi_dq2_oe_o   (flash_spi_dq_oe[2]),
        .spi_dq3_i      (flash_spi_dq_in[3]),
        .spi_dq3_o      (flash_spi_dq_out[3]),
        .spi_dq3_oe_o   (flash_spi_dq_oe[3]),
        .req_i          (slave_req[FlashCtrl]),
        .we_i           (slave_we[FlashCtrl]),
        .be_i           (slave_be[FlashCtrl]),
        .addr_i         (slave_addr[FlashCtrl]),
        .data_i         (slave_wdata[FlashCtrl]),
        .gnt_o          (slave_gnt[FlashCtrl]),
        .rvalid_o       (slave_rvalid[FlashCtrl]),
        .data_o         (slave_rdata[FlashCtrl])
    );

    // 内部总线
    obi_interconnect #(
        .MASTERS(MASTERS),
        .SLAVES(SLAVES)
    ) bus (
        .clk_i              (clk),
        .rst_ni             (ndmreset_n),
        .master_req_i       (master_req),
        .master_gnt_o       (master_gnt),
        .master_rvalid_o    (master_rvalid),
        .master_we_i        (master_we),
        .master_be_i        (master_be),
        .master_addr_i      (master_addr),
        .master_wdata_i     (master_wdata),
        .master_rdata_o     (master_rdata),
        .slave_addr_mask_i  (slave_addr_mask),
        .slave_addr_base_i  (slave_addr_base),
        .slave_req_o        (slave_req),
        .slave_gnt_i        (slave_gnt),
        .slave_rvalid_i     (slave_rvalid),
        .slave_we_o         (slave_we),
        .slave_be_o         (slave_be),
        .slave_addr_o       (slave_addr),
        .slave_wdata_o      (slave_wdata),
        .slave_rdata_i      (slave_rdata)
    );

    // 使用xilinx vivado中的mmcm IP进行分频
    // 输入为50MHZ，输出为25MHZ
    mmcm_main_clk u_mmcm_main_clk(
      .clk_out1(clk),
      .resetn(rst_ext_ni),
      .clk_in1(clk_50m_i)
    );

    // 复位信号产生
    rst_gen #(
        .RESET_FIFO_DEPTH(5)
    ) u_rst (
        .clk    (clk),
        .rst_ni (rst_ext_ni & (~ndmreset)),
        .rst_no (ndmreset_n)
    );

    assign slave_addr_mask[JtagDevice] = `DEBUG_ADDR_MASK;
    assign slave_addr_base[JtagDevice] = `DEBUG_ADDR_BASE;
    // JTAG模块
    jtag_top #(

    ) u_jtag (
        .clk_i              (clk),
        .rst_ni             (rst_ext_ni),
        .debug_req_o        (debug_req),
        .ndmreset_o         (ndmreset),
        .halted_o           (core_halted),
        .jtag_tck_i         (jtag_TCK_pin),
        .jtag_tdi_i         (jtag_TDI_pin),
        .jtag_tms_i         (jtag_TMS_pin),
        .jtag_trst_ni       (rst_ext_ni),
        .jtag_tdo_o         (jtag_TDO_pin),
        .master_req_o       (master_req[JtagHost]),
        .master_gnt_i       (master_gnt[JtagHost]),
        .master_rvalid_i    (master_rvalid[JtagHost]),
        .master_we_o        (master_we[JtagHost]),
        .master_be_o        (master_be[JtagHost]),
        .master_addr_o      (master_addr[JtagHost]),
        .master_wdata_o     (master_wdata[JtagHost]),
        .master_rdata_i     (master_rdata[JtagHost]),
        .master_err_i       (1'b0),
        .slave_req_i        (slave_req[JtagDevice]),
        .slave_we_i         (slave_we[JtagDevice]),
        .slave_addr_i       (slave_addr[JtagDevice]),
        .slave_be_i         (slave_be[JtagDevice]),
        .slave_wdata_i      (slave_wdata[JtagDevice]),
        .slave_gnt_o        (slave_gnt[JtagDevice]),
        .slave_rvalid_o     (slave_rvalid[JtagDevice]),
        .slave_rdata_o      (slave_rdata[JtagDevice])
    );

endmodule
