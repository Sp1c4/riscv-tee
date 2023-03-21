

`include "../core/defines.v"

// tinyriscv soc顶层模块
module tinyriscv_soc_top(

    input wire clk,
    input wire rst,

    output reg over,         // 测试是否完成信号
    output reg succ,         // 测试是否成功信号

    output wire halted_ind,  // jtag是否已经halt住CPU信号

    //input wire uart_debug_pin, // 串口下载使能引脚
    //output wire uart_tx_pin, // UART发送引脚
    //input wire uart_rx_pin,  // UART接收引脚

    inout wire[1:0] gpio,    // GPIO引脚

    input wire jtag_TCK_0,     // JTAG TCK引脚
    input wire jtag_TMS_0,     // JTAG TMS引脚
    input wire jtag_TDI_0,     // JTAG TDI引脚
    output wire jtag_TDO_0,    // JTAG TDO引脚

    input wire jtag_TCK_1,     // JTAG TCK引脚
    input wire jtag_TMS_1,     // JTAG TMS引脚
    input wire jtag_TDI_1,     // JTAG TDI引脚
    output wire jtag_TDO_1,    // JTAG TDO引脚

    input wire spi_miso,     // SPI MISO引脚
    output wire spi_mosi,    // SPI MOSI引脚
    output wire spi_ss,      // SPI SS引脚
    output wire spi_clk      // SPI CLK引脚

    );

    wire uart_debug_pin=0; // 串口下载使能引脚
    wire uart_tx_pin=0; // UART发送引脚
    wire uart_rx_pin=0;  // UART接收引脚

    // master 0 interface 
    //core0 外设
    wire[`MemAddrBus] m0_addr_i;
    wire[`MemBus] m0_data_i;
    wire[`MemBus] m0_data_o;
    wire m0_req_i;
    wire m0_we_i;

    // master 1 interface
    //core0 program
    wire[`MemAddrBus] m1_addr_i;
    wire[`MemBus] m1_data_i;
    wire[`MemBus] m1_data_o;
    wire m1_req_i;
    wire m1_we_i;

    // master 2 interface 
    //core0 jtag
    wire[`MemAddrBus] m2_addr_i;
    wire[`MemBus] m2_data_i;
    wire[`MemBus] m2_data_o;
    wire m2_req_i;
    wire m2_we_i;

    // master 3 interface
    //core1 外设
    wire[`MemAddrBus] m3_addr_i;
    wire[`MemBus] m3_data_i;
    wire[`MemBus] m3_data_o;
    wire m3_req_i;
    wire m3_we_i;

    // master 4 interface
    //core1 program
    wire[`MemAddrBus] m4_addr_i;
    wire[`MemBus] m4_data_i;
    wire[`MemBus] m4_data_o;
    wire m4_req_i;
    wire m4_we_i;

    // master 5 interface
    //core1 jtag
    wire[`MemAddrBus] m5_addr_i;
    wire[`MemBus] m5_data_i;
    wire[`MemBus] m5_data_o;
    wire m5_req_i;
    wire m5_we_i;
    

    // slave 0 interface
    wire[`MemAddrBus] s0_addr_o;
    wire[`MemBus] s0_data_o;
    wire[`MemBus] s0_data_i;
    wire s0_we_o;

    // slave 1 interface
    wire[`MemAddrBus] s1_addr_o;
    wire[`MemBus] s1_data_o;
    wire[`MemBus] s1_data_i;
    wire s1_we_o;

    // slave 2 interface
    wire[`MemAddrBus] s2_addr_o;
    wire[`MemBus] s2_data_o;
    wire[`MemBus] s2_data_i;
    wire s2_we_o;

    // slave 3 interface
    wire[`MemAddrBus] s3_addr_o;
    wire[`MemBus] s3_data_o;
    wire[`MemBus] s3_data_i;
    wire s3_we_o;

    // slave 4 interface
    wire[`MemAddrBus] s4_addr_o;
    wire[`MemBus] s4_data_o;
    wire[`MemBus] s4_data_i;
    wire s4_we_o;

    // slave 5 interface
    wire[`MemAddrBus] s5_addr_o;
    wire[`MemBus] s5_data_o;
    wire[`MemBus] s5_data_i;
    wire s5_we_o;

    // rib
    wire rib_hold_flag_o_0;

    // jtag0 jtag1

    wire jtag_halt_req_o_0;
    wire jtag_reset_req_o_0;
    wire[`RegAddrBus] jtag_reg_addr_o_0;
    wire[`RegBus] jtag_reg_data_o_0;
    wire jtag_reg_we_o_0;
    wire[`RegBus] jtag_reg_data_i_0;

    
    wire jtag_halt_req_o_1;
    wire jtag_reset_req_o_1;
    wire[`RegAddrBus] jtag_reg_addr_o_1;
    wire[`RegBus] jtag_reg_data_o_1;
    wire jtag_reg_we_o_1;
    wire[`RegBus] jtag_reg_data_i_1;

    // tinyriscv
    wire[`INT_BUS] int_flag_0;
    wire[`INT_BUS] int_flag_1;


    // timer0
    wire timer0_int;

    // gpio
    wire[1:0] io_in;
    wire[31:0] gpio_ctrl;
    wire[31:0] gpio_data;

    assign int_flag_0 = {7'h0, timer0_int};

    // 低电平点亮LED
    // 低电平表示已经halt住CPU
    assign halted_ind = ~jtag_halt_req_o_0;


    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            over <= 1'b1;
            succ <= 1'b1;
        end else begin
            over <= ~u_tinyriscv0.u_regs.regs[26];  // when = 1, run over
            succ <= ~u_tinyriscv0.u_regs.regs[27];  // when = 1, run succ, otherwise fail
        end
    end

    // tinyriscv处理器核模块例化
    tinyriscv u_tinyriscv0(
        .clk(clk),
        .rst(rst),
        .rib_ex_addr_o(m0_addr_i),
        .rib_ex_data_i(m0_data_o),
        .rib_ex_data_o(m0_data_i),
        .rib_ex_req_o(m0_req_i),
        .rib_ex_we_o(m0_we_i),

        .rib_pc_addr_o(m1_addr_i),
        .rib_pc_data_i(m1_data_o),

        .jtag_reg_addr_i(jtag_reg_addr_o_0),
        .jtag_reg_data_i(jtag_reg_data_o_0),
        .jtag_reg_we_i(jtag_reg_we_o_0),
        .jtag_reg_data_o(jtag_reg_data_i_0),

        .rib_hold_flag_i(rib_hold_flag_o_0),
        .jtag_halt_flag_i(jtag_halt_req_o_0),
        .jtag_reset_flag_i(jtag_reset_req_o_0),

        .int_i(int_flag_0)
    );

    tinyriscv u_tinyriscv1(
        .clk(clk),
        .rst(rst),
        .rib_ex_addr_o(m3_addr_i),
        .rib_ex_data_i(m3_data_o),
        .rib_ex_data_o(m3_data_i),
        .rib_ex_req_o(m3_req_i),
        .rib_ex_we_o(m3_we_i),

        .rib_pc_addr_o(m4_addr_i),
        .rib_pc_data_i(m4_data_o),

        .jtag_reg_addr_i(jtag_reg_addr_o_1),
        .jtag_reg_data_i(jtag_reg_data_o_1),
        .jtag_reg_we_i(jtag_reg_we_o_1),
        .jtag_reg_data_o(jtag_reg_data_i_1),

        .rib_hold_flag_i(rib_hold_flag_o_1),
        .jtag_halt_flag_i(jtag_halt_req_o_1),
        .jtag_reset_flag_i(jtag_reset_req_o_1),

        .int_i(int_flag_1)
    );

    // rom模块例化
    rom u_rom(
        .clk(clk),
        .rst(rst),
        .we_i(s0_we_o),
        .addr_i(s0_addr_o),
        .data_i(s0_data_o),
        .data_o(s0_data_i)
    );

    // ram模块例化
    ram u_ram(
        .clk(clk),
        .rst(rst),
        .we_i(s1_we_o),
        .addr_i(s1_addr_o),
        .data_i(s1_data_o),
        .data_o(s1_data_i)
    );

    // timer模块例化
    timer timer_0(
        .clk(clk),
        .rst(rst),
        .data_i(s2_data_o),
        .addr_i(s2_addr_o),
        .we_i(s2_we_o),
        .data_o(s2_data_i),
        .int_sig_o(timer0_int)
    );

    // uart模块例化
    uart uart_0(
        .clk(clk),
        .rst(rst),
        .we_i(s3_we_o),
        .addr_i(s3_addr_o),
        .data_i(s3_data_o),
        .data_o(s3_data_i),
        .tx_pin(uart_tx_pin),
        .rx_pin(uart_rx_pin)
    );

    // io0
    assign gpio[0] = (gpio_ctrl[1:0] == 2'b01)? gpio_data[0]: 1'bz;
    assign io_in[0] = gpio[0];
    // io1
    assign gpio[1] = (gpio_ctrl[3:2] == 2'b01)? gpio_data[1]: 1'bz;
    assign io_in[1] = gpio[1];

    // gpio模块例化
    gpio gpio_0(
        .clk(clk),
        .rst(rst),
        .we_i(s4_we_o),
        .addr_i(s4_addr_o),
        .data_i(s4_data_o),
        .data_o(s4_data_i),
        .io_pin_i(io_in),
        .reg_ctrl(gpio_ctrl),
        .reg_data(gpio_data)
    );

    // spi模块例化
    spi spi_0(
        .clk(clk),
        .rst(rst),
        .data_i(s5_data_o),
        .addr_i(s5_addr_o),
        .we_i(s5_we_o),
        .data_o(s5_data_i),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_ss(spi_ss),
        .spi_clk(spi_clk)
    );

    // rib模块例化
    rib u_rib(
        .clk(clk),
        .rst(rst),

        // master 0 interface
        .m0_addr_i(m0_addr_i),
        .m0_data_i(m0_data_i),
        .m0_data_o(m0_data_o),
        .m0_req_i(m0_req_i),
        .m0_we_i(m0_we_i),

        // master 1 interface
        .m1_addr_i(m1_addr_i),
        .m1_data_i(`ZeroWord),
        .m1_data_o(m1_data_o),
        .m1_req_i(`RIB_REQ),
        .m1_we_i(`WriteDisable),

        // master 2 interface
        .m2_addr_i(m2_addr_i),
        .m2_data_i(m2_data_i),
        .m2_data_o(m2_data_o),
        .m2_req_i(m2_req_i),
        .m2_we_i(m2_we_i),

        // master 3 interface
        .m3_addr_i(m3_addr_i),
        .m3_data_i(m3_data_i),
        .m3_data_o(m3_data_o),
        .m3_req_i(m3_req_i),
        .m3_we_i(m3_we_i),

        // master 4 interface
        .m4_addr_i(m4_addr_i),
        .m4_data_i(`ZeroWord),
        .m4_data_o(m4_data_o),
        .m4_req_i(`RIB_REQ),
        .m4_we_i(`WriteDisable),

        // master 5 interface
        .m5_addr_i(m5_addr_i),
        .m5_data_i(m5_data_i),
        .m5_data_o(m5_data_o),
        .m5_req_i(m5_req_i),
        .m5_we_i(m5_we_i),

        // slave 0 interface
        .s0_addr_o(s0_addr_o),
        .s0_data_o(s0_data_o),
        .s0_data_i(s0_data_i),
        .s0_we_o(s0_we_o),

        // slave 1 interface
        .s1_addr_o(s1_addr_o),
        .s1_data_o(s1_data_o),
        .s1_data_i(s1_data_i),
        .s1_we_o(s1_we_o),

        // slave 2 interface
        .s2_addr_o(s2_addr_o),
        .s2_data_o(s2_data_o),
        .s2_data_i(s2_data_i),
        .s2_we_o(s2_we_o),

        // slave 3 interface
        .s3_addr_o(s3_addr_o),
        .s3_data_o(s3_data_o),
        .s3_data_i(s3_data_i),
        .s3_we_o(s3_we_o),

        // slave 4 interface
        .s4_addr_o(s4_addr_o),
        .s4_data_o(s4_data_o),
        .s4_data_i(s4_data_i),
        .s4_we_o(s4_we_o),

        // slave 5 interface
        .s5_addr_o(s5_addr_o),
        .s5_data_o(s5_data_o),
        .s5_data_i(s5_data_i),
        .s5_we_o(s5_we_o),

        .hold_flag_o(rib_hold_flag_o_0)
    );

    // // 串口下载模块例化
    // uart_debug u_uart_debug(
    //     .clk(clk),
    //     .rst(rst),
    //     .debug_en_i(uart_debug_pin),
    //     .req_o(m3_req_i),
    //     .mem_we_o(m3_we_i),
    //     .mem_addr_o(m3_addr_i),
    //     .mem_wdata_o(m3_data_i),
    //     .mem_rdata_i(m3_data_o)
    // );

    // jtag模块例化
    jtag_top #(
        .DMI_ADDR_BITS(6),
        .DMI_DATA_BITS(32),
        .DMI_OP_BITS(2)
    ) u_jtag_top0(
        .clk(clk),
        .jtag_rst_n(rst),
        .jtag_pin_TCK(jtag_TCK_0),
        .jtag_pin_TMS(jtag_TMS_0),
        .jtag_pin_TDI(jtag_TDI_0),
        .jtag_pin_TDO(jtag_TDO_0),
        .reg_we_o(jtag_reg_we_o_0),
        .reg_addr_o(jtag_reg_addr_o_0),
        .reg_wdata_o(jtag_reg_data_o_0),
        .reg_rdata_i(jtag_reg_data_i_0),
        .mem_we_o(m2_we_i),
        .mem_addr_o(m2_addr_i),
        .mem_wdata_o(m2_data_i),
        .mem_rdata_i(m2_data_o),
        .op_req_o(m2_req_i),
        .halt_req_o(jtag_halt_req_o_0),
        .reset_req_o(jtag_reset_req_o_0)
    );

    jtag_top #(
        .DMI_ADDR_BITS(6),
        .DMI_DATA_BITS(32),
        .DMI_OP_BITS(2)
    ) u_jtag_top1(
        .clk(clk),
        .jtag_rst_n(rst),
        .jtag_pin_TCK(jtag_TCK_1),
        .jtag_pin_TMS(jtag_TMS_1),
        .jtag_pin_TDI(jtag_TDI_1),
        .jtag_pin_TDO(jtag_TDO_1),
        .reg_we_o(jtag_reg_we_o_1),
        .reg_addr_o(jtag_reg_addr_o_1),
        .reg_wdata_o(jtag_reg_data_o_1),
        .reg_rdata_i(jtag_reg_data_i_1),
        .mem_we_o(m5_we_i),
        .mem_addr_o(m5_addr_i),
        .mem_wdata_o(m5_data_i),
        .mem_rdata_i(m5_data_o),
        .op_req_o(m5_req_i),
        .halt_req_o(jtag_halt_req_o_1),
        .reset_req_o(jtag_reset_req_o_1)
    );

endmodule
