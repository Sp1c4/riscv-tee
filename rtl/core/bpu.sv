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

`include "defines.sv"

// 静态分支预测模块
module bpu(

	input wire clk,
	input wire rst_n,

    input wire[31:0] inst_i,
    input wire inst_valid_i,
    input wire[31:0] pc_i,

    output wire prdt_taken_o,
    output wire[31:0] prdt_addr_o

    );

    wire[6:0] opcode = inst_i[6:0];

    wire opcode_1100011 = (opcode == 7'b1100011);
    wire opcode_1101111 = (opcode == 7'b1101111);

    wire inst_type_branch = opcode_1100011;
    wire inst_jal = opcode_1101111;

    wire[31:0] inst_b_type_imm = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
    wire[31:0] inst_j_type_imm = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};

    wire prdt_taken = (inst_type_branch & inst_b_type_imm[31]) | inst_jal;

    reg[31:0] prdt_imm;

    always @ (*) begin
        prdt_imm = inst_b_type_imm;

        case (1'b1)
            inst_type_branch: prdt_imm = inst_b_type_imm;
            inst_jal:         prdt_imm = inst_j_type_imm;
            default: ;
        endcase
    end

    assign prdt_taken_o = inst_valid_i ? prdt_taken : 1'b0;
    assign prdt_addr_o = pc_i + prdt_imm;

endmodule
