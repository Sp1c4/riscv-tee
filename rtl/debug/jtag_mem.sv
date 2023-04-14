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

`include "jtag_def.sv"

module jtag_mem(

    input wire                           clk,
    input wire                           rst_n,

    output wire                          halted_o,
    output wire                          resumeack_o,
    input  wire                          clear_resumeack_i,
    input  wire                          resumereq_i,
    input  wire                          haltreq_i,
    input  wire                          ndmreset_i,

    input  wire [`ProgBufSize-1:0][31:0] progbuf_i,
    input  wire [31:0]                   data_i,
    output wire [31:0]                   data_o,
    output wire                          data_valid_o,
    input  wire                          cmd_valid_i,
    input  wire [31:0]                   cmd_i,
    output wire                          cmderror_valid_o,
    output wire [2:0]                    cmderror_o,
    output wire                          cmdbusy_o,

    input  wire                          req_i,
    input  wire                          we_i,
    input  wire [31:0]                   addr_i,
    input  wire [3:0]                    be_i,
    input  wire [31:0]                   wdata_i,
    output wire                          gnt_o,
    output wire                          rvalid_o,
    output wire [31:0]                   rdata_o

    );

    // 16KB
    localparam DbgAddressBits       = 12;
    // x10/a0
    localparam LoadBaseAddr         = 5'd10;

    localparam Data0Addr            = `DataBaseAddr;
    localparam Data1Addr            = `DataBaseAddr + 4;
    localparam Data2Addr            = `DataBaseAddr + 8;
    localparam Data3Addr            = `DataBaseAddr + 12;
    localparam Data4Addr            = `DataBaseAddr + 16;

    localparam Progbuf0Addr         = `ProgbufBaseAddr;
    localparam Progbuf1Addr         = `ProgbufBaseAddr + 4;
    localparam Progbuf2Addr         = `ProgbufBaseAddr + 8;
    localparam Progbuf3Addr         = `ProgbufBaseAddr + 12;
    localparam Progbuf4Addr         = `ProgbufBaseAddr + 16;
    localparam Progbuf5Addr         = `ProgbufBaseAddr + 20;
    localparam Progbuf6Addr         = `ProgbufBaseAddr + 24;
    localparam Progbuf7Addr         = `ProgbufBaseAddr + 28;
    localparam Progbuf8Addr         = `ProgbufBaseAddr + 32;
    localparam Progbuf9Addr         = `ProgbufBaseAddr + 36;

    localparam AbstractCmd0Addr     = `AbstCmdBaseAddr;
    localparam AbstractCmd1Addr     = `AbstCmdBaseAddr + 4;
    localparam AbstractCmd2Addr     = `AbstCmdBaseAddr + 8;
    localparam AbstractCmd3Addr     = `AbstCmdBaseAddr + 12;
    localparam AbstractCmd4Addr     = `AbstCmdBaseAddr + 16;
    localparam AbstractCmd5Addr     = `AbstCmdBaseAddr + 20;
    localparam AbstractCmd6Addr     = `AbstCmdBaseAddr + 24;
    localparam AbstractCmd7Addr     = `AbstCmdBaseAddr + 28;
    localparam AbstractCmd8Addr     = `AbstCmdBaseAddr + 32;
    localparam AbstractCmd9Addr     = `AbstCmdBaseAddr + 36;

    localparam WhereToAddr          = 12'h300;
    localparam FlagsBaseAddr        = 12'h400;
    localparam FlagsEndAddr         = 12'h7FF;

    localparam HaltedAddr           = 12'h100;
    localparam GoingAddr            = 12'h104;
    localparam ResumingAddr         = 12'h108;
    localparam ExceptionAddr        = 12'h10C;

    localparam CmdAccessRegister    = 8'h0;
    localparam CmdQuickAccess       = 8'h1;
    localparam CmdAccessMemory      = 8'h2;

    localparam CmdErrorNone         = 3'h0;
    localparam CmdErrorHaltResume   = 3'h4;
    localparam CmdErrorNotSupport   = 3'h2;
    localparam CmdErrorException    = 3'h3;

    localparam illegal              = 32'h00000000;
    localparam nop                  = 32'h00000013;
    localparam ebreak               = 32'h00100073;

    localparam S_IDLE               = 4'b0001;
    localparam S_RESUME             = 4'b0010;
    localparam S_GO                 = 4'b0100;
    localparam S_CMD_EXECUTING      = 4'b1000;


    function automatic [31:0] jal;
        input [4:0] rd;
        input [20:0] imm;

        jal = {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'h6f};
    endfunction

    function automatic [31:0] slli;
        input [4:0] rd;
        input [4:0] rs1;
        input [5:0] shamt;

        slli = {6'b0, shamt[5:0], rs1, 3'h1, rd, 7'h13};
    endfunction

    function automatic [31:0] srli;
        input [4:0] rd;
        input [4:0] rs1;
        input [5:0] shamt;

        srli = {6'b0, shamt[5:0], rs1, 3'h5, rd, 7'h13};
    endfunction

    function automatic [31:0] load;
        input [2:0]  size;
        input [4:0]  dest;
        input [4:0]  base;
        input [11:0] offset;

        load = {offset[11:0], base, size, dest, 7'h03};
    endfunction

    function automatic [31:0] auipc;
        input [4:0]  rd;
        input [20:0] imm;

        auipc = {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'h17};
    endfunction

    function automatic [31:0] store;
        input [2:0]  size;
        input [4:0]  src;
        input [4:0]  base;
        input [11:0] offset;

        store = {offset[11:5], src, base, size, offset[4:0], 7'h23};
    endfunction

    function automatic [31:0] csrw;
        input [11:0] csr;
        input [4:0] rs1;

        csrw = {csr, rs1, 3'h1, 5'h0, 7'h73};
    endfunction

    function automatic [31:0] csrr;
        input [11:0] csr;
        input [4:0] dest;

        csrr = {csr, 5'h0, 3'h2, dest, 7'h73};
    endfunction


    reg[3:0] state_d, state_q;
    reg[31:0] rdata_d, rdata_q;
    reg halted_d, halted_q;
    reg resuming_d, resuming_q;
    reg resume, go, going;
    reg fwd_rom_q;
    reg data_valid;
    reg cmdbusy;
    reg halted_aligned;
    reg rvalid_q;
    wire fwd_rom_d;
    wire[31:0] rom_rdata;
    reg[31:0] data_bits;
    reg[9:0][31:0] abstract_cmd;
    reg unsupported_command;
    reg cmderror_valid;
    reg[2:0] cmderror;
    reg exception;
    wire[11:0] progbuf_baseaddr = Progbuf0Addr;
    wire[11:0] abstractcmd_baseaddr = AbstractCmd0Addr;
    wire[7:0] cmd_type = cmd_i[31:24];
    wire cmd_postexec = cmd_i[18];
    wire cmd_transfer = cmd_i[17];
    wire cmd_write = cmd_i[16];
    wire[15:0] cmd_regno = cmd_i[15:0];
    wire[2:0] cmd_aarsize = cmd_i[22:20];
    wire cmd_aarpostincrement = cmd_i[19];

    wire[31:0] word_mux;
    assign word_mux = fwd_rom_q ? rom_rdata : rdata_q;
    assign rdata_o = word_mux;

    assign halted_o = halted_q;
    assign resumeack_o = resuming_q;
    assign gnt_o = req_i;
    assign rvalid_o = rvalid_q;

    always @ (*) begin
        state_d = state_q;
        resume = 1'b0;
        go = 1'b0;
        cmdbusy = 1'b1;
        cmderror_valid = 1'b0;
        cmderror = CmdErrorNone;

        case (state_q)
            S_IDLE: begin
                cmdbusy = 1'b0;
                if (resumereq_i && (!resuming_q) &&
                    halted_q && (!haltreq_i)) begin
                    state_d = S_RESUME;
                end
                if (cmd_valid_i) begin
                    if (!halted_q) begin
                        cmderror_valid = 1'b1;
                        cmderror = CmdErrorHaltResume;
                    end else if (unsupported_command) begin
                        cmderror_valid = 1'b1;
                        cmderror = CmdErrorNotSupport;
                    end else begin
                        state_d = S_GO;
                    end
                end
            end

            S_GO: begin
                cmdbusy = 1'b1;
                go = 1'b1;
                if (going) begin
                    state_d = S_CMD_EXECUTING;
                end
            end

            S_RESUME: begin
                resume = 1'b1;
                cmdbusy = 1'b1;
                if (resuming_q) begin
                    state_d = S_IDLE;
                end
            end

            S_CMD_EXECUTING: begin
                cmdbusy = 1'b1;
                go = 1'b0;
                if (halted_aligned) begin
                    state_d = S_IDLE;
                end
            end

            default:;
        endcase

        if (exception) begin
            cmderror_valid = 1'b1;
            cmderror = CmdErrorException;
        end
    end

    assign cmderror_valid_o = cmderror_valid;
    assign cmderror_o = cmderror;
    assign cmdbusy_o = cmdbusy;

    always @ (*) begin
        rdata_d = rdata_q;
        halted_d = halted_q;
        resuming_d = resuming_q;

        going = 1'b0;
        exception = 1'b0;
        halted_aligned = 1'b0;

        data_valid = 1'b0;
        data_bits = data_i;

        if (clear_resumeack_i) begin
            resuming_d = 1'b0;
        end

        if (ndmreset_i & (!haltreq_i)) begin
            halted_d = 1'b0;
        end

        // write
        if (req_i & we_i) begin
            case (addr_i[DbgAddressBits-1:0])
                HaltedAddr: begin
                    halted_d = 1'b1;
                    halted_aligned = 1'b1;
                end

                GoingAddr: begin
                    going = 1'b1;
                end

                ResumingAddr: begin
                    halted_d = 1'b0;
                    resuming_d = 1'b1;
                end

                ExceptionAddr: begin
                    exception = 1'b1;
                end

                Data0Addr, Data1Addr, Data2Addr,
                Data3Addr, Data4Addr: begin
                    data_valid = 1'b1;
                    if (be_i[0])
                        data_bits[7:0] = wdata_i[7:0];
                    if (be_i[1])
                        data_bits[15:8] = wdata_i[15:8];
                    if (be_i[2])
                        data_bits[23:16] = wdata_i[23:16];
                    if (be_i[3])
                        data_bits[31:24] = wdata_i[31:24];
                end

                default:;
            endcase
        // read
        end else if (req_i & (!we_i)) begin
            case (addr_i[DbgAddressBits-1:0])
                WhereToAddr: begin
                    if (cmdbusy & (cmd_type == CmdAccessRegister)) begin
                        // execute program buf
                        if (cmd_postexec) begin
                            rdata_d = jal(5'h0, {9'h0, progbuf_baseaddr-WhereToAddr});
                        // execute command
                        end else begin
                            rdata_d = jal(5'h0, {9'h0, abstractcmd_baseaddr-WhereToAddr});
                        end
                    end
                end

                // harts are polling for flags here
                FlagsBaseAddr: begin
                    rdata_d = {30'b0, resume, go};
                end

                Data0Addr, Data1Addr, Data2Addr, Data3Addr,
                Data4Addr: begin
                    rdata_d = data_i;
                end

                Progbuf0Addr, Progbuf1Addr, Progbuf2Addr, Progbuf3Addr,
                Progbuf4Addr, Progbuf5Addr, Progbuf6Addr, Progbuf7Addr,
                Progbuf8Addr, Progbuf9Addr: begin
                    rdata_d = progbuf_i[addr_i[DbgAddressBits-1:2] -
                              progbuf_baseaddr[DbgAddressBits-1:2]];
                end

                AbstractCmd0Addr, AbstractCmd1Addr, AbstractCmd2Addr, AbstractCmd3Addr,
                AbstractCmd4Addr, AbstractCmd5Addr, AbstractCmd6Addr, AbstractCmd7Addr,
                AbstractCmd8Addr, AbstractCmd9Addr: begin
                    rdata_d = abstract_cmd[addr_i[DbgAddressBits-1:2] -
                              abstractcmd_baseaddr[DbgAddressBits-1:2]];
                end

                default:;
            endcase
        end

    end

    assign data_valid_o = data_valid;
    assign data_o = data_bits;

    always @ (*) begin
        unsupported_command = 1'b0;

        abstract_cmd[0] = illegal;
        abstract_cmd[1] = auipc(5'd10, 21'd0);          // auipc a0, 0
        abstract_cmd[2] = srli(5'd10, 5'd10, 6'd12);    // srli a0, a0, 12
        abstract_cmd[3] = slli(5'd10, 5'd10, 6'd12);    // slli a0, a0, 12
        abstract_cmd[4] = nop;
        abstract_cmd[5] = nop;
        abstract_cmd[6] = nop;
        abstract_cmd[7] = nop;
        abstract_cmd[8] = csrr(`CSR_DSCRATCH1, 5'd10);  // csrr dscratch1, a0  恢复a0寄存器的值
        abstract_cmd[9] = ebreak;

        case (cmd_type)
            CmdAccessRegister: begin
                // unsupported reg size
                if (cmd_aarsize > 3'h2 || cmd_aarpostincrement || cmd_regno >= 16'h1020) begin
                    abstract_cmd[0] = ebreak;
                    unsupported_command = 1'b1;
                end else begin
                    // store a0 in dscratch1
                    abstract_cmd[0] = csrw(`CSR_DSCRATCH1, 5'd10);  // csrw dscratch1, a0  保存a0寄存器的值
                    // write regs
                    if (cmd_transfer && cmd_write) begin
                        // a0
                        if (cmd_regno[12] && (cmd_regno[4:0] == 5'd10)) begin
                            // store s0 in dscratch
                            abstract_cmd[4] = csrw(`CSR_DSCRATCH0, 5'd8);
                            // load from data register
                            abstract_cmd[5] = load(cmd_aarsize, 5'd8, LoadBaseAddr, `DataBaseAddr);
                            // and store it in the corresponding CSR
                            abstract_cmd[6] = csrw(`CSR_DSCRATCH1, 5'd8);
                            // restore s0 again from dscratch
                            abstract_cmd[7] = csrr(`CSR_DSCRATCH0, 5'd8);
                        // GPR access
                        end else if (cmd_regno[12]) begin
                            abstract_cmd[4] = load(cmd_aarsize, cmd_regno[4:0], LoadBaseAddr, `DataBaseAddr);
                        // CSR access
                        end else begin
                            // data register to CSR
                            // store s0 in dscratch
                            abstract_cmd[4] = csrw(`CSR_DSCRATCH0, 5'd8);
                            // load from data register
                            abstract_cmd[5] = load(cmd_aarsize, 5'd8, LoadBaseAddr, `DataBaseAddr);
                            // and store it in the corresponding CSR
                            abstract_cmd[6] = csrw(cmd_regno[11:0], 5'd8);
                            // restore s0 again from dscratch
                            abstract_cmd[7] = csrr(`CSR_DSCRATCH0, 5'd8);
                        end
                    // read regs
                    end else if (cmd_transfer && (!cmd_write)) begin
                        // a0
                        if (cmd_regno[12] && (cmd_regno[4:0] == 5'd10)) begin
                            // store s0 in dscratch
                            abstract_cmd[4] = csrw(`CSR_DSCRATCH0, 5'd8);
                            // read value from CSR into s0
                            abstract_cmd[5] = csrr(`CSR_DSCRATCH1, 5'd8);
                            // and store s0 into data section
                            abstract_cmd[6] = store(cmd_aarsize, 5'd8, LoadBaseAddr, `DataBaseAddr);
                            // restore s0 again from dscratch
                            abstract_cmd[7] = csrr(`CSR_DSCRATCH0, 5'd8);
                        // GPR access
                        end else if (cmd_regno[12]) begin
                            abstract_cmd[4] = store(cmd_aarsize, cmd_regno[4:0], LoadBaseAddr, `DataBaseAddr);
                        // CSR access
                        end else begin
                            // CSR register to data
                            // store s0 in dscratch
                            abstract_cmd[4] = csrw(`CSR_DSCRATCH0, 5'd8);
                            // read value from CSR into s0
                            abstract_cmd[5] = csrr(cmd_regno[11:0], 5'd8);
                            // and store s0 into data section
                            abstract_cmd[6] = store(cmd_aarsize, 5'd8, LoadBaseAddr, `DataBaseAddr);
                            // restore s0 again from dscratch
                            abstract_cmd[7] = csrr(`CSR_DSCRATCH0, 5'd8);
                        end
                    end
                end
                if (cmd_postexec && (!unsupported_command)) begin
                    // issue a nop, we will automatically run into the program buffer
                    abstract_cmd[9] = nop;
                end
            end

            // not supported at the moment:
            // CmdQuickAccess:;
            // CmdAccessMemory:;
            default: begin
                unsupported_command = 1'b1;
                abstract_cmd[0] = ebreak;
            end
        endcase
    end

    wire[31:0] rom_addr;
    assign rom_addr = addr_i;
    assign fwd_rom_d = addr_i[DbgAddressBits-1:0] >= `HaltAddress;

    debug_rom u_debug_rom (
        .clk_i   ( clk       ),
        .req_i   ( req_i     ),
        .addr_i  ( rom_addr  ),
        .rdata_o ( rom_rdata )
    );

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata_q <= 32'h0;
            fwd_rom_q <= 1'b0;
            halted_q <= 1'b0;
            resuming_q <= 1'b0;
            rvalid_q <= 1'b0;
        end else begin
            rdata_q <= rdata_d;
            fwd_rom_q <= fwd_rom_d;
            halted_q <= halted_d;
            resuming_q <= resuming_d;
            rvalid_q <= req_i;
        end
    end

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= S_IDLE;
        end else begin
            state_q <= state_d;
        end
    end

endmodule
