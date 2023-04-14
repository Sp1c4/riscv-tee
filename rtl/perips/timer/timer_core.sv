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

module timer_core (
    input  logic        clk_i,
    input  logic        rst_ni,

    output logic        irq_o,

    input  logic        reg_we_i,
    input  logic        reg_re_i,
    input  logic [31:0] reg_wdata_i,
    input  logic [ 3:0] reg_be_i,
    input  logic [31:0] reg_addr_i,
    output logic [31:0] reg_rdata_o
    );

    import timer_reg_pkg::*;

    timer_reg_pkg::timer_reg2hw_t reg2hw;
    timer_reg_pkg::timer_hw2reg_t hw2reg;

    logic start;
    logic int_en;
    logic int_pending;
    logic mode;
    logic [23:0] div_cont;
    logic [31:0] count_q;
    logic [31:0] value;
    logic tick;

    assign start       = reg2hw.ctrl.en.q;
    assign int_en      = reg2hw.ctrl.int_en.q;
    assign int_pending = reg2hw.ctrl.int_pending.q;
    assign mode        = reg2hw.ctrl.mode.q;
    assign div_cont    = reg2hw.ctrl.clk_div.q;
    assign value       = reg2hw.value.q;

    // 当前计数值
    assign hw2reg.count.d             = count_q;
    assign hw2reg.ctrl.int_pending.d  = 1'b1;
    assign hw2reg.ctrl.int_pending.de = (count_q == value) && int_en && start;

    assign hw2reg.ctrl.en.d  = 1'b0;
    assign hw2reg.ctrl.en.de = (count_q == value) && (mode == 1'b0) && start;

    assign irq_o = int_pending;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count_q <= 32'h0;
        end else begin
            if (start) begin
                if (tick) begin
                    count_q <= count_q + 1'b1;
                    if (count_q == value) begin
                        count_q <= 32'h0;
                    end
                end
            end else begin
                count_q <= 32'h0;
            end
        end
    end

    clk_div #(
        .RATIO_WIDTH(24)
    ) u_clk_div (
        .clk_i(clk_i),
        .rst_ni(rst_ni || (~(count_q == value))),
        .en_i(start),
        .ratio_i(div_cont),
        .clk_o(tick)
    );

    timer_reg_top u_timer_reg_top (
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
