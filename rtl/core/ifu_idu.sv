 /*                                                                      
 Copyright 2019 Blue Liang, liangkangnan@163.com
                                                                         
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

`include "defines.sv"

// 将指令信息向译码模块(通过寄存器)传递
module ifu_idu(

    input wire clk,                         // 时钟
    input wire rst_n,                       // 复位

    input wire[`STALL_WIDTH-1:0] stall_i,   // 流水线暂停
    input wire flush_i,                     // 流水线冲刷

    input wire[31:0] inst_i,                // 指令内容
    input wire[31:0] inst_addr_i,           // 指令地址
    input wire inst_valid_i,                // 指令有效

    output wire ready_o,                    // 可以接收指令
    output wire[31:0] inst_o,               // 指令内容
    output wire[31:0] inst_addr_o,          // 指令地址
    output wire inst_valid_o                // 指令有效

    );

    // 使能信号，只要流水线不暂停就传递
    wire en = (~stall_i[`STALL_ID]) | flush_i;

    assign ready_o = en;

    // 指令内容传递，冲刷或指令无效时传递NOP指令
    wire[31:0] i_inst = (flush_i | (~inst_valid_i))? `INST_NOP: inst_i;
    wire[31:0] inst;
    gen_en_dff #(32) inst_ff(clk, rst_n, en, i_inst, inst);
    assign inst_o = inst;

    // 指令地址传递
    wire[31:0] i_inst_addr = flush_i? 32'h0: inst_addr_i;
    wire[31:0] inst_addr;
    gen_en_dff #(32) inst_addr_ff(clk, rst_n, en, i_inst_addr, inst_addr);
    assign inst_addr_o = inst_addr;

    // 指令有效性传递，冲刷时无效
    wire i_inst_valid = flush_i? 1'b0: inst_valid_i;
    wire inst_valid;
    gen_en_dff #(1) inst_valid_ff(clk, rst_n, en, i_inst_valid, inst_valid);
    assign inst_valid_o = inst_valid;

endmodule
