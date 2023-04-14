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

module debug_rom (
    input  wire         clk_i,
    input  wire         req_i,
    input  wire [31:0]  addr_i,
    output wire [31:0]  rdata_o
    );

    localparam RomSize = 38;

    wire [RomSize-1:0][31:0] mem;

    assign mem = {
        32'h00000000,
        32'h7b200073,
        32'h7b202473,
        32'h7b302573,
        32'h10852423,
        32'hf1402473,
        32'ha85ff06f,
        32'h7b202473,
        32'h7b302573,
        32'h10052223,
        32'h00100073,
        32'h7b202473,
        32'h7b302573,
        32'h10052623,
        32'h00c51513,
        32'h00c55513,
        32'h00000517,
        32'hfd5ff06f,
        32'hfa041ce3,
        32'h00247413,
        32'h40044403,
        32'h00a40433,
        32'hf1402473,
        32'h02041c63,
        32'h00147413,
        32'h40044403,
        32'h00a40433,
        32'h10852023,
        32'hf1402473,
        32'h00c51513,
        32'h00c55513,
        32'h00000517,
        32'h7b351073,
        32'h7b241073,
        32'h0ff0000f,
        32'h04c0006f,
        32'h07c0006f,
        32'h00c0006f
    };

    reg [5:0] addr_q;

    always @ (posedge clk_i) begin
        if (req_i) begin
            addr_q <= addr_i[7:2];
        end
    end

    reg[31:0] rdata;

    always @ (*) begin
        rdata = 32'h0;
        if (addr_q < 6'd38) begin
            rdata = mem[addr_q];
        end
    end

    assign rdata_o = rdata;

endmodule
