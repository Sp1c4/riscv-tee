 /*                                                                      
 Copyright 2020 Blue Liang, liangkangnan@163.com
                                                                         
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

`include "defines.sv"

// 复位控制模块
module rst_gen #(
    parameter RESET_FIFO_DEPTH = 5
    )(

    input wire clk,
    input wire rst_ni,

    output wire rst_no

    );

    reg[RESET_FIFO_DEPTH-1:0] synch_regs_q;

    always @ (posedge clk or negedge rst_ni) begin
        if (~rst_ni) begin
            synch_regs_q <= 0;
        end else begin
            synch_regs_q <= {synch_regs_q[RESET_FIFO_DEPTH-2:0], 1'b1};
        end
    end

    assign rst_no = synch_regs_q[RESET_FIFO_DEPTH-1];

endmodule
