 /*                                                                      
 Copyright 2023 Blue Liang, liangkangnan@163.com
                                                                         
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


module bootrom_top(
    input  wire        clk_i,
    input  wire        rst_ni,

    input  wire        req_i,
    input  wire        we_i,
    input  wire [ 3:0] be_i,
    input  wire [31:0] addr_i,
    input  wire [31:0] data_i,
    output wire        gnt_o,
    output wire        rvalid_o,
	output wire [31:0] data_o
    );

    localparam RomSize = 5;

    wire [RomSize-1:0][31:0] mem;

    assign mem = {
        32'h0000006f,
        32'h000500e7,
        32'h02000537,
        32'h0005a023,
        32'h02c005b7
    };

    reg [5:0] addr_q;

    always @(posedge clk_i) begin
        if (req_i) begin
            addr_q <= addr_i[7:2];
        end
    end

    reg rvalid_q;

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rvalid_q <= 1'b0;
        end else begin
            rvalid_q <= req_i;
        end
    end

    reg[31:0] rdata;

    always @(*) begin
        rdata = 32'h0;
        if (addr_q < 6'd38) begin
            rdata = mem[addr_q];
        end
    end

    assign gnt_o    = req_i;
    assign data_o   = rdata;
    assign rvalid_o = rvalid_q;

endmodule
