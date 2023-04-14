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

module jtag_dtm #(
    parameter DMI_ADDR_BITS  = 7,
    parameter DMI_DATA_BITS  = 32,
    parameter DMI_OP_BITS    = 2,
    parameter TAP_REQ_BITS  = DMI_ADDR_BITS + DMI_DATA_BITS + DMI_OP_BITS,
    parameter DTM_RESP_BITS = TAP_REQ_BITS,
    parameter DTM_REQ_BITS  = DTM_RESP_BITS,
    parameter DMI_RESP_BITS = DTM_REQ_BITS
    )(

    input  wire                     jtag_tck_i,     // JTAG test clock pad
    input  wire                     jtag_trst_ni,   // JTAG test reset pad

    // to jtag_dmi
    output wire [DTM_REQ_BITS-1:0]  dtm_data_o,
    output wire                     dtm_valid_o,
    // from jtag_dmi
    input  wire                     dmi_ready_i,

    // from jtag_dmi
    input  wire [DMI_RESP_BITS-1:0] dmi_data_i,
    input  wire                     dmi_valid_i,
    // to jtag_dmi
    output wire                     dtm_ready_o,

    // from jtag_tap
    input  wire                     tap_req_i,
    input  wire [TAP_REQ_BITS-1:0]  tap_data_i,
    input  wire                     dmireset_i,

    // to jtag_tap
    output wire [DTM_RESP_BITS-1:0] data_o,
    output wire [31:0]              idcode_o,
    output wire [31:0]              dtmcs_o

    );

    localparam IDCODE_VERSION       = 4'h1;
    localparam IDCODE_PART_NUMBER   = 16'he200;
    localparam IDCODE_MANUFLD       = 11'h537;

    localparam DTM_VERSION          = 4'h1;

    localparam S_IDLE               = 5'b00001;
    localparam S_READ               = 5'b00010;
    localparam S_WAIT_READ          = 5'b00100;
    localparam S_WRITE              = 5'b01000;
    localparam S_WAIT_WRITE         = 5'b10000;

    reg[4:0] state_d;
    reg[4:0] state_q;
    reg dtm_valid;
    reg dtm_ready;
    reg[DTM_REQ_BITS-1:0] dtm_data_q;
    reg[DTM_REQ_BITS-1:0] dtm_data_d;
    reg[DTM_RESP_BITS-1:0] resp_tap_data_q;
    reg is_busy;
    reg stick_busy;

    wire[DTM_RESP_BITS-1:0] busy_response;
    wire dtm_busy;
    wire[DMI_OP_BITS-1:0] op;
    wire[1:0] dmistat;
    wire[DMI_ADDR_BITS-1:0] abits = DMI_ADDR_BITS[6:0];

    assign idcode_o = {IDCODE_VERSION, IDCODE_PART_NUMBER, IDCODE_MANUFLD, 1'h1};
    assign dtmcs_o = {14'b0,
                      1'b0,         // dmihardreset
                      1'b0,         // dmireset
                      1'b0,
                      3'h1,         // idle
                      dmistat,      // dmistat
                      abits,        // abits
                      DTM_VERSION}; // version

    assign busy_response = {{(DMI_ADDR_BITS + DMI_DATA_BITS){1'b0}}, {(DMI_OP_BITS){1'b1}}};  // op = 2'b11

    assign dmistat = (stick_busy | is_busy) ? 2'b11 : 2'b00;

    assign op = tap_data_i[DMI_OP_BITS-1:0];

    always @ (*) begin
        state_d = state_q;
        dtm_valid = 1'b0;
        dtm_ready = 1'b0;
        dtm_data_d = dtm_data_q;

        case (state_q)
            S_IDLE: begin
                if (tap_req_i) begin
                    if (op == `DMI_OP_READ) begin
                        state_d = S_READ;
                        dtm_data_d = tap_data_i;
                    end else if (op == `DMI_OP_WRITE) begin
                        state_d = S_WRITE;
                        dtm_data_d = tap_data_i;
                    end else begin
                        state_d = S_IDLE;
                    end
                end else begin
                    state_d = S_IDLE;
                end
            end

            S_READ: begin
                if (dmi_ready_i) begin
                    dtm_valid = 1'b1;
                    state_d = S_WAIT_READ;
                end
            end

            S_WAIT_READ: begin
                dtm_ready = 1'b1;
                if (dmi_valid_i) begin
                    dtm_data_d = dmi_data_i;
                    state_d = S_IDLE;
                end
            end

            S_WRITE: begin
                if (dmi_ready_i) begin
                    dtm_valid = 1'b1;
                    state_d = S_WAIT_WRITE;
                end
            end

            S_WAIT_WRITE: begin
                dtm_ready = 1'b1;
                if (dmi_valid_i) begin
                    dtm_data_d = dmi_data_i;
                    state_d = S_IDLE;
                end
            end

            default: begin
                dtm_data_d = {DTM_REQ_BITS{1'b0}};
                state_d = S_IDLE;
            end
        endcase
    end

    assign dtm_valid_o = dtm_valid;
    assign dtm_data_o  = dtm_data_q;
    assign dtm_ready_o = dtm_ready;

    always @ (posedge jtag_tck_i or negedge jtag_trst_ni) begin
        if (!jtag_trst_ni) begin
            state_q <= S_IDLE;
            dtm_data_q <= {DTM_REQ_BITS{1'b0}};
        end else begin
            state_q <= state_d;
            dtm_data_q <= dtm_data_d;
        end
    end

    always @ (posedge jtag_tck_i or negedge jtag_trst_ni) begin
        if (!jtag_trst_ni) begin
            is_busy <= 1'b0;
            stick_busy <= 1'b0;
        end else begin
            if (dmireset_i) begin
                stick_busy <= 1'b0;
            end else if ((state_q != S_IDLE) && tap_req_i) begin
                stick_busy <= 1'b1;
            end
            if ((state_q != S_IDLE) | tap_req_i) begin
                is_busy <= 1'b1;
            end else begin
                is_busy <= 1'b0;
            end
        end
    end

    assign data_o = (stick_busy | is_busy | tap_req_i) ? busy_response : dtm_data_q;

endmodule
