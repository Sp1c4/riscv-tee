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

module i2c_core (
    input  logic        clk_i,
    input  logic        rst_ni,

    output logic        scl_o,
    output logic        scl_oe_o,
    input  logic        scl_i,
    output logic        sda_o,
    output logic        sda_oe_o,
    input  logic        sda_i,

    output logic        irq_o,

    input  logic        reg_we_i,
    input  logic        reg_re_i,
    input  logic [31:0] reg_wdata_i,
    input  logic [ 3:0] reg_be_i,
    input  logic [31:0] reg_addr_i,
    output logic [31:0] reg_rdata_o
    );

    import i2c_reg_pkg::*;

    i2c_reg_pkg::i2c_reg2hw_t reg2hw;
    i2c_reg_pkg::i2c_hw2reg_t hw2reg;

    logic master_mode;
    logic op_write;
    logic op_read;
    logic start;
    logic [15:0] clk_div;
    logic int_enable;
    logic [7:0] master_address;
    logic [7:0] master_register;
    logic [7:0] master_data;
    logic master_ready, master_ready_re;
    logic master_start;
    logic master_error;
    logic [7:0] master_read_data;
    logic master_scl;
    logic master_scl_oe;
    logic master_sda;
    logic master_sda_oe;
    logic slave_mode;
    logic slave_start;
    logic [7:0] slave_address;
    logic [7:0] slave_recv_address;
    logic [7:0] slave_send_data;
    logic [7:0] slave_recv_data;
    logic slave_recv_read;
    logic slave_recv_valid, slave_recv_valid_re;
    logic slave_op_req, slave_op_req_re;
    logic slave_scl;
    logic slave_scl_oe;
    logic slave_sda;
    logic slave_sda_oe;

    assign scl_o    = master_scl | slave_scl;
    assign scl_oe_o = master_scl_oe | slave_scl_oe;
    assign sda_o    = master_sda | slave_sda;
    assign sda_oe_o = master_sda_oe | slave_sda_oe;

//////////////////////////////////////////////////////// master //////////////////////////////////////////////////////////

    assign master_mode = ~reg2hw.ctrl.mode.q;
    assign op_write    = ~reg2hw.ctrl.write.q;
    assign op_read     = reg2hw.ctrl.write.q;
    assign start       = reg2hw.ctrl.start.q;
    assign clk_div     = reg2hw.ctrl.clk_div.q;
    assign int_enable  = reg2hw.ctrl.int_en.q;

    assign master_address  = reg2hw.master_data.address.q;
    assign master_register = reg2hw.master_data.regreg.q;
    assign master_data     = reg2hw.master_data.data.q;

    // 软件写1启动master传输
    assign master_start = reg2hw.ctrl.start.qe && reg2hw.ctrl.start.q && master_ready && master_mode;

    // master传输完成，硬件清start位
    assign hw2reg.ctrl.start.d = 1'b0;
    assign hw2reg.ctrl.start.de = master_ready_re;

    // 传输完成产生中断pending
    assign hw2reg.ctrl.int_pending.d = 1'b1;
    assign hw2reg.ctrl.int_pending.de = int_enable && (master_ready_re || slave_op_req_re);

    // 传输完成并且是读操作，则更新master data
    assign hw2reg.master_data.data.d = master_read_data;
    assign hw2reg.master_data.data.de = op_read && master_ready_re;

    // 传输完成更新error
    assign hw2reg.ctrl.error.d = master_error;
    assign hw2reg.ctrl.error.de = master_ready_re;

    assign irq_o = reg2hw.ctrl.int_pending.q;

    edge_detect master_ready_edge_detect (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .sig_i  (master_ready),
        .sig_o  (),
        .re_o   (master_ready_re),
        .fe_o   ()
    );

