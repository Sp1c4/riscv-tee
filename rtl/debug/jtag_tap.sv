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


module jtag_tap #(
    parameter DMI_ADDR_BITS = 7,
    parameter DMI_DATA_BITS = 32,
    parameter DMI_OP_BITS   = 2,
    parameter IR_BITS       = 5,
    parameter TAP_REQ_BITS  = DMI_ADDR_BITS + DMI_DATA_BITS + DMI_OP_BITS,
    parameter DTM_RESP_BITS = TAP_REQ_BITS
    )(

    input wire  jtag_tck_i,     // JTAG test clock pad
    input wire  jtag_tdi_i,     // JTAG test data input pad
    input wire  jtag_tms_i,     // JTAG test mode select pad
    input wire  jtag_trst_ni,   // JTAG test reset pad
    output wire jtag_tdo_o,     // JTAG test data output pad

    output wire tap_req_o,
    output wire[TAP_REQ_BITS-1:0] tap_data_o,
    output wire dmireset_o,

    input wire[DTM_RESP_BITS-1:0] dtm_data_i,
    input wire[31:0] idcode_i,
    input wire[31:0] dtmcs_i

    );

    localparam SHIFT_REG_BITS    = TAP_REQ_BITS;

    localparam TEST_LOGIC_RESET  = 16'h0001;
    localparam RUN_TEST_IDLE     = 16'h0002;
    localparam SELECT_DR         = 16'h0004;
    localparam CAPTURE_DR        = 16'h0008;
    localparam SHIFT_DR          = 16'h0010;
    localparam EXIT1_DR          = 16'h0020;
    localparam PAUSE_DR          = 16'h0040;
    localparam EXIT2_DR          = 16'h0080;
    localparam UPDATE_DR         = 16'h0100;
    localparam SELECT_IR         = 16'h0200;
    localparam CAPTURE_IR        = 16'h0400;
    localparam SHIFT_IR          = 16'h0800;
    localparam EXIT1_IR          = 16'h1000;
    localparam PAUSE_IR          = 16'h2000;
    localparam EXIT2_IR          = 16'h4000;
    localparam UPDATE_IR         = 16'h8000;

    // DTM regs
    localparam REG_BYPASS        = 5'b11111;
    localparam REG_IDCODE        = 5'b00001;
    localparam REG_DMI           = 5'b10001;
    localparam REG_DTMCS         = 5'b10000;

    reg[IR_BITS-1:0] ir_reg;
    reg[SHIFT_REG_BITS-1:0] shift_reg;

    reg[15:0] tap_state;
    reg[15:0] next_state;

    always @ (posedge jtag_tck_i or negedge jtag_trst_ni) begin
        if (!jtag_trst_ni) begin
            tap_state <= TEST_LOGIC_RESET;
        end else begin
            tap_state <= next_state;
        end
    end

    // state switch
    always @ (*) begin
        case (tap_state)
            TEST_LOGIC_RESET  : next_state = jtag_tms_i ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
            RUN_TEST_IDLE     : next_state = jtag_tms_i ? SELECT_DR        : RUN_TEST_IDLE;
            SELECT_DR         : next_state = jtag_tms_i ? SELECT_IR        : CAPTURE_DR;
            CAPTURE_DR        : next_state = jtag_tms_i ? EXIT1_DR         : SHIFT_DR;
            SHIFT_DR          : next_state = jtag_tms_i ? EXIT1_DR         : SHIFT_DR;
            EXIT1_DR          : next_state = jtag_tms_i ? UPDATE_DR        : PAUSE_DR;
            PAUSE_DR          : next_state = jtag_tms_i ? EXIT2_DR         : PAUSE_DR;
            EXIT2_DR          : next_state = jtag_tms_i ? UPDATE_DR        : SHIFT_DR;
            UPDATE_DR         : next_state = jtag_tms_i ? SELECT_DR        : RUN_TEST_IDLE;
            SELECT_IR         : next_state = jtag_tms_i ? TEST_LOGIC_RESET : CAPTURE_IR;
            CAPTURE_IR        : next_state = jtag_tms_i ? EXIT1_IR         : SHIFT_IR;
            SHIFT_IR          : next_state = jtag_tms_i ? EXIT1_IR         : SHIFT_IR;
            EXIT1_IR          : next_state = jtag_tms_i ? UPDATE_IR        : PAUSE_IR;
            PAUSE_IR          : next_state = jtag_tms_i ? EXIT2_IR         : PAUSE_IR;
            EXIT2_IR          : next_state = jtag_tms_i ? UPDATE_IR        : SHIFT_IR;
            UPDATE_IR         : next_state = jtag_tms_i ? SELECT_DR        : RUN_TEST_IDLE;
            default           : next_state = TEST_LOGIC_RESET;
        endcase
    end

    // IR or DR shift
    always @ (posedge jtag_tck_i or negedge jtag_trst_ni) begin
        if (!jtag_trst_ni) begin
            shift_reg <= {SHIFT_REG_BITS{1'b0}};
        end else begin
            case (tap_state)
                // IR
                CAPTURE_IR: shift_reg <= {{(SHIFT_REG_BITS-1){1'b0}}, 1'b1}; //JTAG spec says it must be 2'b01
                SHIFT_IR  : shift_reg <= {{(SHIFT_REG_BITS-IR_BITS){1'b0}}, jtag_tdi_i, shift_reg[IR_BITS-1:1]}; // right shift 1 bit
                // DR
                CAPTURE_DR: case (ir_reg) 
                                REG_BYPASS     : shift_reg <= {(SHIFT_REG_BITS){1'b0}};
                                REG_IDCODE     : shift_reg <= {{(SHIFT_REG_BITS-DMI_DATA_BITS){1'b0}}, idcode_i};
                                REG_DTMCS      : shift_reg <= {{(SHIFT_REG_BITS-DMI_DATA_BITS){1'b0}}, dtmcs_i};
                                REG_DMI        : shift_reg <= dtm_data_i;
                                default        : shift_reg <= {(SHIFT_REG_BITS){1'b0}};
                            endcase
                SHIFT_DR  : case (ir_reg) 
                                REG_BYPASS     : shift_reg <= {{(SHIFT_REG_BITS-1){1'b0}}, jtag_tdi_i};    // in = out
                                REG_IDCODE     : shift_reg <= {{(SHIFT_REG_BITS-DMI_DATA_BITS){1'b0}}, jtag_tdi_i, shift_reg[31:1]}; // right shift 1 bit
                                REG_DTMCS      : shift_reg <= {{(SHIFT_REG_BITS-DMI_DATA_BITS){1'b0}}, jtag_tdi_i, shift_reg[31:1]}; // right shift 1 bit
                                REG_DMI        : shift_reg <= {jtag_tdi_i, shift_reg[SHIFT_REG_BITS-1:1]}; // right shift 1 bit
                                default        : shift_reg <= {{(SHIFT_REG_BITS-1){1'b0}} , jtag_tdi_i};
                            endcase 
            endcase
        end
    end

    reg tap_req_q;
    reg[TAP_REQ_BITS-1:0] tap_data_q;

    // send request to DTM module
    always @ (posedge jtag_tck_i or negedge jtag_trst_ni) begin
        if (!jtag_trst_ni) begin
            tap_req_q <= 1'b0;
            tap_data_q <= {TAP_REQ_BITS{1'b0}};
        end else begin
            if ((tap_state == UPDATE_DR) && (ir_reg == REG_DMI)) begin
                tap_req_q <= 1'b1;
                tap_data_q <= shift_reg;
            end else begin
                tap_req_q <= 1'b0;
            end
        end
    end

    assign tap_req_o = tap_req_q;
    assign tap_data_o = tap_data_q;

    // ir_reg
    always @ (negedge jtag_tck_i) begin
        if (tap_state == TEST_LOGIC_RESET) begin
            ir_reg <= REG_IDCODE;
        end else if (tap_state == UPDATE_IR) begin
            ir_reg <= shift_reg[IR_BITS-1:0];
        end
    end

    reg jtag_tdo_q;

    // TDO output
    always @ (negedge jtag_tck_i) begin
        if ((tap_state == SHIFT_IR) || (tap_state == SHIFT_DR)) begin
            jtag_tdo_q <= shift_reg[0];
        end else begin
            jtag_tdo_q <= 1'b0;
        end
    end

    assign jtag_tdo_o = jtag_tdo_q;

    reg dmireset_q;

    always @ (posedge jtag_tck_i or negedge jtag_trst_ni) begin
        if (!jtag_trst_ni) begin
            dmireset_q <= 1'b0;
        end else begin
            if ((tap_state == UPDATE_DR) && (ir_reg == REG_DTMCS)) begin
                dmireset_q <= shift_reg[16];
            end else begin
                dmireset_q <= 1'b0;
            end
        end
    end

    assign dmireset_o = dmireset_q;

endmodule
