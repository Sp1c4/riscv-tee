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

module clk_div #(
    parameter int unsigned RATIO_WIDTH = 32
    )(
    input  logic                    clk_i,   // clock
    input  logic                    rst_ni,  // asynchronous reset active low
    input  logic                    en_i,    // enable clock divider
    input  logic [RATIO_WIDTH-1:0]  ratio_i, // divider ratio
    output logic                    clk_o    // divided clock out
    );

    logic [RATIO_WIDTH-1:0] counter_q;
    logic clk_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            clk_q <= 1'b0;
            counter_q <= '0;
        end else begin
            clk_q <= 1'b0;
            if (en_i) begin
                if (counter_q == (ratio_i - 1)) begin
                    clk_q <= 1'b1;
                    counter_q <= '0;
                end else begin
                    counter_q <= counter_q + 1;
                end
            end
        end
    end

    assign clk_o = clk_q;

endmodule
