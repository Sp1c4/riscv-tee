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

`include "defines.sv"


module exu_mem(

    input wire clk,
    input wire rst_n,

    input req_mem_i,
    input wire[31:0] mem_addr_i,
    input wire[31:0] mem_rs2_data_i,
    input wire[31:0] mem_rdata_i,
    input wire mem_gnt_i,
    input wire mem_rvalid_i,
    input wire mem_op_lb_i,
    input wire mem_op_lh_i,
    input wire mem_op_lw_i,
    input wire mem_op_lbu_i,
    input wire mem_op_lhu_i,
    input wire mem_op_sb_i,
    input wire mem_op_sh_i,
    input wire mem_op_sw_i,

    output wire mem_access_misaligned_o,
    output wire mem_stall_o,
    output wire[31:0] mem_addr_o,
    output wire[31:0] mem_wdata_o,
    output wire mem_reg_we_o,
    output wire mem_mem_we_o,
    output wire[3:0] mem_be_o,
    output wire mem_req_o

    );


    wire[1:0] mem_addr_index = mem_addr_i[1:0];
    wire mem_addr_index00 = (mem_addr_index == 2'b00);
    wire mem_addr_index01 = (mem_addr_index == 2'b01);
    wire mem_addr_index10 = (mem_addr_index == 2'b10);
    wire mem_addr_index11 = (mem_addr_index == 2'b11);

    assign mem_be_o[0] = mem_addr_index00 | mem_op_sw_i;
    assign mem_be_o[1] = mem_addr_index01 | (mem_op_sh_i & mem_addr_index00) | mem_op_sw_i;
    assign mem_be_o[2] = mem_addr_index10 | mem_op_sw_i;
    assign mem_be_o[3] = mem_addr_index11 | (mem_op_sh_i & mem_addr_index10) | mem_op_sw_i;

    reg[31:0] sb_res;

    always @ (*) begin
        sb_res = 32'h0;
        case (1'b1)
            mem_addr_index00: sb_res = {24'h0, mem_rs2_data_i[7:0]};
            mem_addr_index01: sb_res = {16'h0, mem_rs2_data_i[7:0], 8'h0};
            mem_addr_index10: sb_res = {8'h0, mem_rs2_data_i[7:0], 16'h0};
            mem_addr_index11: sb_res = {mem_rs2_data_i[7:0], 24'h0};
        endcase
    end

    reg[31:0] sh_res;

    always @ (*) begin
        sh_res = 32'h0;
        case (1'b1)
            mem_addr_index00: sh_res = {16'h0, mem_rs2_data_i[15:0]};
            mem_addr_index10: sh_res = {mem_rs2_data_i[15:0], 16'h0};
        endcase
    end

    wire[31:0] sw_res = mem_rs2_data_i;

    reg[31:0] lb_res;

    always @ (*) begin
        lb_res = 32'h0;
        case (1'b1)
            mem_addr_index00: lb_res = {{24{mem_op_lb_i & mem_rdata_i[7]}}, mem_rdata_i[7:0]};
            mem_addr_index01: lb_res = {{24{mem_op_lb_i & mem_rdata_i[15]}}, mem_rdata_i[15:8]};
            mem_addr_index10: lb_res = {{24{mem_op_lb_i & mem_rdata_i[23]}}, mem_rdata_i[23:16]};
            mem_addr_index11: lb_res = {{24{mem_op_lb_i & mem_rdata_i[31]}}, mem_rdata_i[31:24]};
        endcase
    end

    reg[31:0] lh_res;

    always @ (*) begin
        lh_res = 32'h0;
        case (1'b1)
            mem_addr_index00: lh_res = {{24{mem_op_lh_i & mem_rdata_i[15]}}, mem_rdata_i[15:0]};
            mem_addr_index10: lh_res = {{24{mem_op_lh_i & mem_rdata_i[31]}}, mem_rdata_i[31:16]};
        endcase
    end

    wire[31:0] lw_res = mem_rdata_i;

    reg[31:0] mem_wdata;

    always @ (*) begin
        mem_wdata = 32'h0;
        case (1'b1)
            mem_op_sb_i:  mem_wdata = sb_res;
            mem_op_sh_i:  mem_wdata = sh_res;
            mem_op_sw_i:  mem_wdata = sw_res;
            mem_op_lb_i:  mem_wdata = lb_res;
            mem_op_lbu_i: mem_wdata = lb_res;
            mem_op_lh_i:  mem_wdata = lh_res;
            mem_op_lhu_i: mem_wdata = lh_res;
            mem_op_lw_i:  mem_wdata = lw_res;
        endcase
    end

    assign mem_wdata_o = mem_wdata;

    wire op_load = mem_op_lb_i | mem_op_lh_i | mem_op_lw_i | mem_op_lbu_i | mem_op_lhu_i;
    wire op_store = mem_op_sb_i | mem_op_sh_i | mem_op_sw_i;

    localparam S_IDLE       = 3'b001;
    localparam S_WAIT_READ  = 3'b010;
    localparam S_WAIT_WRITE = 3'b100;

    reg[2:0] state_d, state_q;
    reg mem_stall_d;
    reg mem_reg_we_d;
    reg mem_mem_we_d;
    reg req_mem_d;

    // 访存状态机
    always @ (*) begin
        state_d = state_q;

        mem_stall_d = 1'b0;
        mem_reg_we_d = 1'b0;
        mem_mem_we_d = 1'b0;
        req_mem_d = 1'b0;

        case (state_q)
            S_IDLE: begin
                if (req_mem_i) begin
                    mem_stall_d = 1'b1;
                    req_mem_d = 1'b1;
                    if (mem_gnt_i) begin
                        if (op_load) begin
                            state_d = S_WAIT_READ;
                        end else if (op_store) begin
                            state_d = S_WAIT_WRITE;
                            mem_mem_we_d = 1'b1;
                        end
                    end
                end
            end

            // 读内存
            S_WAIT_READ: begin
                mem_stall_d = 1'b1;
                if (mem_rvalid_i) begin
                    state_d = S_IDLE;
                    mem_reg_we_d = 1'b1;
                    mem_stall_d = 1'b0;
                end
            end

            // 写内存
            S_WAIT_WRITE: begin
                mem_stall_d = 1'b1;
                if (mem_rvalid_i) begin
                    state_d = S_IDLE;
                    mem_stall_d = 1'b0;
                end
            end

            default: ;
        endcase
    end

    // 访存请求
    assign mem_req_o  = req_mem_d;
    // 访存地址
    assign mem_addr_o = mem_addr_i;

    // 暂停流水线
    assign mem_stall_o  = mem_stall_d;
    // 写寄存器使能
    assign mem_reg_we_o = mem_reg_we_d;
    // 写内存使能
    assign mem_mem_we_o = mem_mem_we_d;

    assign mem_access_misaligned_o = (mem_op_sw_i | mem_op_lw_i)? (mem_addr_i[0] | mem_addr_i[1]):
                                     (mem_op_sh_i | mem_op_lh_i | mem_op_lhu_i)? mem_addr_i[0]:
                                     0;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= S_IDLE;
        end else begin
            state_q <= state_d;
        end
    end

endmodule
