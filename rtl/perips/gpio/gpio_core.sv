 /*                                                                      
 Copyright 2021 Blue Liang, liangkangnan@163.com
                                                                         
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

// 目前最多支持16个GPIO
module gpio_core #(
    parameter int GPIO_NUM = 2
    )(
    input  logic                clk_i,
    input  logic                rst_ni,

    output logic [GPIO_NUM-1:0] gpio_oe_o,
    output logic [GPIO_NUM-1:0] gpio_data_o,
    input  logic [GPIO_NUM-1:0] gpio_data_i,
    output logic                irq_gpio0_o,
    output logic                irq_gpio1_o,
    output logic                irq_gpio2_4_o,
    output logic                irq_gpio5_7_o,
    output logic                irq_gpio8_o,
    output logic                irq_gpio9_o,
    output logic                irq_gpio10_12_o,
    output logic                irq_gpio13_15_o,

    input  logic                reg_we_i,
    input  logic                reg_re_i,
    input  logic [31:0]         reg_wdata_i,
    input  logic [ 3:0]         reg_be_i,
    input  logic [31:0]         reg_addr_i,
    output logic [31:0]         reg_rdata_o
    );

    localparam logic [1:0] INTR_MODE_NONE        = 2'd0;
    localparam logic [1:0] INTR_MODE_RAISE_EDGE  = 2'd1;
    localparam logic [1:0] INTR_MODE_FALL_EDGE   = 2'd2;
    localparam logic [1:0] INTR_MODE_DOUBLE_EDGE = 2'd3;

    localparam logic [1:0] GPIO_MODE_NONE   = 2'd0;
    localparam logic [1:0] GPIO_MODE_INPUT  = 2'd1;
    localparam logic [1:0] GPIO_MODE_OUTPUT = 2'd2;

    import gpio_reg_pkg::*;

    gpio_reg_pkg::gpio_reg2hw_t reg2hw;
    gpio_reg_pkg::gpio_hw2reg_t hw2reg;

    logic [GPIO_NUM-1:0] gpio_oe;
    logic [GPIO_NUM-1:0] gpio_ie;
    logic [GPIO_NUM-1:0] gpio_data;
    logic [GPIO_NUM-1:0] gpio_filter_enable;
    logic [GPIO_NUM-1:0] gpio_filter_data;
    logic [GPIO_NUM-1:0] gpio_raise_detect;
    logic [GPIO_NUM-1:0] gpio_fall_detect;
    logic [GPIO_NUM-1:0] gpio_intr_trigge;

    // 输入滤波使能
    for (genvar i = 0; i < GPIO_NUM; i = i + 1) begin : g_gpio_filter_enable
        assign gpio_filter_enable[i] = reg2hw.filter.q[i];
    end

    // 输出使能
    for (genvar i = 0; i < GPIO_NUM; i = i + 1) begin : g_gpio_oe
        assign gpio_oe[i] = reg2hw.io_mode.q[i*2+1:i*2] == GPIO_MODE_OUTPUT;
    end

    assign gpio_oe_o = gpio_oe;

    // 输出数据
    for (genvar i = 0; i < GPIO_NUM; i = i + 1) begin : g_gpio_data
        assign gpio_data[i] = reg2hw.data.q[i];
    end

    assign gpio_data_o = gpio_data;

    // 输入使能
    for (genvar i = 0; i < GPIO_NUM; i = i + 1) begin : g_gpio_ie
        assign gpio_ie[i] = reg2hw.io_mode.q[i*2+1:i*2] == GPIO_MODE_INPUT;
    end

    // 硬件写data数据
    for (genvar i = 0; i < GPIO_NUM; i = i + 1) begin : g_h2r_data
        assign hw2reg.data.d[i] = gpio_ie[i] ? gpio_filter_data[i] : reg2hw.data.q[i];
    end
    // 硬件写data使能
    assign hw2reg.data.de = |gpio_ie;

    // 中断有效
    for (genvar i = 0; i < GPIO_NUM; i = i + 1) begin : g_gpio_intr_trigge
        assign gpio_intr_trigge[i] = ((reg2hw.int_mode.q[i*2+1:i*2] == INTR_MODE_RAISE_EDGE)  & gpio_raise_detect[i]) |
                                     ((reg2hw.int_mode.q[i*2+1:i*2] == INTR_MODE_FALL_EDGE)   & gpio_fall_detect[i]) |
                                     ((reg2hw.int_mode.q[i*2+1:i*2] == INTR_MODE_DOUBLE_EDGE) & (gpio_raise_detect[i] | gpio_fall_detect[i]));
    end

    // 硬件写中断pending数据
    for (genvar i = 0; i < GPIO_NUM; i = i + 1) begin : g_gpio_intr_pending
        assign hw2reg.int_pending.d[i] = gpio_intr_trigge[i] ? 1'b1 : reg2hw.int_pending.q[i];
    end
    // 硬件写中断pending使能
    assign hw2reg.int_pending.de = |gpio_intr_trigge;

    // 中断输出信号
    if (GPIO_NUM >= 1) begin : g_num_ge_1
        assign irq_gpio0_o   = reg2hw.int_pending.q[0];
    end
    if (GPIO_NUM >= 2) begin : g_num_ge_2
        assign irq_gpio1_o   = reg2hw.int_pending.q[1];
    end
    if (GPIO_NUM >= 5) begin : g_num_ge_5
        assign irq_gpio2_4_o = reg2hw.int_pending.q[2] | reg2hw.int_pending.q[3] | reg2hw.int_pending.q[4];
    end
    if (GPIO_NUM >= 8) begin : g_num_ge_8
        assign irq_gpio5_7_o = reg2hw.int_pending.q[5] | reg2hw.int_pending.q[6] | reg2hw.int_pending.q[7];
    end
    if (GPIO_NUM >= 9) begin : g_num_ge_9
        assign irq_gpio8_o = reg2hw.int_pending.q[8];
    end
    if (GPIO_NUM >= 10) begin : g_num_ge_10
        assign irq_gpio9_o = reg2hw.int_pending.q[9];
    end
    if (GPIO_NUM >= 13) begin : g_num_ge_13
        assign irq_gpio10_12_o = reg2hw.int_pending.q[10] | reg2hw.int_pending.q[11] | reg2hw.int_pending.q[12];
    end
    if (GPIO_NUM >= 16) begin : g_num_ge_16
        assign irq_gpio13_15_o = reg2hw.int_pending.q[13] | reg2hw.int_pending.q[14] | reg2hw.int_pending.q[15];
    end

    // 沿检测
    for (genvar i = 0; i < GPIO_NUM; i = i + 1) begin : g_edge_detect
        edge_detect u_edge_detect(
            .clk_i  (clk_i),
            .rst_ni (rst_ni),
            .sig_i  (gpio_filter_data[i]),
            .sig_o  (),
            .re_o   (gpio_raise_detect[i]),
            .fe_o   (gpio_fall_detect[i])
        );
    end

    // 输入信号滤波
    for (genvar i = 0; i < GPIO_NUM; i = i + 1) begin : g_gpio_filter
        prim_filter #(
            .Cycles(8)
        ) gpio_filter (
            .clk_i      (clk_i),
            .rst_ni     (rst_ni),
            .enable_i   (gpio_filter_enable[i]),
            .filter_i   (gpio_data_i[i]),
            .filter_o   (gpio_filter_data[i])
        );
    end

    gpio_reg_top u_gpio_reg_top (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .reg2hw     (reg2hw),
        .hw2reg     (hw2reg),
        .reg_we     (reg_we_i),
        .reg_re     (reg_re_i),
        .reg_wdata  (reg_wdata_i),
        .reg_be     (reg_be_i),
        .reg_addr   (reg_addr_i),
        .reg_rdata  (reg_rdata_o)
    );

endmodule
