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


module jtag_dmi #(
    parameter DATA_WIDTH = 41
    )(

    // JTAG side(master side)
    input  wire                     jtag_tck_i,
    input  wire                     jtag_trst_ni,

    input  wire [DATA_WIDTH-1:0]    jtag_data_i,
    input  wire                     jtag_valid_i,
    output wire                     jtag_ready_o,

    output wire [DATA_WIDTH-1:0]    jtag_data_o,
    output wire                     jtag_valid_o,
    input  wire                     jtag_ready_i,

    // Core side(slave side)
    input  wire                     clk_i,
    input  wire                     rst_ni,

    input  wire [DATA_WIDTH-1:0]    core_data_i,
    input  wire                     core_valid_i,
    output wire                     core_ready_o,

    output wire [DATA_WIDTH-1:0]    core_data_o,
    output wire                     core_valid_o,
    input  wire                     core_ready_i

    );

    cdc_2phase #(.DATA_WIDTH(DATA_WIDTH)) u_cdc_req (
        .src_rst_ni  ( jtag_trst_ni     ),
        .src_clk_i   ( jtag_tck_i       ),
        .src_data_i  ( jtag_data_i      ),
        .src_valid_i ( jtag_valid_i     ),
        .src_ready_o ( jtag_ready_o     ),

        .dst_rst_ni  ( rst_ni           ),
        .dst_clk_i   ( clk_i            ),
        .dst_data_o  ( core_data_o      ),
        .dst_valid_o ( core_valid_o     ),
        .dst_ready_i ( core_ready_i     )
    );

    cdc_2phase #(.DATA_WIDTH(DATA_WIDTH)) u_cdc_resp (
        .src_rst_ni  ( rst_ni           ),
        .src_clk_i   ( clk_i            ),
        .src_data_i  ( core_data_i      ),
        .src_valid_i ( core_valid_i     ),
        .src_ready_o ( core_ready_o     ),

        .dst_rst_ni  ( jtag_trst_ni     ),
        .dst_clk_i   ( jtag_tck_i       ),
        .dst_data_o  ( jtag_data_o      ),
        .dst_valid_o ( jtag_valid_o     ),
        .dst_ready_i ( jtag_ready_i     )
    );

endmodule
