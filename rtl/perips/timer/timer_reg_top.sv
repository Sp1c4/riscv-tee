// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Top module auto-generated by `reggen`


module timer_reg_top (
  input  logic        clk_i,
  input  logic        rst_ni,

  // To HW
  output timer_reg_pkg::timer_reg2hw_t reg2hw, // Write
  input  timer_reg_pkg::timer_hw2reg_t hw2reg, // Read

  input  logic        reg_we,
  input  logic        reg_re,
  input  logic [31:0] reg_wdata,
  input  logic [ 3:0] reg_be,
  input  logic [31:0] reg_addr,
  output logic [31:0] reg_rdata
);

  import timer_reg_pkg::* ;

  localparam int AW = 4;
  localparam int DW = 32;
  localparam int DBW = DW/8;    // Byte Width

  logic reg_error;
  logic addrmiss, wr_err;

  logic [DW-1:0] reg_rdata_next;

  assign reg_rdata = reg_rdata_next;
  assign reg_error = wr_err;

  // Define SW related signals
  // Format: <reg>_<field>_{wd|we|qs}
  //        or <reg>_{wd|we|qs} if field == 1 or 0
  logic ctrl_we;
  logic ctrl_en_qs;
  logic ctrl_en_wd;
  logic ctrl_int_en_qs;
  logic ctrl_int_en_wd;
  logic ctrl_int_pending_qs;
  logic ctrl_int_pending_wd;
  logic ctrl_mode_qs;
  logic ctrl_mode_wd;
  logic [23:0] ctrl_clk_div_qs;
  logic [23:0] ctrl_clk_div_wd;
  logic value_we;
  logic [31:0] value_qs;
  logic [31:0] value_wd;
  logic count_re;
  logic [31:0] count_qs;

  // Register instances
  // R[ctrl]: V(False)

  //   F[en]: 0:0
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_ctrl_en (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),

    // from register interface
    .we     (ctrl_we),
    .wd     (ctrl_en_wd),

    // from internal hardware
    .de     (hw2reg.ctrl.en.de),
    .d      (hw2reg.ctrl.en.d),

    // to internal hardware
    .qe     (reg2hw.ctrl.en.qe),
    .q      (reg2hw.ctrl.en.q),

    // to register interface (read)
    .qs     (ctrl_en_qs)
  );


  //   F[int_en]: 1:1
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_ctrl_int_en (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),

    // from register interface
    .we     (ctrl_we),
    .wd     (ctrl_int_en_wd),

    // from internal hardware
    .de     (hw2reg.ctrl.int_en.de),
    .d      (hw2reg.ctrl.int_en.d),

    // to internal hardware
    .qe     (reg2hw.ctrl.int_en.qe),
    .q      (reg2hw.ctrl.int_en.q),

    // to register interface (read)
    .qs     (ctrl_int_en_qs)
  );


  //   F[int_pending]: 2:2
  prim_subreg #(
    .DW      (1),
    .SWACCESS("W1C"),
    .RESVAL  (1'h0)
  ) u_ctrl_int_pending (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),

    // from register interface
    .we     (ctrl_we),
    .wd     (ctrl_int_pending_wd),

    // from internal hardware
    .de     (hw2reg.ctrl.int_pending.de),
    .d      (hw2reg.ctrl.int_pending.d),

    // to internal hardware
    .qe     (reg2hw.ctrl.int_pending.qe),
    .q      (reg2hw.ctrl.int_pending.q),

    // to register interface (read)
    .qs     (ctrl_int_pending_qs)
  );


  //   F[mode]: 3:3
  prim_subreg #(
    .DW      (1),
    .SWACCESS("RW"),
    .RESVAL  (1'h0)
  ) u_ctrl_mode (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),

    // from register interface
    .we     (ctrl_we),
    .wd     (ctrl_mode_wd),

    // from internal hardware
    .de     (hw2reg.ctrl.mode.de),
    .d      (hw2reg.ctrl.mode.d),

    // to internal hardware
    .qe     (reg2hw.ctrl.mode.qe),
    .q      (reg2hw.ctrl.mode.q),

    // to register interface (read)
    .qs     (ctrl_mode_qs)
  );


  //   F[clk_div]: 31:8
  prim_subreg #(
    .DW      (24),
    .SWACCESS("RW"),
    .RESVAL  (24'h0)
  ) u_ctrl_clk_div (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),

    // from register interface
    .we     (ctrl_we),
    .wd     (ctrl_clk_div_wd),

    // from internal hardware
    .de     (hw2reg.ctrl.clk_div.de),
    .d      (hw2reg.ctrl.clk_div.d),

    // to internal hardware
    .qe     (reg2hw.ctrl.clk_div.qe),
    .q      (reg2hw.ctrl.clk_div.q),

    // to register interface (read)
    .qs     (ctrl_clk_div_qs)
  );


  // R[value]: V(False)

  prim_subreg #(
    .DW      (32),
    .SWACCESS("RW"),
    .RESVAL  (32'h0)
  ) u_value (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),

    // from register interface
    .we     (value_we),
    .wd     (value_wd),

    // from internal hardware
    .de     (1'b0),
    .d      ('0),

    // to internal hardware
    .qe     (),
    .q      (reg2hw.value.q),

    // to register interface (read)
    .qs     (value_qs)
  );


  // R[count]: V(True)

  prim_subreg_ext #(
    .DW    (32)
  ) u_count (
    .re     (count_re),
    .we     (1'b0),
    .wd     ('0),
    .d      (hw2reg.count.d),
    .qre    (),
    .qe     (),
    .q      (reg2hw.count.q),
    .qs     (count_qs)
  );


  logic [2:0] addr_hit;
  always_comb begin
    addr_hit = '0;
    addr_hit[0] = (reg_addr == TIMER_CTRL_OFFSET);
    addr_hit[1] = (reg_addr == TIMER_VALUE_OFFSET);
    addr_hit[2] = (reg_addr == TIMER_COUNT_OFFSET);
  end

  assign addrmiss = (reg_re || reg_we) ? ~|addr_hit : 1'b0 ;

  // Check sub-word write is permitted
  always_comb begin
    wr_err = (reg_we &
              ((addr_hit[0] & (|(TIMER_PERMIT[0] & ~reg_be))) |
               (addr_hit[1] & (|(TIMER_PERMIT[1] & ~reg_be))) |
               (addr_hit[2] & (|(TIMER_PERMIT[2] & ~reg_be)))));
  end

  assign ctrl_we = addr_hit[0] & reg_we & !reg_error;

  assign ctrl_en_wd = reg_wdata[0];

  assign ctrl_int_en_wd = reg_wdata[1];

  assign ctrl_int_pending_wd = reg_wdata[2];

  assign ctrl_mode_wd = reg_wdata[3];

  assign ctrl_clk_div_wd = reg_wdata[31:8];
  assign value_we = addr_hit[1] & reg_we & !reg_error;

  assign value_wd = reg_wdata[31:0];
  assign count_re = addr_hit[2] & reg_re & !reg_error;

  // Read data return
  always_comb begin
    reg_rdata_next = '0;
    unique case (1'b1)
      addr_hit[0]: begin
        reg_rdata_next[0] = ctrl_en_qs;
        reg_rdata_next[1] = ctrl_int_en_qs;
        reg_rdata_next[2] = ctrl_int_pending_qs;
        reg_rdata_next[3] = ctrl_mode_qs;
        reg_rdata_next[31:8] = ctrl_clk_div_qs;
      end

      addr_hit[1]: begin
        reg_rdata_next[31:0] = value_qs;
      end

      addr_hit[2]: begin
        reg_rdata_next[31:0] = count_qs;
      end

      default: begin
        reg_rdata_next = '1;
      end
    endcase
  end

  // Unused signal tieoff

  // wdata / byte enable are not always fully used
  // add a blanket unused statement to handle lint waivers
  logic unused_wdata;
  logic unused_be;
  assign unused_wdata = ^reg_wdata;
  assign unused_be = ^reg_be;

endmodule
