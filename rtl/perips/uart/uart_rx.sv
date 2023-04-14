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

module uart_rx (
    input  logic        clk_i,          // 时钟信号
    input  logic        rst_ni,         // 异步复位信号，低电平有效
    input  logic        enable_i,       // RX模块使能信号
    input  logic        parity_en_i,    // 校验使能
    input  logic        parity_odd_i,   // 奇校验
    input  logic [15:0] div_ratio_i,    // 波特率分频系数
    input  logic        rx_i,           // 来自RX引脚的信号
    output logic        idle_o,         // RX模块空闲
    output logic        err_o,          // 接收出错，帧出错或者校验出错
    output logic [7:0]  rdata_o,        // 接收到的一个字节数据
    output logic        rvalid_o        // 有效接收到一个字节数据
    );

    logic tick;
    logic rx;
    logic rx_start;
    logic clk_div_rst_n_d, clk_div_rst_n_q;
    logic idle_d, idle_q;
    logic rx_valid_d, rx_valid_q;
    logic [10:0] shift_reg_d, shift_reg_q;
    logic [3:0] bit_cnt_d, bit_cnt_q;
    logic [15:0] baud_div_d, baud_div_q;


    always_comb begin
        if (!enable_i) begin
            rx_valid_d = 1'b0;
            shift_reg_d = '0;
            idle_d = 1'b1;
            bit_cnt_d = '0;
            baud_div_d = '0;
            clk_div_rst_n_d = 1'b1;
        end else begin
            rx_valid_d = 1'b0;
            shift_reg_d = shift_reg_q;
            idle_d = idle_q;
            bit_cnt_d = bit_cnt_q;
            baud_div_d = baud_div_q;
            clk_div_rst_n_d = 1'b1;
            if (rx_start & idle_q) begin
                bit_cnt_d = parity_en_i ? 4'd11 : 4'd10;
                shift_reg_d = '0;
                idle_d = 1'b0;
                // 起始位，采中间值
                baud_div_d = {1'b0, div_ratio_i[15:1]};
                clk_div_rst_n_d = 1'b0;
            end else if (tick && (!idle_q)) begin
                shift_reg_d = {rx, shift_reg_q[10:1]};
                bit_cnt_d = bit_cnt_q - 1'b1;
                idle_d = (bit_cnt_q == 4'h1);
                rx_valid_d = (bit_cnt_q == 4'h1);
                baud_div_d = div_ratio_i;
            end
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rx_valid_q <= 1'b0;
            shift_reg_q <= '0;
            idle_q <= 1'b1;
            bit_cnt_q <= '0;
            baud_div_q <= '0;
            clk_div_rst_n_q <= 1'b1;
        end else begin
            rx_valid_q <= rx_valid_d;
            shift_reg_q <= shift_reg_d;
            idle_q <= idle_d;
            bit_cnt_q <= bit_cnt_d;
            baud_div_q <= baud_div_d;
            clk_div_rst_n_q <= clk_div_rst_n_d;
        end
    end

    assign idle_o = idle_q;
    assign rvalid_o = rx_valid_q;
    assign rdata_o = parity_en_i ? shift_reg_q[8:1] : shift_reg_q[9:2];
    assign err_o = rx_valid_q & (~shift_reg_q[10]);

    edge_detect u_edge_detect(
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .sig_i  (rx_i),
        .sig_o  (rx),
        .re_o   (),
        .fe_o   (rx_start)
    );

    clk_div #(
        .RATIO_WIDTH(16)
    ) u_clk_div (
        .clk_i(clk_i),
        .rst_ni(rst_ni || clk_div_rst_n_q),
        .en_i(rx_start || (!idle_q)),
        .ratio_i(baud_div_q),
        .clk_o(tick)
    );

endmodule
