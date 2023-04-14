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

module csr #(
    parameter RESET_VAL = 32'h0,
    parameter WIDTH     = 32
    )(

    input  wire             clk,
    input  wire             rst_n,

    input  wire [WIDTH-1:0] wdata_i,
    input  wire             we_i,
    output wire [WIDTH-1:0] rdata_o

    );

    reg[WIDTH-1:0] rdata_q;

    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata_q <= RESET_VAL;
        end else if (we_i) begin
            rdata_q <= wdata_i;
        end
    end

    assign rdata_o = rdata_q;

endmodule
