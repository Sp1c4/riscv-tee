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

// 二选一，都不选时表示测试用户自定义程序
// tests/isa测试
//`define TEST_ISA                1
// tests/riscv-compliance测试
//`define TEST_RISCV_COMPLIANCE   1

module tb_top_verilator #(

    ) (
       input wire  clk_i,
       input wire  rst_ni,
       output wire dump_wave_en_o
    );

    wire halted;

    // ISA、自定义程序测试
    wire[31:0] fail_num   = u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.regs[3];
    wire[31:0] sim_result = u_tinyriscv_soc_top.u_tinyriscv_core.u_csr_reg.sstatus_q;
    wire sim_end          = sim_result[0];
    wire sim_succ         = sim_result[1];
    // riscv compliance测试
    wire[31:0] end_flag         = u_tinyriscv_soc_top.u_ram.u_gen_ram.ram[4];
    wire[31:0] begin_signature  = u_tinyriscv_soc_top.u_ram.u_gen_ram.ram[2];
    wire[31:0] end_signature    = u_tinyriscv_soc_top.u_ram.u_gen_ram.ram[3];

    initial begin: load_prog
        automatic logic [1023:0] firmware;

        if($value$plusargs("firmware=%s", firmware)) begin
            $display("[TESTBENCH] %t: loading firmware %0s ...",
                     $time, firmware);
            $readmemh (firmware, u_tinyriscv_soc_top.u_rom.u_gen_ram.ram);
        end else begin
            $display("No firmware specified");
        end
    end

    integer r;
    reg sim_end_q;
    reg[31:0] end_flag_q;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sim_end_q <= 1'b0;
            end_flag_q <= 32'h0;
        end else begin
            sim_end_q <= sim_end;
            end_flag_q <= end_flag;
            `ifdef TEST_RISCV_COMPLIANCE
                if ((!end_flag_q) && (end_flag == 32'h1)) begin
                    if (end_flag == 32'h1) begin
                        for (r = begin_signature; r < end_signature; r = r + 4) begin
                            $display("%x", u_tinyriscv_soc_top.u_rom.u_gen_ram.ram[r[31:2]]);
                        end
                        $finish;
                    end
                end
            `else
                if (sim_end && (!sim_end_q)) begin
                    if (sim_end == 1'b1) begin
                        if (sim_succ == 1'b1) begin
                            $display("~~~~~~~~~~~~~~~~~~~ TEST_PASS ~~~~~~~~~~~~~~~~~~~");
                            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
                            $display("~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~");
                            $display("~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~");
                            $display("~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~");
                            $display("~~~~~~~~~ #####   ######       #       #~~~~~~~~~");
                            $display("~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~");
                            $display("~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~");
                            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
                        end else begin
                            $display("~~~~~~~~~~~~~~~~~~~ TEST_FAIL ~~~~~~~~~~~~~~~~~~~~");
                            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
                            $display("~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~");
                            $display("~~~~~~~~~~#        #  #      #    #     ~~~~~~~~~~");
                            $display("~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~");
                            $display("~~~~~~~~~~#       ######     #    #     ~~~~~~~~~~");
                            $display("~~~~~~~~~~#       #    #     #    #     ~~~~~~~~~~");
                            $display("~~~~~~~~~~#       #    #     #    ######~~~~~~~~~~");
                            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
                            `ifdef TEST_ISA
                            $display("fail testnum = %2d", fail_num);
                            `endif
                        end
                    end
                end
            `endif
        end
    end

    wire           sim_jtag_tck;
    wire           sim_jtag_tms;
    wire           sim_jtag_tdi;
    wire           sim_jtag_trstn;
    wire           sim_jtag_tdo;
    wire [31:0]    sim_jtag_exit;

    tinyriscv_soc_top #(
        .TRACE_ENABLE(1'b1)
    ) u_tinyriscv_soc_top (
        .clk_50m_i     (clk_i),
        .rst_ext_ni    (rst_ni),
        .dump_wave_en_o(dump_wave_en_o),
        .halted_ind_pin(halted),
        .jtag_TCK_pin  (sim_jtag_tck),
        .jtag_TMS_pin  (sim_jtag_tms),
        .jtag_TDI_pin  (sim_jtag_tdi),
        .jtag_TDO_pin  (sim_jtag_tdo)
    );

    sim_jtag #(
        .TICK_DELAY(10),
        .PORT(9999)
    ) u_sim_jtag (
        .clock                ( clk_i                ),
        .reset                ( ~rst_ni              ),
        .enable               ( 1'b1                 ),
        .init_done            ( rst_ni               ),
        .jtag_TCK             ( sim_jtag_tck         ),
        .jtag_TMS             ( sim_jtag_tms         ),
        .jtag_TDI             ( sim_jtag_tdi         ),
        .jtag_TRSTn           ( sim_jtag_trstn       ),
        .jtag_TDO_data        ( sim_jtag_tdo         ),
        .jtag_TDO_driven      ( 1'b1                 ),
        .exit                 ( sim_jtag_exit        )
    );

    always @ (*) begin
        if (sim_jtag_exit) begin
            $display("jtag exit...");
            $finish(2);
        end
    end

    // 默认不显示寄存器值
    wire display_regs = 1'b0;

    wire write_gpr_reg = u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.we_i;
    wire[4:0] write_gpr_addr = u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.waddr_i;

    wire write_csr_reg = u_tinyriscv_soc_top.u_tinyriscv_core.u_csr_reg.exu_we_i;
    wire[31:0] write_csr_addr = u_tinyriscv_soc_top.u_tinyriscv_core.u_csr_reg.exu_waddr_i;

    always @ (posedge clk_i) begin
        if (halted && write_gpr_reg && display_regs && (write_gpr_addr == 5'd31)) begin
            $display("\n");
            $display("ra = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.ra);
            $display("sp = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.sp);
            $display("gp = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.gp);
            $display("tp = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.tp);
            $display("t0 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.t0);
            $display("t1 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.t1);
            $display("t2 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.t2);
            $display("s0 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.s0);
            $display("fp = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.fp);
            $display("s1 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.s1);
            $display("a0 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.a0);
            $display("a1 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.a1);
            $display("a2 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.a2);
            $display("a3 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.a3);
            $display("a4 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.a4);
            $display("a5 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.a5);
            $display("a6 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.a6);
            $display("a7 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.a7);
            $display("s2 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.s2);
            $display("s3 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.s3);
            $display("s4 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.s4);
            $display("s5 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.s5);
            $display("s6 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.s6);
            $display("s7 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.s7);
            $display("s8 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.s8);
            $display("s9 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.s9);
            $display("s10 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.s10);
            $display("s11 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.s11);
            $display("t3 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.t3);
            $display("t4 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.t4);
            $display("t5 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.t5);
            $display("t6 = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_gpr_reg.t6);
        end else if (halted && write_csr_reg && display_regs && (write_csr_addr[11:0] == 12'hc00)) begin
            $display("\n");
            $display("misa = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_csr_reg.misa);
            $display("cycle = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_csr_reg.cycle[31:0]);
            $display("cycleh = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_csr_reg.cycle[63:32]);
            $display("mtvec = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_csr_reg.mtvec);
            $display("mstatus = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_csr_reg.mstatus);
            $display("mepc = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_csr_reg.mepc);
            $display("mie = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_csr_reg.mie);
            $display("dpc = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_csr_reg.dpc);
            $display("dcsr = 0x%x", u_tinyriscv_soc_top.u_tinyriscv_core.u_csr_reg.dcsr);
        end
    end

endmodule // tb_top_verilator
