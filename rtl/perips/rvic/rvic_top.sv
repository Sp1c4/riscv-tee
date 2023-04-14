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

module rvic_top (
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic [31:0] src_i,
    output logic [ 7:0] irq_id_o,
    output logic        irq_o,

    // OBI总线接口信号
    input  logic        req_i,
    input  logic        we_i,
    input  logic [ 3:0] be_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] data_i,
    output logic        gnt_o,
    output logic        rvalid_o,
    output logic [31:0] data_o
    );

    logic re;
    logic we;
    logic [31:0] addr;
    logic [31:0] reg_rdata;

    assign gnt_o = req_i;

    // 读信号
    assign re = req_i & (!we_i);
    // 写信号
    assign we = req_i & we_i;
    // 去掉基地址
    assign addr = {16'h0, addr_i[15:0]};

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rvalid_o <= '0;
            data_o <= '0;
        end else begin
            rvalid_o <= req_i;
            data_o <= reg_rdata;
        end
    end

    rvic_core u_rvic_core (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .src_i      (src_i),
        .irq_id_o   (irq_id_o),
        .irq_o      (irq_o),
        .reg_we_i   (we),
        .reg_re_i   (re),
        .reg_wdata_i(data_i),
        .reg_be_i   (be_i),
        .reg_addr_i (addr),
        .reg_rdata_o(reg_rdata)
    );

endmodule
