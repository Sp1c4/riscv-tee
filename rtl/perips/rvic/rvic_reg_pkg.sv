// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Package auto-generated by `reggen` containing data structure

package rvic_reg_pkg;

  // Address widths within the block
  parameter int BlockAw = 6;

  ////////////////////////////
  // Typedefs for registers //
  ////////////////////////////

  typedef struct packed {
    logic [31:0] q;
  } rvic_reg2hw_enable_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } rvic_reg2hw_pending_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } rvic_reg2hw_priority0_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } rvic_reg2hw_priority1_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } rvic_reg2hw_priority2_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } rvic_reg2hw_priority3_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } rvic_reg2hw_priority4_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } rvic_reg2hw_priority5_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } rvic_reg2hw_priority6_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } rvic_reg2hw_priority7_reg_t;

  typedef struct packed {
    logic [31:0] d;
    logic        de;
  } rvic_hw2reg_pending_reg_t;

  // Register -> HW type
  typedef struct packed {
    rvic_reg2hw_enable_reg_t enable; // [319:288]
    rvic_reg2hw_pending_reg_t pending; // [287:256]
    rvic_reg2hw_priority0_reg_t priority0; // [255:224]
    rvic_reg2hw_priority1_reg_t priority1; // [223:192]
    rvic_reg2hw_priority2_reg_t priority2; // [191:160]
    rvic_reg2hw_priority3_reg_t priority3; // [159:128]
    rvic_reg2hw_priority4_reg_t priority4; // [127:96]
    rvic_reg2hw_priority5_reg_t priority5; // [95:64]
    rvic_reg2hw_priority6_reg_t priority6; // [63:32]
    rvic_reg2hw_priority7_reg_t priority7; // [31:0]
  } rvic_reg2hw_t;

  // HW -> register type
  typedef struct packed {
    rvic_hw2reg_pending_reg_t pending; // [32:0]
  } rvic_hw2reg_t;

  // Register offsets
  parameter logic [BlockAw-1:0] RVIC_ENABLE_OFFSET = 6'h0;
  parameter logic [BlockAw-1:0] RVIC_PENDING_OFFSET = 6'h4;
  parameter logic [BlockAw-1:0] RVIC_PRIORITY0_OFFSET = 6'h8;
  parameter logic [BlockAw-1:0] RVIC_PRIORITY1_OFFSET = 6'hc;
  parameter logic [BlockAw-1:0] RVIC_PRIORITY2_OFFSET = 6'h10;
  parameter logic [BlockAw-1:0] RVIC_PRIORITY3_OFFSET = 6'h14;
  parameter logic [BlockAw-1:0] RVIC_PRIORITY4_OFFSET = 6'h18;
  parameter logic [BlockAw-1:0] RVIC_PRIORITY5_OFFSET = 6'h1c;
  parameter logic [BlockAw-1:0] RVIC_PRIORITY6_OFFSET = 6'h20;
  parameter logic [BlockAw-1:0] RVIC_PRIORITY7_OFFSET = 6'h24;

  // Register index
  typedef enum int {
    RVIC_ENABLE,
    RVIC_PENDING,
    RVIC_PRIORITY0,
    RVIC_PRIORITY1,
    RVIC_PRIORITY2,
    RVIC_PRIORITY3,
    RVIC_PRIORITY4,
    RVIC_PRIORITY5,
    RVIC_PRIORITY6,
    RVIC_PRIORITY7
  } rvic_id_e;

  // Register width information to check illegal writes
  parameter logic [3:0] RVIC_PERMIT [10] = '{
    4'b1111, // index[0] RVIC_ENABLE
    4'b1111, // index[1] RVIC_PENDING
    4'b1111, // index[2] RVIC_PRIORITY0
    4'b1111, // index[3] RVIC_PRIORITY1
    4'b1111, // index[4] RVIC_PRIORITY2
    4'b1111, // index[5] RVIC_PRIORITY3
    4'b1111, // index[6] RVIC_PRIORITY4
    4'b1111, // index[7] RVIC_PRIORITY5
    4'b1111, // index[8] RVIC_PRIORITY6
    4'b1111  // index[9] RVIC_PRIORITY7
  };

endpackage
