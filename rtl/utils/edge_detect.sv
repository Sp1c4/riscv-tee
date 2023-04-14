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

// 上升沿、下降沿检测
module edge_detect #(
    parameter int DP = 2
    )(
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        sig_i,
    output logic        sig_o,
    output logic        re_o,
    output logic        fe_o
    );

    logic sig, sig_q;

    assign sig_o =  sig_q;
    assign fe_o  = (~sig) & sig_q;
    assign re_o  =  sig & (~sig_q);

    always_ff @(posedge clk_i, negedge rst_ni) begin
        if (!rst_ni) begin
            sig_q <= 1'b0;
        end else begin
            sig_q <= sig;
        end
    end

    gen_ticks_sync #(
        .DP(DP),
        .DW(1)
    ) u_sync (
        .clk(clk_i),
        .rst_n(rst_ni),
        .din(sig_i),
        .dout(sig)
    );

endmodule
