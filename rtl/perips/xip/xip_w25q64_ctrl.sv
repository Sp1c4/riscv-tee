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

module xip_w25q64_ctrl(
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic        req_i,
    input  logic [1:0]  op_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] wdata_i,
    output logic        valid_o,
    output logic [31:0] rdata_o,

    output logic        spi_clk_o,
    output logic        spi_clk_oe_o,
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
    output logic        spi_dq3_oe_o
    );

    // SPI模式
    localparam MODE_STAND_SPI = 2'b00;
    localparam MODE_DUAL_SPI  = 2'b01;
    localparam MODE_QUAD_SPI  = 2'b10;
    // 数据宽度
    localparam SPI_DATA_WIDTH_8  = 2'b00;
    localparam SPI_DATA_WIDTH_16 = 2'b01;
    localparam SPI_DATA_WIDTH_24 = 2'b10;
    localparam SPI_DATA_WIDTH_32 = 2'b11;
    // 2分频
    localparam SPI_CLK_DIV = 3'd1;
    // SPI极性
    localparam SPI_CPOL_CPHA = 2'b00;

    localparam OP_READ         = 2'b00;
    localparam OP_WRITE        = 2'b01;
    localparam OP_SECTOR_ERASE = 2'b10;
    localparam OP_QUAD_ENABLE  = 2'b11;

    localparam STATE_NUM        = 16;
    localparam S_IDLE           = 16'h001;
    localparam S_SS_LOW         = 16'h002;
    localparam S_SS_HIGH        = 16'h004;
    localparam S_WRITE_ENABLE   = 16'h008;
    localparam S_WRITE_DISABLE  = 16'h010;
    localparam S_SECTOR_ERASE   = 16'h020;
    localparam S_PAGE_PROGRAM   = 16'h040;
    localparam S_WRITE_DATA     = 16'h080;
    localparam S_READ_DATA      = 16'h100;
    localparam S_READ32         = 16'h200;
    localparam S_READ_STATUS    = 16'h400;
    localparam S_CHECK_WIP      = 16'h800;
    localparam S_QUAD_ENABLE    = 16'h1000;
    localparam S_READ8          = 16'h2000;
    localparam S_QUAD_WRITE_ADDR= 16'h4000;
    localparam S_READ_DUMMY     = 16'h8000;

    logic [STATE_NUM-1:0] state_d, state_q;
    logic [STATE_NUM-1:0] next_state_d, next_state_q;
    logic [31:0] addr_d, addr_q;
    logic [31:0] wdata_d, wdata_q;
    logic [1:0] op_d, op_q;
    logic spi_ss_o_d, spi_ss_o_q;

    logic        start_d;
    logic        read_d;
    logic [1:0]  spi_mode_d;
    logic [1:0]  cp_mode_d;
    logic [1:0]  data_width_d;
    logic [31:0] data_d;
    logic [2:0]  div_ratio_d;
    logic        msb_first_d;

    logic spi_idle;
    logic spi_valid;
    logic [31:0] spi_data_out;

    always_comb begin
        state_d      = state_q;
        next_state_d = next_state_q;
        addr_d       = addr_q;
        wdata_d      = wdata_q;
        op_d         = op_q;
        spi_ss_o_d   = spi_ss_o_q;

        start_d      = '0;
        read_d       = '0;
        spi_mode_d   = '0;
        data_width_d = '0;
        data_d       = '0;
        cp_mode_d    = SPI_CPOL_CPHA;
        div_ratio_d  = SPI_CLK_DIV;
        msb_first_d  = 1'b1;

        case (state_q)
            S_IDLE: begin
                spi_ss_o_d = 1'b1;
                if (req_i) begin
                    addr_d = addr_i;
                    op_d = op_i;
                    wdata_d = wdata_i;
                    state_d = S_SS_LOW;
                    if ((op_i == OP_WRITE) | (op_i == OP_SECTOR_ERASE) | (op_i == OP_QUAD_ENABLE)) begin
                        next_state_d = S_WRITE_ENABLE;
                    end else begin
                        next_state_d = S_READ_DATA;
                    end
                end
            end

            S_SS_LOW: begin
                if (spi_idle) begin
                    spi_ss_o_d = 1'b0;
                    state_d = next_state_q;
                end
            end

            S_WRITE_ENABLE: begin
                if (spi_idle) begin
                    start_d = 1'b1;
                    read_d = 1'b0;
                    spi_mode_d = MODE_STAND_SPI;
                    data_width_d = SPI_DATA_WIDTH_8;
                    data_d = 8'h06;
                    if (op_q == OP_SECTOR_ERASE) begin
                        next_state_d = S_SECTOR_ERASE;
                    end else if (op_q == OP_WRITE) begin
                        next_state_d = S_PAGE_PROGRAM;
                    end else begin
                        next_state_d = S_QUAD_ENABLE;
                    end
                    state_d = S_SS_HIGH;
                end
            end

            S_WRITE_DISABLE: begin
                if (spi_idle) begin
                    start_d = 1'b1;
                    read_d = 1'b0;
                    spi_mode_d = MODE_STAND_SPI;
                    data_width_d = SPI_DATA_WIDTH_8;
                    data_d = 8'h04;
                    state_d = S_SS_HIGH;
                    next_state_d = S_IDLE;
                end
            end

            S_QUAD_ENABLE: begin
                if (spi_idle) begin
                    start_d = 1'b1;
                    read_d = 1'b0;
                    spi_mode_d = MODE_STAND_SPI;
                    data_width_d = SPI_DATA_WIDTH_24;
                    data_d = {8'h01, 8'h00, 8'h02};
                    state_d = S_SS_HIGH;
                    next_state_d = S_READ_STATUS;
                end
            end

            S_PAGE_PROGRAM: begin
                if (spi_idle) begin
                    start_d = 1'b1;
                    read_d = 1'b0;
                    spi_mode_d = MODE_STAND_SPI;
                    data_width_d = SPI_DATA_WIDTH_32;
                    data_d = {8'h32, addr_q[23:0]};
                    state_d = S_WRITE_DATA;
                end
            end

            S_WRITE_DATA: begin
                if (spi_idle) begin
                    start_d = 1'b1;
                    read_d = 1'b0;
                    spi_mode_d = MODE_QUAD_SPI;
                    data_width_d = SPI_DATA_WIDTH_32;
                    data_d = wdata_q;
                    state_d = S_SS_HIGH;
                    next_state_d = S_READ_STATUS;
                end
            end

            S_SECTOR_ERASE: begin
                if (spi_idle) begin
                    start_d = 1'b1;
                    read_d = 1'b0;
                    spi_mode_d = MODE_STAND_SPI;
                    data_width_d = SPI_DATA_WIDTH_32;
                    data_d = {8'h20, addr_q[23:0]};
                    state_d = S_SS_HIGH;
                    next_state_d = S_READ_STATUS;
                end
            end

            S_READ_STATUS: begin
                if (spi_idle) begin
                    start_d = 1'b1;
                    read_d = 1'b0;
                    spi_mode_d = MODE_STAND_SPI;
                    data_width_d = SPI_DATA_WIDTH_8;
                    data_d = 8'h05;
                    state_d = S_READ8;
                    next_state_d = S_CHECK_WIP;
                end
            end

            S_READ8: begin
                if (spi_idle) begin
                    start_d = 1'b1;
                    read_d = 1'b1;
                    spi_mode_d = MODE_STAND_SPI;
                    data_width_d = SPI_DATA_WIDTH_8;
                    state_d = S_SS_HIGH;
                end
            end

            S_CHECK_WIP: begin
                if (spi_idle) begin
                    // flash is in WIP
                    if (spi_data_out[0]) begin
                        state_d = S_SS_HIGH;
                        next_state_d = S_READ_STATUS;
                    end else begin
                        state_d = S_SS_HIGH;
                        state_d = S_WRITE_DISABLE;
                    end
                end
            end

            S_READ_DATA: begin
                if (spi_idle) begin
                    start_d = 1'b1;
                    read_d = 1'b0;
                    spi_mode_d = MODE_STAND_SPI;
                    data_width_d = SPI_DATA_WIDTH_8;
                    data_d = 8'hEB;
                    state_d = S_QUAD_WRITE_ADDR;
                    next_state_d = S_IDLE;
                end
            end

            S_QUAD_WRITE_ADDR: begin
                if (spi_idle) begin
                    start_d = 1'b1;
                    read_d = 1'b0;
                    spi_mode_d = MODE_QUAD_SPI;
                    data_width_d = SPI_DATA_WIDTH_32;
                    data_d = {addr_q[23:0], 8'h00};
                    state_d = S_READ_DUMMY;
                    next_state_d = S_IDLE;
                end
            end

            S_READ_DUMMY: begin
                if (spi_idle) begin
                    start_d = 1'b1;
                    read_d = 1'b1;
                    spi_mode_d = MODE_QUAD_SPI;
                    data_width_d = SPI_DATA_WIDTH_16;
                    state_d = S_READ32;
                    next_state_d = S_IDLE;
                end
            end

            S_READ32: begin
                if (spi_idle) begin
                    start_d = 1'b1;
                    read_d = 1'b1;
                    spi_mode_d = MODE_QUAD_SPI;
                    data_width_d = SPI_DATA_WIDTH_32;
                    state_d = S_SS_HIGH;
                end
            end

            S_SS_HIGH: begin
                if (spi_idle) begin
                    spi_ss_o_d = 1'b1;
                    if (next_state_q != S_IDLE) begin
                        state_d = S_SS_LOW;
                    end else begin
                        state_d = S_IDLE;
                    end
                end
            end

            default: ;
        endcase
    end

    assign valid_o = (state_q == S_SS_HIGH) & spi_idle & (next_state_q == S_IDLE);
    assign rdata_o = spi_data_out;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q      <= S_IDLE;
            next_state_q <= S_IDLE;
            addr_q       <= '0;
            wdata_q      <= '0;
            op_q         <= '0;
            spi_ss_o_q   <= '0;
        end else begin
            state_q      <= state_d;
            next_state_q <= next_state_d;
            addr_q       <= addr_d;
            wdata_q      <= wdata_d;
            op_q         <= op_d;
            spi_ss_o_q   <= spi_ss_o_d;
        end
    end

    assign spi_ss_oe_o = 1'b1;
    assign spi_ss_o    = spi_ss_o_q;

    spi_master_transmit u_spi_master (
        .clk_i,
        .rst_ni,
        .start_i     (start_d),
        .read_i      (read_d),
        .spi_mode_i  (spi_mode_d),
        .cp_mode_i   (cp_mode_d),
        .data_width_i(data_width_d),
        .data_i      (data_d),
        .div_ratio_i (div_ratio_d),
        .msb_first_i (msb_first_d),
        .data_o      (spi_data_out),
        .idle_o      (spi_idle),
        .data_valid_o(spi_valid),
        .spi_clk_o,
        .spi_clk_oe_o,
        .spi_dq0_i,
        .spi_dq0_o,
        .spi_dq0_oe_o,
        .spi_dq1_i,
        .spi_dq1_o,
        .spi_dq1_oe_o,
        .spi_dq2_i,
        .spi_dq2_o,
        .spi_dq2_oe_o,
        .spi_dq3_i,
        .spi_dq3_o,
        .spi_dq3_oe_o
    );

endmodule
