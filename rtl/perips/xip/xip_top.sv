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

module xip_top (
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

    xip_core u_xip_core (
        .clk_i          (clk_i),
        .rst_ni         (rst_ni),
        .spi_clk_o      (spi_clk_o),
        .spi_clk_oe_o   (spi_clk_oe_o),
        .spi_ss_o       (spi_ss_o),
        .spi_ss_oe_o    (spi_ss_oe_o),
        .spi_dq0_i      (spi_dq0_i),
        .spi_dq0_o      (spi_dq0_o),
        .spi_dq0_oe_o   (spi_dq0_oe_o),
        .spi_dq1_i      (spi_dq1_i),
        .spi_dq1_o      (spi_dq1_o),
        .spi_dq1_oe_o   (spi_dq1_oe_o),
        .spi_dq2_i      (spi_dq2_i),
        .spi_dq2_o      (spi_dq2_o),
        .spi_dq2_oe_o   (spi_dq2_oe_o),
        .spi_dq3_i      (spi_dq3_i),
        .spi_dq3_o      (spi_dq3_o),
        .spi_dq3_oe_o   (spi_dq3_oe_o),
        .req_i          (req_i),
        .we_i           (we_i),
        .be_i           (be_i),
        .addr_i         (addr_i),
        .data_i         (data_i),
        .gnt_o          (gnt_o),
        .rvalid_o       (rvalid_o),
        .data_o         (data_o)
    );

endmodule
