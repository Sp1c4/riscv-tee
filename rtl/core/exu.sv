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

// 执行模块
module exu #(
    parameter bit          BranchPredictor      = 1'b1
    )(
    input wire clk,                         // 时钟
    input wire rst_n,                       // 复位

    // exception
    input wire int_assert_i,                // 中断发生标志
    input wire[31:0] int_addr_i,            // 中断跳转地址
    input wire int_stall_i,                 // 暂停标志
    output wire inst_ecall_o,               // ecall指令
    output wire inst_ebreak_o,              // ebreak指令
    output wire inst_mret_o,                // mret指令
    output wire inst_dret_o,                // dret指令

    // mem
    input wire[31:0] mem_rdata_i,           // 内存输入数据
    input wire mem_gnt_i,                   // 总线授权
    input wire mem_rvalid_i,                // 总线响应
    output wire[31:0] mem_wdata_o,          // 写内存数据
    output wire[31:0] mem_addr_o,           // 读、写内存地址
    output wire mem_we_o,                   // 是否要写内存
    output wire[3:0] mem_be_o,              // 字节位
    output wire mem_req_o,                  // 访存请求
    output wire mem_access_misaligned_o,    // 访存不对齐

    // to gpr_reg
    output wire[31:0] reg_wdata_o,          // 写寄存器数据
    output wire reg_we_o,                   // 是否要写通用寄存器
    output wire[4:0] reg_waddr_o,           // 写通用寄存器地址

    // csr_reg
    input wire[31:0] csr_rdata_i,           // CSR寄存器数据
    output wire[31:0] csr_raddr_o,          // 读CSR寄存器地址
    output wire[31:0] csr_wdata_o,          // 写CSR寄存器数据
    output wire csr_we_o,                   // 是否要写CSR寄存器
    output wire[31:0] csr_waddr_o,          // 写CSR寄存器地址

    // to pipe_ctrl
    output wire hold_flag_o,                // 是否暂停标志
    output wire jump_flag_o,                // 是否跳转标志
    output wire[31:0] jump_addr_o,          // 跳转目的地址

    //
    output wire inst_valid_o,               // 指令有效
    output wire inst_executed_o,            // 指令已经执行完毕

    // from idu_exu
    input wire inst_valid_i,
    input wire[31:0] inst_i,
    input wire[`DECINFO_WIDTH-1:0] dec_info_bus_i,
    input wire[31:0] dec_imm_i,
    input wire[31:0] dec_pc_i,
    input wire[31:0] next_pc_i,
    input wire[4:0] rd_waddr_i,
    input wire[31:0] reg1_rdata_i,          // 通用寄存器1输入数据
    input wire[31:0] reg2_rdata_i,          // 通用寄存器2输入数据
    input wire rd_we_i

    );

    wire[31:0] next_pc = dec_pc_i + 4'h4;

    // dispatch to ALU
    wire[31:0] alu_op1_o;
    wire[31:0] alu_op2_o;
    wire req_alu_o;
    wire alu_op_lui_o;
    wire alu_op_auipc_o;
    wire alu_op_add_o;
    wire alu_op_sub_o;
    wire alu_op_sll_o;
    wire alu_op_slt_o;
    wire alu_op_sltu_o;
    wire alu_op_xor_o;
    wire alu_op_srl_o;
    wire alu_op_sra_o;
    wire alu_op_or_o;
    wire alu_op_and_o;
    // dispatch to BJP
    wire[31:0] bjp_op1_o;
    wire[31:0] bjp_op2_o;
    wire[31:0] bjp_jump_op1_o;
    wire[31:0] bjp_jump_op2_o;
    wire req_bjp_o;
    wire bjp_op_jump_o;
    wire bjp_op_beq_o;
    wire bjp_op_bne_o;
    wire bjp_op_blt_o;
    wire bjp_op_bltu_o;
    wire bjp_op_bge_o;
    wire bjp_op_bgeu_o;
    wire bjp_op_jalr_o;
    // dispatch to MULDIV
    wire req_muldiv_o;
    wire[31:0] muldiv_op1_o;
    wire[31:0] muldiv_op2_o;
    wire muldiv_op_mul_o;
    wire muldiv_op_mulh_o;
    wire muldiv_op_mulhsu_o;
    wire muldiv_op_mulhu_o;
    wire muldiv_op_div_o;
    wire muldiv_op_divu_o;
    wire muldiv_op_rem_o;
    wire muldiv_op_remu_o;
    // dispatch to CSR
    wire req_csr_o;
    wire[31:0] csr_op1_o;
    wire[31:0] csr_addr_o;
    wire csr_csrrw_o;
    wire csr_csrrs_o;
    wire csr_csrrc_o;
    // dispatch to MEM
    wire req_mem_o;
    wire[31:0] mem_op1_o;
    wire[31:0] mem_op2_o;
    wire[31:0] mem_rs2_data_o;
    wire mem_op_lb_o;
    wire mem_op_lh_o;
    wire mem_op_lw_o;
    wire mem_op_lbu_o;
    wire mem_op_lhu_o;
    wire mem_op_sb_o;
    wire mem_op_sh_o;
    wire mem_op_sw_o;
    // dispatch to SYS
    wire sys_op_nop_o;
    wire sys_op_mret_o;
    wire sys_op_ecall_o;
    wire sys_op_ebreak_o;
    wire sys_op_fence_o;
    wire sys_op_dret_o;

    exu_dispatch u_exu_dispatch(
        // input
        .clk(clk),
        .rst_n(rst_n),
        .dec_info_bus_i(dec_info_bus_i),
        .dec_imm_i(dec_imm_i),
        .dec_pc_i(dec_pc_i),
        .rs1_rdata_i(reg1_rdata_i),
        .rs2_rdata_i(reg2_rdata_i),
        // dispatch to ALU
        .alu_op1_o(alu_op1_o),
        .alu_op2_o(alu_op2_o),
        .req_alu_o(req_alu_o),
        .alu_op_lui_o(alu_op_lui_o),
        .alu_op_auipc_o(alu_op_auipc_o),
        .alu_op_add_o(alu_op_add_o),
        .alu_op_sub_o(alu_op_sub_o),
        .alu_op_sll_o(alu_op_sll_o),
        .alu_op_slt_o(alu_op_slt_o),
        .alu_op_sltu_o(alu_op_sltu_o),
        .alu_op_xor_o(alu_op_xor_o),
        .alu_op_srl_o(alu_op_srl_o),
        .alu_op_sra_o(alu_op_sra_o),
        .alu_op_or_o(alu_op_or_o),
        .alu_op_and_o(alu_op_and_o),
        // dispatch to BJP
        .bjp_op1_o(bjp_op1_o),
        .bjp_op2_o(bjp_op2_o),
        .bjp_jump_op1_o(bjp_jump_op1_o),
        .bjp_jump_op2_o(bjp_jump_op2_o),
        .req_bjp_o(req_bjp_o),
        .bjp_op_jump_o(bjp_op_jump_o),
        .bjp_op_beq_o(bjp_op_beq_o),
        .bjp_op_bne_o(bjp_op_bne_o),
        .bjp_op_blt_o(bjp_op_blt_o),
        .bjp_op_bltu_o(bjp_op_bltu_o),
        .bjp_op_bge_o(bjp_op_bge_o),
        .bjp_op_bgeu_o(bjp_op_bgeu_o),
        .bjp_op_jalr_o(bjp_op_jalr_o),
        // dispatch to MULDIV
        .req_muldiv_o(req_muldiv_o),
        .muldiv_op1_o(muldiv_op1_o),
        .muldiv_op2_o(muldiv_op2_o),
        .muldiv_op_mul_o(muldiv_op_mul_o),
        .muldiv_op_mulh_o(muldiv_op_mulh_o),
        .muldiv_op_mulhsu_o(muldiv_op_mulhsu_o),
        .muldiv_op_mulhu_o(muldiv_op_mulhu_o),
        .muldiv_op_div_o(muldiv_op_div_o),
        .muldiv_op_divu_o(muldiv_op_divu_o),
        .muldiv_op_rem_o(muldiv_op_rem_o),
        .muldiv_op_remu_o(muldiv_op_remu_o),
        // dispatch to CSR
        .req_csr_o(req_csr_o),
        .csr_op1_o(csr_op1_o),
        .csr_addr_o(csr_addr_o),
        .csr_csrrw_o(csr_csrrw_o),
        .csr_csrrs_o(csr_csrrs_o),
        .csr_csrrc_o(csr_csrrc_o),
        // dispatch to MEM
        .req_mem_o(req_mem_o),
        .mem_op1_o(mem_op1_o),
        .mem_op2_o(mem_op2_o),
        .mem_rs2_data_o(mem_rs2_data_o),
        .mem_op_lb_o(mem_op_lb_o),
        .mem_op_lh_o(mem_op_lh_o),
        .mem_op_lw_o(mem_op_lw_o),
        .mem_op_lbu_o(mem_op_lbu_o),
        .mem_op_lhu_o(mem_op_lhu_o),
        .mem_op_sb_o(mem_op_sb_o),
        .mem_op_sh_o(mem_op_sh_o),
        .mem_op_sw_o(mem_op_sw_o),
        // dispatch to SYS
        .sys_op_nop_o(sys_op_nop_o),
        .sys_op_mret_o(sys_op_mret_o),
        .sys_op_ecall_o(sys_op_ecall_o),
        .sys_op_ebreak_o(sys_op_ebreak_o),
        .sys_op_fence_o(sys_op_fence_o),
        .sys_op_dret_o(sys_op_dret_o)
    );

    assign inst_ecall_o = sys_op_ecall_o;
    assign inst_ebreak_o = sys_op_ebreak_o;
    assign inst_mret_o = sys_op_mret_o;
    assign inst_dret_o = sys_op_dret_o;

    wire[31:0] alu_res_o;
    wire[31:0] bjp_res_o;
    wire bjp_cmp_res_o;
    wire[31:0] csr_op1 = csr_csrrc_o? (~csr_op1_o): csr_op1_o;
    wire[31:0] csr_op2 = csr_csrrw_o? (32'h0): csr_rdata_i;

    exu_alu_datapath u_exu_alu_datapath(
        .clk(clk),
        .rst_n(rst_n),
        // ALU
        .req_alu_i(req_alu_o),
        .alu_op1_i(alu_op1_o),
        .alu_op2_i(alu_op2_o),
        .alu_op_add_i(alu_op_add_o | alu_op_lui_o | alu_op_auipc_o),
        .alu_op_sub_i(alu_op_sub_o),
        .alu_op_sll_i(alu_op_sll_o),
        .alu_op_slt_i(alu_op_slt_o),
        .alu_op_sltu_i(alu_op_sltu_o),
        .alu_op_xor_i(alu_op_xor_o),
        .alu_op_srl_i(alu_op_srl_o),
        .alu_op_sra_i(alu_op_sra_o),
        .alu_op_or_i(alu_op_or_o),
        .alu_op_and_i(alu_op_and_o),
        // BJP
        .req_bjp_i(req_bjp_o),
        .bjp_op1_i(bjp_op1_o),
        .bjp_op2_i(bjp_op2_o),
        .bjp_op_beq_i(bjp_op_beq_o),
        .bjp_op_bne_i(bjp_op_bne_o),
        .bjp_op_blt_i(bjp_op_blt_o),
        .bjp_op_bltu_i(bjp_op_bltu_o),
        .bjp_op_bge_i(bjp_op_bge_o),
        .bjp_op_bgeu_i(bjp_op_bgeu_o),
        .bjp_op_jump_i(bjp_op_jump_o),
        .bjp_jump_op1_i(bjp_jump_op1_o),
        .bjp_jump_op2_i(bjp_jump_op2_o),
        // MEM
        .req_mem_i(req_mem_o),
        .mem_op1_i(mem_op1_o),
        .mem_op2_i(mem_op2_o),
        // CSR
        .req_csr_i(req_csr_o),
        .csr_op1_i(csr_op1),
        .csr_op2_i(csr_op2),
        .csr_csrrw_i(csr_csrrw_o),
        .csr_csrrs_i(csr_csrrs_o),
        .csr_csrrc_i(csr_csrrc_o),

        .alu_res_o(alu_res_o),
        .bjp_res_o(bjp_res_o),
        .bjp_cmp_res_o(bjp_cmp_res_o)
    );

    wire mem_reg_we_o;
    wire mem_mem_we_o;
    wire[31:0] mem_wdata;
    wire mem_stall_o;

    exu_mem u_exu_mem(
        .clk(clk),
        .rst_n(rst_n),
        .req_mem_i(req_mem_o),
        .mem_addr_i(alu_res_o),
        .mem_rs2_data_i(mem_rs2_data_o),
        .mem_gnt_i(mem_gnt_i),
        .mem_rvalid_i(mem_rvalid_i),
        .mem_rdata_i(mem_rdata_i),
        .mem_op_lb_i(mem_op_lb_o),
        .mem_op_lh_i(mem_op_lh_o),
        .mem_op_lw_i(mem_op_lw_o),
        .mem_op_lbu_i(mem_op_lbu_o),
        .mem_op_lhu_i(mem_op_lhu_o),
        .mem_op_sb_i(mem_op_sb_o),
        .mem_op_sh_i(mem_op_sh_o),
        .mem_op_sw_i(mem_op_sw_o),
        .mem_access_misaligned_o(mem_access_misaligned_o),
        .mem_stall_o(mem_stall_o),
        .mem_addr_o(mem_addr_o),
        .mem_wdata_o(mem_wdata),
        .mem_reg_we_o(mem_reg_we_o),
        .mem_mem_we_o(mem_mem_we_o),
        .mem_be_o(mem_be_o),
        .mem_req_o(mem_req_o)
    );

    wire[31:0] muldiv_reg_wdata_o;
    wire muldiv_reg_we_o;
    wire muldiv_stall_o;

    exu_muldiv u_exu_muldiv(
        .clk(clk),
        .rst_n(rst_n),
        .muldiv_op1_i(muldiv_op1_o),
        .muldiv_op2_i(muldiv_op2_o),
        .muldiv_op_mul_i(muldiv_op_mul_o),
        .muldiv_op_mulh_i(muldiv_op_mulh_o),
        .muldiv_op_mulhsu_i(muldiv_op_mulhsu_o),
        .muldiv_op_mulhu_i(muldiv_op_mulhu_o),
        .muldiv_op_div_i(muldiv_op_div_o),
        .muldiv_op_divu_i(muldiv_op_divu_o),
        .muldiv_op_rem_i(muldiv_op_rem_o),
        .muldiv_op_remu_i(muldiv_op_remu_o),
        .int_stall_i(int_stall_i),
        .muldiv_reg_wdata_o(muldiv_reg_wdata_o),
        .muldiv_reg_we_o(muldiv_reg_we_o),
        .muldiv_stall_o(muldiv_stall_o)
    );

    wire commit_reg_we_o;

    exu_commit u_exu_commit(
        .clk(clk),
        .rst_n(rst_n),
        .req_muldiv_i(req_muldiv_o),
        .muldiv_reg_we_i(muldiv_reg_we_o),
        .muldiv_reg_waddr_i(rd_waddr_i),
        .muldiv_reg_wdata_i(muldiv_reg_wdata_o),
        .req_mem_i(req_mem_o),
        .mem_reg_we_i(mem_reg_we_o),
        .mem_reg_waddr_i(rd_waddr_i),
        .mem_reg_wdata_i(mem_wdata),
        .req_csr_i(req_csr_o),
        .csr_reg_we_i(req_csr_o),
        .csr_reg_waddr_i(rd_waddr_i),
        .csr_reg_wdata_i(csr_rdata_i),
        .req_bjp_i(req_bjp_o),
        .bjp_reg_we_i(bjp_op_jump_o),
        .bjp_reg_wdata_i(next_pc),
        .bjp_reg_waddr_i(rd_waddr_i),
        .rd_we_i(rd_we_i),
        .rd_waddr_i(rd_waddr_i),
        .alu_reg_wdata_i(alu_res_o),
        .reg_we_o(commit_reg_we_o),
        .reg_waddr_o(reg_waddr_o),
        .reg_wdata_o(reg_wdata_o)
    );

    assign reg_we_o = commit_reg_we_o & (~int_stall_i);

    wire prdt_taken;

    if (BranchPredictor) begin: g_branch_predictor
                            // jal
        assign prdt_taken = ((~bjp_op_jalr_o) & bjp_op_jump_o) |
                            // bxx & imm[31]
                            (req_bjp_o & (~bjp_op_jump_o) & dec_imm_i[31]);
    end else begin: g_no_branch_predictor
        assign prdt_taken = 1'b0;
    end

    // bxx分支预测错误
    wire prdt_taken_error = prdt_taken & (~bjp_cmp_res_o) & req_bjp_o & (~bjp_op_jump_o);

    wire inst_jump = (bjp_cmp_res_o & (~prdt_taken)) |
                     (bjp_op_jump_o & (~prdt_taken)) |
                     sys_op_fence_o;
    assign jump_flag_o = ((inst_jump | prdt_taken_error) & (~int_stall_i)) | int_assert_i;
    assign jump_addr_o = int_assert_i? int_addr_i:
                         sys_op_fence_o? next_pc:
                         prdt_taken_error? next_pc:
                         bjp_res_o;
    assign hold_flag_o = muldiv_stall_o | mem_stall_o;

    assign csr_raddr_o = csr_addr_o;
    assign csr_waddr_o = csr_addr_o;
    assign csr_we_o = req_csr_o & (~int_stall_i);
    assign csr_wdata_o = alu_res_o;

    assign mem_we_o = mem_mem_we_o & (~int_stall_i);
    assign mem_wdata_o = mem_wdata;

    assign inst_valid_o = hold_flag_o? 1'b0: inst_valid_i;

    reg inst_executed_q;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inst_executed_q <= 1'b0;
        end else begin
            if (inst_valid_i) begin
                inst_executed_q <= (inst_jump & (~int_stall_i)) |
                                   reg_we_o |
                                   csr_we_o |
                                   mem_we_o;
            end
        end
    end

    assign inst_executed_o = inst_executed_q;

endmodule
