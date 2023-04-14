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

`define DCSR_CAUSE_NONE         3'h0
`define DCSR_CAUSE_STEP         3'h4
`define DCSR_CAUSE_DBGREQ       3'h3
`define DCSR_CAUSE_EBREAK       3'h1
`define DCSR_CAUSE_HALT         3'h5
`define DCSR_CAUSE_TRIGGER      3'h2


module exception (

    input wire clk,
    input wire rst_n,

    input wire inst_valid_i,
    input wire inst_executed_i,
    input wire inst_ecall_i,                    // ecall指令
    input wire inst_ebreak_i,                   // ebreak指令
    input wire inst_mret_i,                     // mret指令
    input wire inst_dret_i,                     // dret指令
    input wire[31:0] inst_addr_i,               // 指令地址

    input wire illegal_inst_i,                  // 非法指令

    input wire[31:0] mtvec_i,                   // mtvec寄存器
    input wire[31:0] mepc_i,                    // mepc寄存器
    input wire[31:0] mstatus_i,                 // mstatus寄存器
    input wire[31:0] mie_i,                     // mie寄存器
    input wire[31:0] dpc_i,                     // dpc寄存器
    input wire[31:0] dcsr_i,                    // dcsr寄存器

    input wire int_req_i,
    input wire[7:0] int_id_i,

    input wire trigger_match_i,

    input wire[31:0] debug_halt_addr_i,
    input wire debug_req_i,

    output wire csr_we_o,                       // 写CSR寄存器标志
    output wire[31:0] csr_waddr_o,              // 写CSR寄存器地址
    output wire[31:0] csr_wdata_o,              // 写CSR寄存器数据

    output wire stall_flag_o,                   // 流水线暂停标志
    output wire[31:0] int_addr_o,               // 中断入口地址
    output wire int_assert_o                    // 中断标志

    );

    // 异常偏移
    localparam ILLEGAL_INSTR_OFFSET         = 0;
    localparam INSTR_ADDR_MISA_OFFSET       = 4;
    localparam ECALL_OFFSET                 = 8;
    localparam EBREAK_OFFSET                = 12;
    localparam LOAD_MISA_OFFSET             = 16;
    localparam STORE_MISA_OFFSET            = 20;
    localparam RESERVED1_EXCEPTION_OFFSET   = 24;
    localparam RESERVED2_EXCEPTION_OFFSET   = 28;
    // 中断偏移
    localparam INT_OFFSET                   = 32;

    localparam S_IDLE       = 5'b00001;
    localparam S_W_MEPC     = 5'b00010;
    localparam S_W_DCSR     = 5'b00100;
    localparam S_ASSERT     = 5'b01000;
    localparam S_W_MSTATUS  = 5'b10000;

    reg debug_mode_d, debug_mode_q;
    reg[4:0] state_d, state_q;
    reg[31:0] assert_addr_d, assert_addr_q;
    reg[31:0] return_addr_d, return_addr_q;
    reg trigger_match_d, trigger_match_q;
    reg csr_we;
    reg[31:0] csr_waddr;
    reg[31:0] csr_wdata;

    reg[7:0] int_id_d, int_id_q;
    reg in_irq_context_d, in_irq_context_q;
    wire global_int_en;
    wire interrupt_req_valid;

    assign global_int_en = mstatus_i[3];

    assign interrupt_req_valid = inst_valid_i &
                                 int_req_i &
                                 ((int_id_i != int_id_q) | (~in_irq_context_q));

    reg exception_req;
    reg[31:0] exception_cause;

    always @ (*) begin
        if (illegal_inst_i) begin
            exception_req = 1'b1;
            exception_cause = 32'h0;
        end else if (inst_ecall_i & inst_valid_i) begin
            exception_req = 1'b1;
            exception_cause = 32'h2;
        end else begin
            exception_req = 1'b0;
            exception_cause = 32'h0;
        end
    end

    wire int_or_exception_req;
    wire[31:0] int_or_exception_cause;

    assign int_or_exception_req   = (interrupt_req_valid & global_int_en & (~debug_mode_q)) | exception_req;
    assign int_or_exception_cause = exception_req ? exception_cause : (32'h8 + {24'h0, int_id_i});

    wire trigger_matching;

    gen_ticks_sync #(
        .DP(5),
        .DW(1)
    ) gen_trigger_sync (
        .rst_n(rst_n),
        .clk(clk),
        .din(trigger_match_q),
        .dout(trigger_matching)
    );

    reg enter_debug_cause_debugger_req;
    reg enter_debug_cause_single_step;
    reg enter_debug_cause_ebreak;
    reg enter_debug_cause_reset_halt;
    reg enter_debug_cause_trigger;
    reg[2:0] dcsr_cause_d, dcsr_cause_q;

    always @ (*) begin
        enter_debug_cause_debugger_req = 1'b0;
        enter_debug_cause_single_step = 1'b0;
        enter_debug_cause_ebreak = 1'b0;
        enter_debug_cause_reset_halt = 1'b0;
        enter_debug_cause_trigger = 1'b0;
        dcsr_cause_d = `DCSR_CAUSE_NONE;

        if (trigger_match_i & inst_valid_i & (~trigger_matching)) begin
            enter_debug_cause_trigger = 1'b1;
            dcsr_cause_d = `DCSR_CAUSE_TRIGGER;
        end else if (inst_ebreak_i & inst_valid_i) begin
            enter_debug_cause_ebreak = 1'b1;
            dcsr_cause_d = `DCSR_CAUSE_EBREAK;
        end else if ((inst_addr_i == `CPU_RESET_ADDR) & inst_valid_i & debug_req_i) begin
            enter_debug_cause_reset_halt = 1'b1;
            dcsr_cause_d = `DCSR_CAUSE_HALT;
        end else if ((~debug_mode_q) & debug_req_i & inst_valid_i) begin
            enter_debug_cause_debugger_req = 1'b1;
            dcsr_cause_d = `DCSR_CAUSE_DBGREQ;
        end else if ((~debug_mode_q) & dcsr_i[2] & inst_valid_i & inst_executed_i) begin
            enter_debug_cause_single_step = 1'b1;
            dcsr_cause_d = `DCSR_CAUSE_STEP;
        end
    end

    wire debug_mode_req = enter_debug_cause_debugger_req |
                          enter_debug_cause_single_step |
                          enter_debug_cause_reset_halt |
                          enter_debug_cause_trigger |
                          enter_debug_cause_ebreak;

    assign stall_flag_o = ((state_q != S_IDLE) & (state_q != S_ASSERT)) |
                          int_or_exception_req |
                          debug_mode_req |
                          inst_mret_i |
                          inst_dret_i;

    always @ (*) begin
        state_d = state_q;
        assert_addr_d = assert_addr_q;
        debug_mode_d = debug_mode_q;
        return_addr_d = return_addr_q;
        csr_we = 1'b0;
        csr_waddr = 32'h0;
        csr_wdata = 32'h0;
        trigger_match_d = trigger_match_q;
        int_id_d = int_id_q;
        in_irq_context_d = in_irq_context_q;

        case (state_q)
            S_IDLE: begin
                if (int_or_exception_req & (!debug_mode_q)) begin
                    csr_we = 1'b1;
                    csr_waddr = {20'h0, `CSR_MCAUSE};
                    csr_wdata = int_or_exception_cause;
                    assert_addr_d = mtvec_i;
                    return_addr_d = inst_addr_i;
                    state_d = S_W_MSTATUS;
                    int_id_d = int_id_i;
                    in_irq_context_d = 1'b1;
                end else if (debug_mode_req) begin
                    debug_mode_d = 1'b1;
                    if (enter_debug_cause_debugger_req |
                        enter_debug_cause_single_step |
                        enter_debug_cause_trigger |
                        enter_debug_cause_reset_halt) begin
                        csr_we = 1'b1;
                        csr_waddr = {20'h0, `CSR_DPC};
                        csr_wdata = enter_debug_cause_reset_halt ? (`CPU_RESET_ADDR) : inst_addr_i;
                        // when run openocd compliance test, use it.
                        // openocd compliance test bug: It report test fail when the reset address is 0x0:
                        // "NDMRESET should move DPC to reset value."
                        //csr_wdata = enter_debug_cause_reset_halt ? (`CPU_RESET_ADDR + 4'h4) : inst_addr_i;
                    end
                    if (enter_debug_cause_trigger) begin
                        trigger_match_d = 1'b1;
                    end
                    assert_addr_d = debug_halt_addr_i;
                    // ebreak do not change dpc and dcsr value
                    if (enter_debug_cause_ebreak) begin
                        state_d = S_ASSERT;
                    end else begin
                        state_d = S_W_DCSR;
                    end
                end else if (inst_mret_i) begin
                    in_irq_context_d = 1'b0;
                    assert_addr_d = mepc_i;
                    csr_we = 1'b1;
                    csr_waddr = {20'h0, `CSR_MSTATUS};
                    // 开全局中断
                    csr_wdata = {mstatus_i[31:4], 1'b1, mstatus_i[2:0]};
                    state_d = S_ASSERT;
                end else if (inst_dret_i) begin
                    assert_addr_d = dpc_i;
                    state_d = S_ASSERT;
                    debug_mode_d = 1'b0;
                    trigger_match_d = 1'b0;
                end
            end

            S_W_MSTATUS: begin
                csr_we = 1'b1;
                csr_waddr = {20'h0, `CSR_MSTATUS};
                // 关全局中断
                csr_wdata = {mstatus_i[31:4], 1'b0, mstatus_i[2:0]};
                state_d = S_W_MEPC;
            end

            S_W_MEPC: begin
                csr_we = 1'b1;
                csr_waddr = {20'h0, `CSR_MEPC};
                csr_wdata = return_addr_q;
                state_d = S_ASSERT;
            end

            S_W_DCSR: begin
                csr_we = 1'b1;
                csr_waddr = {20'h0, `CSR_DCSR};
                csr_wdata = {dcsr_i[31:9], dcsr_cause_q, dcsr_i[5:0]};
                state_d = S_ASSERT;
            end

            S_ASSERT: begin
                csr_we = 1'b0;
                state_d = S_IDLE;
            end

            default:;

        endcase
    end

    assign csr_we_o = csr_we;
    assign csr_waddr_o = csr_waddr;
    assign csr_wdata_o = csr_wdata;

    assign int_assert_o = (state_q == S_ASSERT);
    assign int_addr_o   = assert_addr_q;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= S_IDLE;
            assert_addr_q <= 32'h0;
            debug_mode_q <= 1'b0;
            return_addr_q <= 32'h0;
            dcsr_cause_q <= `DCSR_CAUSE_NONE;
            trigger_match_q <= 1'b0;
            int_id_q <= 8'h0;
            in_irq_context_q <= 1'b0;
        end else begin
            state_q <= state_d;
            assert_addr_q <= assert_addr_d;
            debug_mode_q <= debug_mode_d;
            return_addr_q <= return_addr_d;
            dcsr_cause_q <= dcsr_cause_d;
            trigger_match_q <= trigger_match_d;
            int_id_q <= int_id_d;
            in_irq_context_q <= in_irq_context_d;
        end
    end

endmodule
