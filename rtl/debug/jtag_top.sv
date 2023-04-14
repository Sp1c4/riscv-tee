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


module jtag_top(

    input wire                      clk_i,
    input wire                      rst_ni,

    output wire                     debug_req_o,
    output wire                     ndmreset_o,
    output wire                     halted_o,

    input wire                      jtag_tck_i,     // JTAG test clock pad
    input wire                      jtag_tdi_i,     // JTAG test data input pad
    input wire                      jtag_tms_i,     // JTAG test mode select pad
    input wire                      jtag_trst_ni,   // JTAG test reset pad
    output wire                     jtag_tdo_o,     // JTAG test data output pad

    output wire                     master_req_o,
    input  wire                     master_gnt_i,
    input  wire                     master_rvalid_i,
    output wire                     master_we_o,
    output wire [3:0]               master_be_o,
    output wire [31:0]              master_addr_o,
    output wire [31:0]              master_wdata_o,
    input  wire [31:0]              master_rdata_i,
    input  wire                     master_err_i,

    input  wire                     slave_req_i,
    input  wire                     slave_we_i,
    input  wire [31:0]              slave_addr_i,
    input  wire [3:0]               slave_be_i,
    input  wire [31:0]              slave_wdata_i,
    output wire                     slave_gnt_o,
    output wire                     slave_rvalid_o,
    output wire [31:0]              slave_rdata_o

    );

    // addr + data + op = 7 + 32 + 2 = 41
    localparam DMI_DATA_WIDTH = 41;


    wire [DMI_DATA_WIDTH-1:0]   dm_to_dmi_data;
    wire                        dm_to_dmi_valid;
    wire                        dm_to_dmi_ready;
    wire [DMI_DATA_WIDTH-1:0]   dmi_to_dm_data;
    wire                        dmi_to_dm_valid;
    wire                        dmi_to_dm_ready;

    jtag_dm #(

    ) u_jtag_dm (
        .clk            (clk_i),
        .rst_n          (rst_ni),
        .dmi_data_i     (dmi_to_dm_data),
        .dmi_valid_i    (dmi_to_dm_valid),
        .dm_ready_o     (dm_to_dmi_ready),
        .dm_data_o      (dm_to_dmi_data),
        .dm_valid_o     (dm_to_dmi_valid),
        .dmi_ready_i    (dmi_to_dm_ready),
        .debug_req_o    (debug_req_o),
        .ndmreset_o     (ndmreset_o),
        .halted_o       (halted_o),
        .master_req_o   (master_req_o),
        .master_gnt_i   (master_gnt_i),
        .master_rvalid_i(master_rvalid_i),
        .master_we_o    (master_we_o),
        .master_be_o    (master_be_o),
        .master_addr_o  (master_addr_o),
        .master_wdata_o (master_wdata_o),
        .master_rdata_i (master_rdata_i),
        .master_err_i   (master_err_i),
        .slave_req_i    (slave_req_i),
        .slave_we_i     (slave_we_i),
        .slave_addr_i   (slave_addr_i),
        .slave_be_i     (slave_be_i),
        .slave_wdata_i  (slave_wdata_i),
        .slave_gnt_o    (slave_gnt_o),
        .slave_rvalid_o (slave_rvalid_o),
        .slave_rdata_o  (slave_rdata_o)
    );

    wire [DMI_DATA_WIDTH-1:0]   dtm_to_dmi_data;
    wire                        dtm_to_dmi_valid;
    wire                        dtm_to_dmi_ready;
    wire [DMI_DATA_WIDTH-1:0]   dmi_to_dtm_data;
    wire                        dmi_to_dtm_valid;
    wire                        dmi_to_dtm_ready;

    jtag_dmi #(

    ) u_jtag_dmi (
        .jtag_tck_i     (jtag_tck_i),
        .jtag_trst_ni   (jtag_trst_ni),
        .jtag_data_i    (dtm_to_dmi_data),
        .jtag_valid_i   (dtm_to_dmi_valid),
        .jtag_ready_o   (dmi_to_dtm_ready),
        .jtag_data_o    (dmi_to_dtm_data),
        .jtag_valid_o   (dmi_to_dtm_valid),
        .jtag_ready_i   (dtm_to_dmi_ready),
        .clk_i          (clk_i),
        .rst_ni         (rst_ni),
        .core_data_i    (dm_to_dmi_data),
        .core_valid_i   (dm_to_dmi_valid),
        .core_ready_o   (dmi_to_dm_ready),
        .core_data_o    (dmi_to_dm_data),
        .core_valid_o   (dmi_to_dm_valid),
        .core_ready_i   (dm_to_dmi_ready)
    );

    wire                        tap_to_dtm_req;
    wire [DMI_DATA_WIDTH-1:0]   tap_to_dtm_data;
    wire [DMI_DATA_WIDTH-1:0]   dtm_to_tap_data;
    wire [31:0]                 idcode;
    wire [31:0]                 dtmcs;
    wire                        dmireset;

    jtag_dtm #(

    ) u_jtag_dtm (
        .jtag_tck_i     (jtag_tck_i),
        .jtag_trst_ni   (jtag_trst_ni),
        .dtm_data_o     (dtm_to_dmi_data),
        .dtm_valid_o    (dtm_to_dmi_valid),
        .dmi_ready_i    (dmi_to_dtm_ready),
        .dmi_data_i     (dmi_to_dtm_data),
        .dmi_valid_i    (dmi_to_dtm_valid),
        .dtm_ready_o    (dtm_to_dmi_ready),
        .tap_req_i      (tap_to_dtm_req),
        .tap_data_i     (tap_to_dtm_data),
        .dmireset_i     (dmireset),
        .data_o         (dtm_to_tap_data),
        .idcode_o       (idcode),
        .dtmcs_o        (dtmcs)
    );

    jtag_tap #(

    ) u_jtag_tap (
        .jtag_tck_i     (jtag_tck_i),
        .jtag_tdi_i     (jtag_tdi_i),
        .jtag_tms_i     (jtag_tms_i),
        .jtag_trst_ni   (jtag_trst_ni),
        .jtag_tdo_o     (jtag_tdo_o),
        .tap_req_o      (tap_to_dtm_req),
        .tap_data_o     (tap_to_dtm_data),
        .dmireset_o     (dmireset),
        .dtm_data_i     (dtm_to_tap_data),
        .idcode_i       (idcode),
        .dtmcs_i        (dtmcs)
    );

endmodule
