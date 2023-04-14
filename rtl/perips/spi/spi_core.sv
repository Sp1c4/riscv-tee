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

module spi_core #(
    parameter int unsigned TX_FIFO_DEPTH = 8,
    parameter int unsigned RX_FIFO_DEPTH = 8
    )(
    input  logic        clk_i,
    input  logic        rst_ni,

    // SPI引脚信号
    input  logic        spi_clk_i,
    output logic        spi_clk_o,
    output logic        spi_clk_oe_o,
    input  logic        spi_ss_i,
    output logic        spi_ss_o,
    output logic        spi_ss_oe_o,
    input  logic        spi_dq0_i,
    output logic        spi_dq0_o,
    output logic        spi_dq0_oe_o,
    input  logic        spi_dq1_i,
    output logic        spi_dq1_o,
    output logic        spi_dq1_oe_o,
    input  logic        spi_dq2_i,
    output logic        spi_dq2_o,
    output logic        spi_dq2_oe_o,
    input  logic        spi_dq3_i,
    output logic        spi_dq3_o,
    output logic        spi_dq3_oe_o,

    // 中断信号
    output logic        irq_o,

    // OBI总线接口信号
    input  logic        reg_we_i,
    input  logic        reg_re_i,
    input  logic [31:0] reg_wdata_i,
    input  logic [ 3:0] reg_be_i,
    input  logic [31:0] reg_addr_i,
    output logic [31:0] reg_rdata_o
    );

    import spi_reg_pkg::*;

    parameter int unsigned TX_FIFO_ADDR_DEPTH   = (TX_FIFO_DEPTH > 1) ? $clog2(TX_FIFO_DEPTH) : 1;
    parameter int unsigned RX_FIFO_ADDR_DEPTH   = (RX_FIFO_DEPTH > 1) ? $clog2(RX_FIFO_DEPTH) : 1;

    spi_reg_pkg::spi_reg2hw_t reg2hw;
    spi_reg_pkg::spi_hw2reg_t hw2reg;

    logic [TX_FIFO_ADDR_DEPTH-1:0] tx_fifo_usage;
    logic [RX_FIFO_ADDR_DEPTH-1:0] rx_fifo_usage;

    logic master_enable;
    logic master_start;
    logic master_ready, master_ready_re, master_ready_fe;
    logic master_read;
    logic master_msb_first;
    logic master_data_valid, master_data_valid_re;
    logic master_ss_sw_ctrl;
    logic master_ss_level;
    logic busy_q;
    logic [2:0] master_clk_div;
    logic [1:0] master_cp_mode;
    logic [1:0] master_spi_mode;
    logic [3:0] master_ss_delay_cnt;
    logic [7:0] master_data_out;
    logic tx_fifo_full;
    logic tx_fifo_empty;
    logic [7:0] tx_fifo_data_in;
    logic tx_fifo_push;
    logic [7:0] tx_fifo_data_out;
    logic tx_fifo_pop;
    logic tx_fifo_flush;
    logic rx_fifo_full;
    logic rx_fifo_empty;
    logic [7:0] rx_fifo_data_in;
    logic rx_fifo_push;
    logic [7:0] rx_fifo_data_out;
    logic rx_fifo_pop;
    logic rx_fifo_flush;

    assign master_enable        = ~reg2hw.ctrl0.role_mode.q;
    assign master_start         = reg2hw.ctrl0.enable.q && (!tx_fifo_empty);
    assign master_read          = reg2hw.ctrl0.read.q;
    assign master_msb_first     = reg2hw.ctrl0.msb_first.q;
    assign master_clk_div       = reg2hw.ctrl0.clk_div.q;
    assign master_cp_mode       = reg2hw.ctrl0.cp_mode.q;
    assign master_spi_mode      = reg2hw.ctrl0.spi_mode.q;
    assign master_ss_delay_cnt  = reg2hw.ctrl0.ss_delay.q;
    assign master_ss_sw_ctrl    = reg2hw.ctrl0.ss_sw_ctrl.q;
    assign master_ss_level      = reg2hw.ctrl0.ss_level.q;

    assign tx_fifo_push     = reg2hw.txdata.qe;
    assign tx_fifo_data_in  = reg2hw.txdata.q[7:0];
    assign tx_fifo_pop      = master_data_valid_re | master_ready_fe;
    assign tx_fifo_flush    = reg2hw.ctrl0.tx_fifo_reset.q && reg2hw.ctrl0.tx_fifo_reset.qe;
    // 读操作才把接收到的数据压入RX FIFO
    assign rx_fifo_push     = master_data_valid_re & master_read;
    assign rx_fifo_data_in  = master_data_out;
    assign rx_fifo_pop      = reg2hw.rxdata.re;
    assign hw2reg.rxdata.d  = {24'h0, rx_fifo_data_out};
    assign rx_fifo_flush    = reg2hw.ctrl0.rx_fifo_reset.q && reg2hw.ctrl0.rx_fifo_reset.qe;

    assign hw2reg.status.tx_fifo_full.d  = tx_fifo_full;
    assign hw2reg.status.tx_fifo_empty.d = tx_fifo_empty;
    assign hw2reg.status.rx_fifo_full.d  = rx_fifo_full;
    assign hw2reg.status.rx_fifo_empty.d = rx_fifo_empty;
    // 传输完成置位中断pending
    assign hw2reg.ctrl0.int_pending.d   = 1'b1;
    assign hw2reg.ctrl0.int_pending.de  = master_enable & master_ready_re & reg2hw.ctrl0.int_en.q;
    // 传输完成清零busy位
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            busy_q <= 1'b0;
        end else begin
            if (master_start) begin
                busy_q <= 1'b1;
            end else if (master_enable & master_ready_re) begin
                busy_q <= 1'b0;
            end
        end
    end
    assign hw2reg.status.busy.d = busy_q;

    // 中断信号
    assign irq_o = reg2hw.ctrl0.int_pending.q;

    edge_detect #(
        .DP(0)
    ) master_data_valid_ed (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .sig_i(master_data_valid),
        .sig_o(),
        .re_o(master_data_valid_re),
        .fe_o()
    );

    edge_detect #(
        .DP(0)
    ) master_ready_ed (
        .clk_i(clk_i),
        .rst_ni(rst_ni),
        .sig_i(master_ready),
        .sig_o(),
        .re_o(master_ready_re),
        .fe_o(master_ready_fe)
    );

    // TX FIFO
    sync_fifo #(
        .DATA_WIDTH(8),
        .DEPTH(TX_FIFO_DEPTH)
    ) u_tx_fifo (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .flush_i    (tx_fifo_flush),
        .testmode_i (1'b0),
        .full_o     (tx_fifo_full),
        .empty_o    (tx_fifo_empty),
        .usage_o    (tx_fifo_usage),
        .data_i     (tx_fifo_data_in),
        .push_i     (tx_fifo_push),
        .data_o     (tx_fifo_data_out),
        .pop_i      (tx_fifo_pop)
    );

    // RX FIFO
    sync_fifo #(
        .DATA_WIDTH(8),
        .DEPTH(RX_FIFO_DEPTH)
    ) u_rx_fifo (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .flush_i    (rx_fifo_flush),
        .testmode_i (1'b0),
        .full_o     (rx_fifo_full),
        .empty_o    (rx_fifo_empty),
        .usage_o    (rx_fifo_usage),
        .data_i     (rx_fifo_data_in),
        .push_i     (rx_fifo_push),
        .data_o     (rx_fifo_data_out),
        .pop_i      (rx_fifo_pop)
    );

    spi_master u_spi_master (
        .clk_i         (clk_i),
        .rst_ni        (rst_ni),
        .start_i       (master_start),
        .read_i        (master_read),
        .data_i        (tx_fifo_data_out),
        .spi_mode_i    (master_spi_mode),
        .cp_mode_i     (master_cp_mode),
        .div_ratio_i   (master_clk_div),
        .msb_first_i   (master_msb_first),
        .ss_delay_cnt_i(master_ss_delay_cnt),
        .ss_sw_ctrl_i  (master_ss_sw_ctrl),
        .ss_level_i    (master_ss_level),
        .data_o        (master_data_out),
        .ready_o       (master_ready),
        .data_valid_o  (master_data_valid),
        .spi_clk_o     (spi_clk_o),
        .spi_clk_oe_o  (spi_clk_oe_o),
        .spi_ss_o      (spi_ss_o),
        .spi_ss_oe_o   (spi_ss_oe_o),
        .spi_dq0_i     (spi_dq0_i),
        .spi_dq0_o     (spi_dq0_o),
        .spi_dq0_oe_o  (spi_dq0_oe_o),
        .spi_dq1_i     (spi_dq1_i),
        .spi_dq1_o     (spi_dq1_o),
        .spi_dq1_oe_o  (spi_dq1_oe_o),
        .spi_dq2_i     (spi_dq2_i),
        .spi_dq2_o     (spi_dq2_o),
        .spi_dq2_oe_o  (spi_dq2_oe_o),
        .spi_dq3_i     (spi_dq3_i),
        .spi_dq3_o     (spi_dq3_o),
        .spi_dq3_oe_o  (spi_dq3_oe_o)
    );

    spi_reg_top u_spi_reg_top (
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
