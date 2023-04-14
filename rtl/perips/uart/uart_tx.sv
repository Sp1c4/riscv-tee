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

module uart_tx (
    input  logic        clk_i,          // 时钟输入
    input  logic        rst_ni,         // 异步复位信号，低电平有效
    input  logic        enable_i,       // TX模块使能信号
    input  logic        parity_en_i,    // 校验使能
    input  logic        parity_i,       // 校验方式：奇校验还是偶检验
    input  logic        we_i,           // 开始发送数据
    input  logic [7:0]  wdata_i,        // 要发送的一个字节数据
    input  logic [15:0] div_ratio_i,    // 波特率分频系数
    output logic        idle_o,         // TX模块空闲
    output logic        tx_bit_o        // 要发送的1 bit数据
    );

    logic [3:0]  bit_cnt_d, bit_cnt_q;
    logic [10:0] shift_reg_d, shift_reg_q;
    logic tx_d, tx_q;
    logic tick;

    always_comb begin
        if (!enable_i) begin
            bit_cnt_d = 4'h0;
            shift_reg_d = 11'h7ff;
            tx_d = 1'b1;
        end else begin
            bit_cnt_d = bit_cnt_q;
            shift_reg_d = shift_reg_q;
            tx_d = tx_q;
            if (we_i) begin
                // LSB first
                shift_reg_d = {1'b1, (parity_en_i ? parity_i : 1'b1), wdata_i, 1'b0};
                bit_cnt_d = (parity_en_i ? 4'd11 : 4'd10);
            end else if ((bit_cnt_q != 4'h0) && tick) begin
                // 右移1位
                shift_reg_d = {1'b1, shift_reg_q[10:1]};
                tx_d = shift_reg_q[0];
                bit_cnt_d = bit_cnt_q - 4'h1;
            end
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bit_cnt_q <= 4'h0;
            shift_reg_q <= 11'h7ff;
            tx_q <= 1'b1;
        end else begin
            bit_cnt_q <= bit_cnt_d;
            shift_reg_q <= shift_reg_d;
            tx_q <= tx_d;
        end
    end

    assign idle_o = (bit_cnt_q == 4'h0);
    assign tx_bit_o = tx_q;

    clk_div #(
        .RATIO_WIDTH(16)
    ) u_clk_div (
        .clk_i(clk_i),
        .rst_ni(rst_ni || (~we_i)),
        .en_i(we_i || (bit_cnt_q != 4'h0)),
        .ratio_i(div_ratio_i),
        .clk_o(tick)
    );

endmodule
