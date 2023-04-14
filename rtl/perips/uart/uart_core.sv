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

module uart_core # (
    parameter int unsigned TX_FIFO_DEPTH = 8,
    parameter int unsigned RX_FIFO_DEPTH = 8
    )(
    input  logic        clk_i,
    input  logic        rst_ni,

    output logic        tx_pin_o,
    input  logic        rx_pin_i,
    output logic        irq_o,

    input  logic        reg_we_i,
    input  logic        reg_re_i,
    input  logic [31:0] reg_wdata_i,
    input  logic [ 3:0] reg_be_i,
    input  logic [31:0] reg_addr_i,
    output logic [31:0] reg_rdata_o
    );

    import uart_reg_pkg::*;

    uart_reg_pkg::uart_reg2hw_t reg2hw;
    uart_reg_pkg::uart_hw2reg_t hw2reg;

    logic tx_enable;
    logic rx_enable;
    logic [15:0] baud_div;
    logic tx_fifo_empty_int_en;
    logic rx_fifo_not_empty_int_en;
    logic tx_fifo_rst;
    logic rx_fifo_rst;
    logic tx_idle;
    logic rx_idle;
    logic rx_error;
    logic tx_fifo_full;
    logic rx_fifo_full;
    logic tx_fifo_empty;
    logic rx_fifo_empty;
    logic tx_we;
    logic [7:0] tx_wdata;
    logic [7:0] rx_rdata;
    logic rx_rvalid;
    logic tx_fifo_pop;
    logic rx_fifo_pop;
    logic tx_fifo_push;
    logic rx_fifo_push;
    logic [7:0] tx_fifo_data_out;
    logic [7:0] rx_fifo_data_out;
    logic [7:0] tx_fifo_data_in;
    logic [7:0] rx_fifo_data_in;

    // 波特率分频系数
    assign baud_div = reg2hw.ctrl.baud_div.q;

    // TX
    assign tx_enable            = reg2hw.ctrl.tx_en.q;
    assign tx_fifo_empty_int_en = reg2hw.ctrl.tx_fifo_empty_int_en.q;
    // 写1清TX fifo
    assign tx_fifo_rst          = reg2hw.ctrl.tx_fifo_rst.qe & reg2hw.ctrl.tx_fifo_rst.q;

    assign hw2reg.status.txidle.d  = tx_enable ? (tx_idle & tx_fifo_empty) : 1'b1;
    assign hw2reg.status.txfull.d  = tx_fifo_full;
    assign hw2reg.status.txempty.d = tx_fifo_empty;

    // TX开始发送数据
    assign tx_we    = tx_enable & (!tx_fifo_empty) & tx_idle;
    // 要发送的数据
    assign tx_wdata = tx_fifo_data_out;
    // 取出fifo数据
    assign tx_fifo_pop     = tx_enable & (!tx_fifo_empty) & tx_idle;
    // 可以先push完数据再使能TX
    assign tx_fifo_push    = reg2hw.txdata.qe & (!tx_fifo_full);
    // 要压入fifo的数据
    assign tx_fifo_data_in = reg2hw.txdata.q;

    // RX
    assign rx_enable                = reg2hw.ctrl.rx_en.q;
    assign rx_fifo_not_empty_int_en = reg2hw.ctrl.rx_fifo_not_empty_int_en.q;
    // 写1清RX fifo
    assign rx_fifo_rst              = reg2hw.ctrl.rx_fifo_rst.qe & reg2hw.ctrl.rx_fifo_rst.q;

    assign hw2reg.status.rxidle.d  = rx_enable ? rx_idle : 1'b1;
    assign hw2reg.status.rxfull.d  = rx_fifo_full;
    assign hw2reg.status.rxempty.d = rx_fifo_empty;
    assign hw2reg.rxdata.d         = rx_fifo_data_out;

    // 将接收到的数据压入fifo
    assign rx_fifo_push    = (~rx_fifo_full) & rx_rvalid;
    // 要压入的数据
    assign rx_fifo_data_in = rx_rdata;
    // 可以在不使能RX的情况下直接读RX fifo里面的数据
    assign rx_fifo_pop     = reg2hw.rxdata.re & (~rx_fifo_empty);

    // 中断信号
    assign irq_o = (tx_enable & tx_fifo_empty_int_en & tx_fifo_empty) |
                   (rx_enable & rx_fifo_not_empty_int_en & (~rx_fifo_empty));

    // TX byte
    uart_tx u_uart_tx (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .enable_i   (tx_enable),
        .parity_en_i(1'b0),
        .parity_i   (1'b1),
        .we_i       (tx_we),
        .wdata_i    (tx_wdata),
        .div_ratio_i(baud_div),
        .idle_o     (tx_idle),
        .tx_bit_o   (tx_pin_o)
    );

    // TX FIFO
    sync_fifo #(
        .DATA_WIDTH(8),
        .DEPTH(TX_FIFO_DEPTH)
    ) u_tx_fifo (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .flush_i    (tx_fifo_rst),
        .testmode_i (1'b0),
        .full_o     (tx_fifo_full),
        .empty_o    (tx_fifo_empty),
        .usage_o    (),
        .data_i     (tx_fifo_data_in),
        .push_i     (tx_fifo_push),
        .data_o     (tx_fifo_data_out),
        .pop_i      (tx_fifo_pop)
    );

    // RX byte
    uart_rx u_uart_rx (
        .clk_i          (clk_i),
        .rst_ni         (rst_ni),
        .enable_i       (rx_enable),
        .parity_en_i    (1'b0),
        .parity_odd_i   (1'b1),
        .div_ratio_i    (baud_div),
        .rx_i           (rx_pin_i),
        .idle_o         (rx_idle),
        .err_o          (rx_error),
        .rdata_o        (rx_rdata),
        .rvalid_o       (rx_rvalid)
    );

    // RX FIFO
    sync_fifo #(
        .DATA_WIDTH(8),
        .DEPTH(RX_FIFO_DEPTH)
    ) u_rx_fifo (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .flush_i    (rx_fifo_rst),
        .testmode_i (1'b0),
        .full_o     (rx_fifo_full),
        .empty_o    (rx_fifo_empty),
        .usage_o    (),
        .data_i     (rx_fifo_data_in),
        .push_i     (rx_fifo_push),
        .data_o     (rx_fifo_data_out),
        .pop_i      (rx_fifo_pop)
    );

    uart_reg_top u_uart_reg_top (
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
