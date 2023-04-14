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

module spi_top (
    input  logic        clk_i,
    input  logic        rst_ni,

    // SPI引脚信号
    input  logic        spi_clk_i,
    output logic        spi_clk_o,
    output logic        spi_clk_oe_o,
    input  logic        spi_ss_i,
    output logic        spi_ss_o,
    output logic        spi_ss_oe_o,
    input  logic        spi_dq0_i,
    output logic        spi_dq0_o,
    output logic        spi_dq0_oe_o,
    input  logic        spi_dq1_i,
    output logic        spi_dq1_o,
    output logic        spi_dq1_oe_o,
    input  logic        spi_dq2_i,
    output logic        spi_dq2_o,
    output logic        spi_dq2_oe_o,
    input  logic        spi_dq3_i,
    output logic        spi_dq3_o,
    output logic        spi_dq3_oe_o,

    // 中断信号
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

    spi_core u_spi_core (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .spi_clk_o  (spi_clk_o),
        .spi_clk_oe_o(spi_clk_oe_o),
        .spi_ss_o   (spi_ss_o),
        .spi_ss_oe_o(spi_ss_oe_o),
        .spi_dq0_i  (spi_dq0_i),
        .spi_dq0_o  (spi_dq0_o),
        .spi_dq0_oe_o(spi_dq0_oe_o),
        .spi_dq1_i  (spi_dq1_i),
        .spi_dq1_o  (spi_dq1_o),
        .spi_dq1_oe_o(spi_dq1_oe_o),
        .spi_dq2_i  (spi_dq2_i),
        .spi_dq2_o  (spi_dq2_o),
        .spi_dq2_oe_o(spi_dq2_oe_o),
        .spi_dq3_i  (spi_dq3_i),
        .spi_dq3_o  (spi_dq3_o),
        .spi_dq3_oe_o(spi_dq3_oe_o),
        .irq_o      (irq_o),
        .reg_we_i   (we),
        .reg_re_i   (re),
        .reg_wdata_i(data_i),
        .reg_be_i   (be_i),
        .reg_addr_i (addr),
        .reg_rdata_o(reg_rdata)
    );

endmodule