//////////////////////////////////////////////////////// slave //////////////////////////////////////////////////////////

    assign slave_start   = reg2hw.ctrl.start.q;
    assign slave_mode    = reg2hw.ctrl.mode.q;
    assign slave_address = reg2hw.ctrl.slave_addr.q;

    // 收到请求后清ready状态
    assign hw2reg.ctrl.slave_rdy.d = 1'b0;
    assign hw2reg.ctrl.slave_rdy.de = slave_op_req_re;

    always_comb begin
        slave_send_data = '0;
        hw2reg.slave_addr.addr0.de = 1'b0;
        hw2reg.slave_addr.addr0.d = '0;
        hw2reg.slave_addr.addr1.de = 1'b0;
        hw2reg.slave_addr.addr1.d = '0;
        hw2reg.slave_addr.addr2.de = 1'b0;
        hw2reg.slave_addr.addr2.d = '0;
        hw2reg.slave_addr.addr3.de = 1'b0;
        hw2reg.slave_addr.addr3.d = '0;
        hw2reg.slave_wdata.wdata0.de = 1'b0;
        hw2reg.slave_wdata.wdata0.d = '0;
        hw2reg.slave_wdata.wdata1.de = 1'b0;
        hw2reg.slave_wdata.wdata1.d = '0;
        hw2reg.slave_wdata.wdata2.de = 1'b0;
        hw2reg.slave_wdata.wdata2.d = '0;
        hw2reg.slave_wdata.wdata3.de = 1'b0;
        hw2reg.slave_wdata.wdata3.d = '0;
        hw2reg.ctrl.slave_wr.de = 1'b0;
        hw2reg.ctrl.slave_wr.d = '0;

        case (slave_recv_address)
            8'h0: begin
                slave_send_data = {6'h0, reg2hw.ctrl.slave_rdy.q, 1'b0};
            end
            8'hc: begin
                slave_send_data = reg2hw.slave_rdata.q[7:0];
            end
            8'hd: begin
                slave_send_data = reg2hw.slave_rdata.q[15:8];
            end
            8'he: begin
                slave_send_data = reg2hw.slave_rdata.q[23:16];
            end
            8'hf: begin
                slave_send_data = reg2hw.slave_rdata.q[31:24];
            end
            default: ;
        endcase

        // 收到写请求
        if (slave_recv_valid_re && (!slave_recv_read)) begin
            case (slave_recv_address)
                8'h0: begin
                    hw2reg.ctrl.slave_wr.de = 1'b1;
                    hw2reg.ctrl.slave_wr.d = slave_recv_data[0];
                end
                8'h4: begin
                    hw2reg.slave_addr.addr0.de = 1'b1;
                    hw2reg.slave_addr.addr0.d = slave_recv_data;
                end
                8'h5: begin
                    hw2reg.slave_addr.addr1.de = 1'b1;
                    hw2reg.slave_addr.addr1.d = slave_recv_data;
                end
                8'h6: begin
                    hw2reg.slave_addr.addr2.de = 1'b1;
                    hw2reg.slave_addr.addr2.d = slave_recv_data;
                end
                8'h7: begin
                    hw2reg.slave_addr.addr3.de = 1'b1;
                    hw2reg.slave_addr.addr3.d = slave_recv_data;
                end
                8'h8: begin
                    hw2reg.slave_wdata.wdata0.de = 1'b1;
                    hw2reg.slave_wdata.wdata0.d = slave_recv_data;
                end
                8'h9: begin
                    hw2reg.slave_wdata.wdata1.de = 1'b1;
                    hw2reg.slave_wdata.wdata1.d = slave_recv_data;
                end
                8'ha: begin
                    hw2reg.slave_wdata.wdata2.de = 1'b1;
                    hw2reg.slave_wdata.wdata2.d = slave_recv_data;
                end
                8'hb: begin
                    hw2reg.slave_wdata.wdata3.de = 1'b1;
                    hw2reg.slave_wdata.wdata3.d = slave_recv_data;
                end
                default: ;
            endcase
        end
    end

    // master写0x00地址，发出中断(通知软件)
    assign slave_op_req = slave_recv_valid_re && (!slave_recv_read) && (slave_recv_address == 8'h0);

    // 软件收到请求上升沿检测
    edge_detect slave_op_req_edge_detect (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .sig_i  (slave_op_req),
        .sig_o  (),
        .re_o   (slave_op_req_re),
        .fe_o   ()
    );

    // slave收到请求上升沿检测
    edge_detect slave_recv_valid_edge_detect (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .sig_i  (slave_recv_valid),
        .sig_o  (),
        .re_o   (slave_recv_valid_re),
        .fe_o   ()
    );

    i2c_master u_i2c_master (
        .clk_i        (clk_i),
        .rst_ni       (rst_ni),
        .enable_i     (master_mode),
        .div_ratio_i  (clk_div),
        .read_i       (op_read),
        .slave_addr_i (master_address),
        .slave_reg_i  (master_register),
        .slave_data_i (master_data),
        .start_i      (master_start),
        .ready_o      (master_ready),
        .error_o      (master_error),
        .data_o       (master_read_data),
        .scl_i        (scl_i),
        .scl_o        (master_scl),
        .scl_oe_o     (master_scl_oe),
        .sda_i        (sda_i),
        .sda_o        (master_sda),
        .sda_oe_o     (master_sda_oe)
    );

    i2c_slave u_i2c_slave (
        .clk_i        (clk_i),
        .rst_ni       (rst_ni),
        .enable_i     (slave_mode & slave_start),
        .slave_addr_i (slave_address),
        .data_i       (slave_send_data),
        .addr_o       (slave_recv_address),
        .read_o       (slave_recv_read),
        .valid_o      (slave_recv_valid),
        .data_o       (slave_recv_data),
        .scl_i        (scl_i),
        .scl_o        (slave_scl),
        .scl_oe_o     (slave_scl_oe),
        .sda_i        (sda_i),
        .sda_o        (slave_sda),
        .sda_oe_o     (slave_sda_oe)
    );

    i2c_reg_top u_i2c_reg_top (
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
