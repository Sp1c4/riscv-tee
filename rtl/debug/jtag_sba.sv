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


module jtag_sba(

    input  wire                     clk,
    input  wire                     rst_n,

    input  wire [31:0]              sbaddress_i,
    input  wire                     sbaddress_write_valid_i,

    input  wire                     sbreadonaddr_i,
    output wire [31:0]              sbaddress_o,
    input  wire                     sbautoincrement_i,
    input  wire [2:0]               sbaccess_i,

    input  wire                     sbreadondata_i,
    input  wire [31:0]              sbdata_i,
    input  wire                     sbdata_read_valid_i,
    input  wire                     sbdata_write_valid_i,

    output wire [31:0]              sbdata_o,
    output wire                     sbdata_valid_o,

    output wire                     sbbusy_o,
    output wire [2:0]               sberror_o,

    output wire                     master_req_o,
    input  wire                     master_gnt_i,
    input  wire                     master_rvalid_i,
    output wire                     master_we_o,
    output wire [3:0]               master_be_o,
    output wire [31:0]              master_addr_o,
    output wire [31:0]              master_wdata_o,
    input  wire [31:0]              master_rdata_i,
    input  wire                     master_err_i

    );

    localparam S_IDLE       = 4'b0001;
    localparam S_READ       = 4'b0010;
    localparam S_WAIT       = 4'b0100;
    localparam S_WRITE      = 4'b1000;

    reg[3:0] state_d, state_q;
    reg[2:0] sberror;
    reg[3:0] be_mask;
    reg[1:0] be_index;

    reg master_req;
    reg master_we;
    reg[3:0] master_be;
    reg[31:0] master_addr;
    reg[31:0] master_wdata;
    reg[31:0] sbaddress;

    wire[31:0] sbaddress_new;

    assign sbaddress_new = sbaddress_i + (32'h1 << sbaccess_i);

    assign sbbusy_o = (state_q != S_IDLE);

    always @ (*) begin
        be_mask = 4'b0;
        be_index = sbaddress_i[1:0];

        // generate byte enable mask
        case (sbaccess_i)
            3'b000: begin
                be_mask[be_index] = 1'b1;
            end

            3'b001: begin
                if (be_index == 2'h0) begin
                    be_mask[1:0] = 2'b11;
                end else if (be_index == 2'h2) begin
                    be_mask[3:2] = 2'b11;
                end
            end

            3'b010: begin
                be_mask = 4'b1111;
            end

            default:;
        endcase
    end

    // 访存状态机
    always @ (*) begin
        state_d = state_q;

        sbaddress = sbaddress_i;

        master_addr = sbaddress_i;
        master_wdata = sbdata_i;
        master_req = 1'b0;
        master_be = 4'b0;
        master_we = 1'b0;

        sberror = 3'b0;

        case (state_q)
            S_IDLE: begin
                // debugger requested a read
                if (sbaddress_write_valid_i && sbreadonaddr_i) begin
                    state_d = S_READ;
                end
                // debugger requested a write
                if (sbdata_write_valid_i) begin
                    state_d = S_WRITE;
                end
                // perform another read
                if (sbdata_read_valid_i && sbreadondata_i) begin
                    state_d = S_READ;
                end
            end

            // 读内存
            S_READ: begin
                master_req = 1'b1;
                master_be = 4'b1111;
                if (master_gnt_i) begin
                    state_d = S_WAIT;
                end
            end

            // 写内存
            S_WRITE: begin
                master_req = 1'b1;
                master_be = be_mask;
                master_we = 1'b1;
                if (master_gnt_i) begin
                    state_d = S_WAIT;
                end
            end

            // 等待读写完成
            S_WAIT: begin
                if (master_rvalid_i) begin
                    state_d = S_IDLE;
                    if (sbautoincrement_i) begin
                        sbaddress = sbaddress_new;
                    end
                end
            end

            default: state_d = S_IDLE;
        endcase

        if ((sbaccess_i > 3'h2) & (state_q != S_IDLE)) begin
            master_req = 1'b0;
            state_d = S_IDLE;
            sberror = 3'h3;
        end
    end

    assign master_req_o     = master_req;
    assign master_we_o      = master_we;
    assign master_be_o      = master_be;
    assign master_addr_o    = master_addr;
    assign master_wdata_o   = master_wdata;

    assign sbdata_valid_o   = master_rvalid_i & (state_q == S_WAIT);
    assign sbdata_o         = master_rdata_i;
    assign sberror_o        = sberror;
    assign sbaddress_o      = sbaddress;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= S_IDLE;
        end else begin
            state_q <= state_d;
        end
    end

endmodule
