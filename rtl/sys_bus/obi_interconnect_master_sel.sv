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

// 从多个master之间选择一个
module obi_interconnect_master_sel #(
    parameter int unsigned MASTERS = 3,
    parameter MASTER_BITS = MASTERS == 1 ? 1 : $clog2(MASTERS)
    )(
    input   logic                       clk_i,
    input   logic                       rst_ni,

    input   logic                       master_req_i     [MASTERS],
    input   logic     [       31:0]     master_addr_i    [MASTERS],
    input   logic     [       31:0]     slave_addr_mask_i,
    input   logic     [       31:0]     slave_addr_base_i,

    output  logic [MASTER_BITS-1:0]     master_sel_int_o,
    output  logic     [MASTERS-1:0]     master_sel_vec_o,
    output  logic                       granted_master_o
    );

    function integer onehot2int;
        input [MASTERS-1:0] onehot;
        integer i;

        onehot2int = 0; // prevent latch behavior

        for (i = 1; i < MASTERS; i = i + 1) begin: gen_int
            if (onehot[i]) begin
                onehot2int = i;
            end
        end
    endfunction

    genvar m;

    logic[MASTERS-1:0] master_req_vec;

    generate
        for (m = 0; m < MASTERS; m = m + 1) begin: gen_master_req_vec
            assign master_req_vec[m] = master_req_i[m] &
                                       ((master_addr_i[m] & slave_addr_mask_i) == slave_addr_base_i);
        end
    endgenerate

    logic[MASTERS-1:0] master_sel_vec;

    generate
        // 优先级仲裁机制，LSB优先级最高，MSB优先级最低
        for (m = 0; m < MASTERS; m = m + 1) begin: gen_master_sel_vec
            if (m == 0) begin: m_is_0
                assign master_sel_vec[m] = master_req_vec[0];
            end else begin: m_is_not_0
                assign master_sel_vec[m] = ~(|master_req_vec[m-1:0]) & master_req_vec[m];
            end
        end
    endgenerate

    assign master_sel_int_o = onehot2int(master_sel_vec);
    assign master_sel_vec_o = master_sel_vec;
    assign granted_master_o = |master_sel_vec;

endmodule
