// Copyright 2018 ETH Zurich and University of Bologna.
//
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Fabian Schuiki <fschuiki@iis.ee.ethz.ch>

/// A two-phase clock domain crossing.
///
/// CONSTRAINT: Requires max_delay of min_period(src_clk_i, dst_clk_i) through
/// the paths async_req, async_ack, async_data.
/* verilator lint_off DECLFILENAME */
module cdc_2phase #(
  parameter DATA_WIDTH = 32
)(
  input  wire                   src_rst_ni,
  input  wire                   src_clk_i,
  input  wire [DATA_WIDTH-1:0]  src_data_i,
  input  wire                   src_valid_i,
  output wire                   src_ready_o,

  input  wire                   dst_rst_ni,
  input  wire                   dst_clk_i,
  output wire [DATA_WIDTH-1:0]  dst_data_o,
  output wire                   dst_valid_o,
  input  wire                   dst_ready_i
);

  // Asynchronous handshake signals.
  (* dont_touch = "true" *) wire async_req;
  (* dont_touch = "true" *) wire async_ack;
  (* dont_touch = "true" *) wire[DATA_WIDTH-1:0] async_data;

  // The sender in the source domain.
  cdc_2phase_src #(.DATA_WIDTH(DATA_WIDTH)) i_src (
    .rst_ni       ( src_rst_ni  ),
    .clk_i        ( src_clk_i   ),
    .data_i       ( src_data_i  ),
    .valid_i      ( src_valid_i ),
    .ready_o      ( src_ready_o ),
    .async_req_o  ( async_req   ),
    .async_ack_i  ( async_ack   ),
    .async_data_o ( async_data  )
  );

  // The receiver in the destination domain.
  cdc_2phase_dst #(.DATA_WIDTH(DATA_WIDTH)) i_dst (
    .rst_ni       ( dst_rst_ni  ),
    .clk_i        ( dst_clk_i   ),
    .data_o       ( dst_data_o  ),
    .valid_o      ( dst_valid_o ),
    .ready_i      ( dst_ready_i ),
    .async_req_i  ( async_req   ),
    .async_ack_o  ( async_ack   ),
    .async_data_i ( async_data  )
  );

endmodule


/// Half of the two-phase clock domain crossing located in the source domain.
module cdc_2phase_src #(
  parameter DATA_WIDTH = 32
)(
  input  wire                   rst_ni,
  input  wire                   clk_i,
  input  wire [DATA_WIDTH-1:0]  data_i,
  input  wire                   valid_i,
  output wire                   ready_o,
  output wire                   async_req_o,
  input  wire                   async_ack_i,
  output wire [DATA_WIDTH-1:0]  async_data_o
);

  (* dont_touch = "true" *)
  reg req_src_q, ack_src_q, ack_q;
  (* dont_touch = "true" *)
  reg[DATA_WIDTH-1:0] data_src_q;

  // The req_src and data_src registers change when a new data item is accepted.
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      req_src_q  <= 0;
      data_src_q <= {DATA_WIDTH{1'b0}};
    end else if (valid_i && ready_o) begin
      req_src_q  <= ~req_src_q;
      data_src_q <= data_i;
    end
  end

  // The ack_src and ack registers act as synchronization stages.
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ack_src_q <= 0;
      ack_q     <= 0;
    end else begin
      ack_src_q <= async_ack_i;
      ack_q     <= ack_src_q;
    end
  end

  // Output assignments.
  assign ready_o = (req_src_q == ack_q);
  assign async_req_o = req_src_q;
  assign async_data_o = data_src_q;

endmodule


/// Half of the two-phase clock domain crossing located in the destination
/// domain.
module cdc_2phase_dst #(
  parameter DATA_WIDTH = 32
)(
  input  wire                   rst_ni,
  input  wire                   clk_i,
  output wire [DATA_WIDTH-1:0]  data_o,
  output wire                   valid_o,
  input  wire                   ready_i,
  input  wire                   async_req_i,
  output wire                   async_ack_o,
  input  wire [DATA_WIDTH-1:0]  async_data_i
);

  (* dont_touch = "true" *)
  (* async_reg = "true" *)
  reg req_dst_q, req_q0, req_q1, ack_dst_q;
  (* dont_touch = "true" *)
  reg[DATA_WIDTH-1:0] data_dst_q;

  // The ack_dst register changes when a new data item is accepted.
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ack_dst_q  <= 0;
    end else if (valid_o && ready_i) begin
      ack_dst_q  <= ~ack_dst_q;
    end
  end

  // The data_dst register changes when a new data item is presented. This is
  // indicated by the async_req line changing levels.
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      data_dst_q <= '0;
    end else if (req_q0 != req_q1 && !valid_o) begin
      data_dst_q <= async_data_i;
    end
  end

  // The req_dst and req registers act as synchronization stages.
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      req_dst_q <= 0;
      req_q0    <= 0;
      req_q1    <= 0;
    end else begin
      req_dst_q <= async_req_i;
      req_q0    <= req_dst_q;
      req_q1    <= req_q0;
    end
  end

  // Output assignments.
  assign valid_o = (ack_dst_q != req_q1);
  assign data_o = data_dst_q;
  assign async_ack_o = ack_dst_q;

endmodule
/* verilator lint_on DECLFILENAME */
