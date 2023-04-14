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

module up_counter #(
    parameter int unsigned WIDTH = 4
    )(
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             clear_i,   // 同步清零
    input  logic             en_i,      // 使能，开始计数
    output logic [WIDTH-1:0] q_o,       // 当前计数值
    output logic             overflow_o // 溢出标志
    );

    logic [WIDTH:0] counter_d, counter_q;

    assign overflow_o = counter_q[WIDTH];
    assign q_o = counter_q[WIDTH-1:0];

    always_comb begin
        counter_d = counter_q;

        if (clear_i) begin
            counter_d = '0;
        end else if (en_i) begin
            counter_d = counter_q + 1'b1;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
           counter_q <= '0;
        end else begin
           counter_q <= counter_d;
        end
    end

endmodule
