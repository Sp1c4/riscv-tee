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

// SS信号由上层模块控制
module spi_master_transmit (
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic        start_i,         // 开始传输
    input  logic        read_i,          // 0: write, 1: read
    input  logic [1:0]  spi_mode_i,      // 0: Standard SPI, 1: Dual SPI, 2: Quad SPI, 3: Standard SPI
    input  logic [1:0]  cp_mode_i,       // [1]表示CPOL, [0]表示CPHA
    input  logic [1:0]  data_width_i,    // 数据宽度, 0: 8bits, 1: 16bits, 2: 24bits, 3: 32bits
    input  logic [31:0] data_i,          // 数据输入
    input  logic [2:0]  div_ratio_i,     // 分频比(2 ^ div_ratio_i)
    input  logic        msb_first_i,     // 1: MSB, 0: LSB
    output logic [31:0] data_o,          // 接收到的数据输出
    output logic        idle_o,          // 1: IDLE, 0: 正在传输
    output logic        data_valid_o,    // 数据输出有效标志

    // CLK
    input  logic        spi_clk_i,
    output logic        spi_clk_o,
    output logic        spi_clk_oe_o,
    // SS(slave模式使用)
    input  logic        spi_ss_i,
    // MOSI(DQ0)
    input  logic        spi_dq0_i,
    output logic        spi_dq0_o,
    output logic        spi_dq0_oe_o,
    // MISO(DQ1)
    input  logic        spi_dq1_i,
    output logic        spi_dq1_o,
    output logic        spi_dq1_oe_o,
    // DQ2
    input  logic        spi_dq2_i,
    output logic        spi_dq2_o,
    output logic        spi_dq2_oe_o,
    // DQ3
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

    localparam S_IDLE = 3'b001;
    localparam S_DATA = 3'b010;
    localparam S_END  = 3'b100;

    logic tick;

    logic [2:0] state_d, state_q;
    logic [7:0] edge_cnt_d, edge_cnt_q;
    logic [31:0] in_data_d, in_data_q;
    logic [31:0] out_data_d, out_data_q;
    logic [7:0] total_edge_cnt_d, total_edge_cnt_q;
    logic data_valid_d, data_valid_q;
    logic ready_d, ready_q;
    logic read_d, read_q;
    logic [1:0] spi_mode_d, spi_mode_q;
    logic [1:0] cp_mode_d, cp_mode_q;
    logic [1:0] data_width_d, data_width_q;
    logic [2:0] div_ratio_d, div_ratio_q;
    logic msb_first_d, msb_first_q;

    logic spi_clk_d, spi_clk_q;
    logic spi_clk_oe_d, spi_clk_oe_q;
    logic spi_dq0_d, spi_dq0_q;
    logic spi_dq0_oe_d, spi_dq0_oe_q;
    logic spi_dq1_d, spi_dq1_q;
    logic spi_dq1_oe_d, spi_dq1_oe_q;
    logic spi_dq2_d, spi_dq2_q;
    logic spi_dq2_oe_d, spi_dq2_oe_q;
    logic spi_dq3_d, spi_dq3_q;
    logic spi_dq3_oe_d, spi_dq3_oe_q;


    always_comb begin
        state_d = state_q;
        edge_cnt_d = edge_cnt_q;
        in_data_d = in_data_q;
        out_data_d = out_data_q;
        data_valid_d = data_valid_q;
        ready_d = ready_q;
        read_d = read_q;
        spi_mode_d = spi_mode_q;
        cp_mode_d = cp_mode_q;
        data_width_d = data_width_q;
        div_ratio_d = div_ratio_q;
        msb_first_d = msb_first_q;

        spi_clk_d = spi_clk_q;

        case (state_q)
            S_IDLE: begin
                spi_clk_d = cp_mode_i[1];
                data_valid_d = 1'b0;
                ready_d = 1'b1;
                if (start_i) begin
                    edge_cnt_d = '0;
                    ready_d = 1'b0;
                    read_d = read_i;
                    spi_mode_d = spi_mode_i;
                    cp_mode_d = cp_mode_i;
                    data_width_d = data_width_i;
                    div_ratio_d = div_ratio_i;
                    msb_first_d = msb_first_i;
                    state_d = S_DATA;
                    if (msb_first_i) begin
                        out_data_d = data_i;
                    end else begin
                        out_data_d[31] = data_i[0];
                        out_data_d[30] = data_i[1];
                        out_data_d[29] = data_i[2];
                        out_data_d[28] = data_i[3];
                        out_data_d[27] = data_i[4];
                        out_data_d[26] = data_i[5];
                        out_data_d[25] = data_i[6];
                        out_data_d[24] = data_i[7];
                        out_data_d[23] = data_i[8];
                        out_data_d[22] = data_i[9];
                        out_data_d[21] = data_i[10];
                        out_data_d[20] = data_i[11];
                        out_data_d[19] = data_i[12];
                        out_data_d[18] = data_i[13];
                        out_data_d[17] = data_i[14];
                        out_data_d[16] = data_i[15];
                        out_data_d[15] = data_i[16];
                        out_data_d[14] = data_i[17];
                        out_data_d[13] = data_i[18];
                        out_data_d[12] = data_i[19];
                        out_data_d[11] = data_i[20];
                        out_data_d[10] = data_i[21];
                        out_data_d[9] = data_i[22];
                        out_data_d[8] = data_i[23];
                        out_data_d[7] = data_i[24];
                        out_data_d[6] = data_i[25];
                        out_data_d[5] = data_i[26];
                        out_data_d[4] = data_i[27];
                        out_data_d[3] = data_i[28];
                        out_data_d[2] = data_i[29];
                        out_data_d[1] = data_i[30];
                        out_data_d[0] = data_i[31];
                    end
                end
            end

            S_DATA: begin
                if (tick) begin
                    spi_clk_d = ~spi_clk_q;
                    edge_cnt_d = edge_cnt_q + 1'b1;
                    // 第奇数个沿(1, 3, 5...)
                    if (!edge_cnt_q[0]) begin
                        // 出数据
                        if (cp_mode_q[0]) begin
                            // 第一个bit(s)在IDLE状态时已经送出了
                            if (edge_cnt_q != 8'd0) begin
                                case (spi_mode_q)
                                    MODE_STAND_SPI: begin
                                        if (data_width_q == SPI_DATA_WIDTH_16) begin
                                            out_data_d = {out_data_q[14:0], 1'b0};
                                        end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                                            out_data_d = {out_data_q[30:0], 1'b0};
                                        end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                                            out_data_d = {out_data_q[22:0], 1'b0};
                                        end else begin
                                            out_data_d = {out_data_q[6:0], 1'b0};
                                        end
                                    end
                                    MODE_DUAL_SPI : begin
                                        if (data_width_q == SPI_DATA_WIDTH_16) begin
                                            out_data_d = {out_data_q[13:0], 2'b0};
                                        end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                                            out_data_d = {out_data_q[29:0], 2'b0};
                                        end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                                            out_data_d = {out_data_q[21:0], 2'b0};
                                        end else begin
                                            out_data_d = {out_data_q[5:0], 2'b0};
                                        end
                                    end
                                    MODE_QUAD_SPI : begin
                                        if (data_width_q == SPI_DATA_WIDTH_16) begin
                                            out_data_d = {out_data_q[11:0], 4'b0};
                                        end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                                            out_data_d = {out_data_q[27:0], 4'b0};
                                        end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                                            out_data_d = {out_data_q[19:0], 4'b0};
                                        end else begin
                                            out_data_d = {out_data_q[3:0], 4'b0};
                                        end
                                    end
                                    default: out_data_d = {out_data_q[6:0], 1'b0};
                                endcase
                            end
                        // 采数据
                        end else begin
                            case (spi_mode_q)
                                MODE_STAND_SPI: begin
                                    if (data_width_q == SPI_DATA_WIDTH_16) begin
                                        in_data_d = {in_data_q[14:0], spi_dq1_i};
                                    end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                                        in_data_d = {in_data_q[30:0], spi_dq1_i};
                                    end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                                        in_data_d = {in_data_q[22:0], spi_dq1_i};
                                    end else begin
                                        in_data_d = {in_data_q[6:0], spi_dq1_i};
                                    end
                                end
                                MODE_DUAL_SPI : begin
                                    if (data_width_q == SPI_DATA_WIDTH_16) begin
                                        in_data_d = {in_data_q[13:0], spi_dq1_i, spi_dq0_i};
                                    end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                                        in_data_d = {in_data_q[29:0], spi_dq1_i, spi_dq0_i};
                                    end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                                        in_data_d = {in_data_q[21:0], spi_dq1_i, spi_dq0_i};
                                    end else begin
                                        in_data_d = {in_data_q[5:0], spi_dq1_i, spi_dq0_i};
                                    end
                                end
                                MODE_QUAD_SPI : begin
                                    if (data_width_q == SPI_DATA_WIDTH_16) begin
                                        in_data_d = {in_data_q[11:0], spi_dq3_i, spi_dq2_i, spi_dq1_i, spi_dq0_i};
                                    end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                                        in_data_d = {in_data_q[27:0], spi_dq3_i, spi_dq2_i, spi_dq1_i, spi_dq0_i};
                                    end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                                        in_data_d = {in_data_q[19:0], spi_dq3_i, spi_dq2_i, spi_dq1_i, spi_dq0_i};
                                    end else begin
                                        in_data_d = {in_data_q[3:0], spi_dq3_i, spi_dq2_i, spi_dq1_i, spi_dq0_i};
                                    end
                                end
                                default: in_data_d = {in_data_q[6:0], spi_dq1_i};
                            endcase
                        end
                    // 第偶数个沿(2, 4, 6...)
                    end else begin
                        // 出数据
                        if (!cp_mode_q[0]) begin
                            case (spi_mode_q)
                                MODE_STAND_SPI: begin
                                    if (data_width_q == SPI_DATA_WIDTH_16) begin
                                        out_data_d = {out_data_q[14:0], 1'b0};
                                    end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                                        out_data_d = {out_data_q[30:0], 1'b0};
                                    end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                                        out_data_d = {out_data_q[22:0], 1'b0};
                                    end else begin
                                        out_data_d = {out_data_q[6:0], 1'b0};
                                    end
                                end
                                MODE_DUAL_SPI : begin
                                    if (data_width_q == SPI_DATA_WIDTH_16) begin
                                        out_data_d = {out_data_q[13:0], 2'b0};
                                    end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                                        out_data_d = {out_data_q[29:0], 2'b0};
                                    end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                                        out_data_d = {out_data_q[21:0], 2'b0};
                                    end else begin
                                        out_data_d = {out_data_q[5:0], 2'b0};
                                    end
                                end
                                MODE_QUAD_SPI : begin
                                    if (data_width_q == SPI_DATA_WIDTH_16) begin
                                        out_data_d = {out_data_q[11:0], 4'b0};
                                    end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                                        out_data_d = {out_data_q[27:0], 4'b0};
                                    end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                                        out_data_d = {out_data_q[19:0], 4'b0};
                                    end else begin
                                        out_data_d = {out_data_q[3:0], 4'b0};
                                    end
                                end
                                default: out_data_d = {out_data_q[6:0], 1'b0};
                            endcase
                        // 采数据
                        end else begin
                            case (spi_mode_q)
                                MODE_STAND_SPI: begin
                                    if (data_width_q == SPI_DATA_WIDTH_16) begin
                                        in_data_d = {in_data_q[14:0], spi_dq1_i};
                                    end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                                        in_data_d = {in_data_q[30:0], spi_dq1_i};
                                    end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                                        in_data_d = {in_data_q[22:0], spi_dq1_i};
                                    end else begin
                                        in_data_d = {in_data_q[6:0], spi_dq1_i};
                                    end
                                end
                                MODE_DUAL_SPI : begin
                                    if (data_width_q == SPI_DATA_WIDTH_16) begin
                                        in_data_d = {in_data_q[13:0], spi_dq1_i, spi_dq0_i};
                                    end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                                        in_data_d = {in_data_q[29:0], spi_dq1_i, spi_dq0_i};
                                    end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                                        in_data_d = {in_data_q[21:0], spi_dq1_i, spi_dq0_i};
                                    end else begin
                                        in_data_d = {in_data_q[5:0], spi_dq1_i, spi_dq0_i};
                                    end
                                end
                                MODE_QUAD_SPI : begin
                                    if (data_width_q == SPI_DATA_WIDTH_16) begin
                                        in_data_d = {in_data_q[11:0], spi_dq3_i, spi_dq2_i, spi_dq1_i, spi_dq0_i};
                                    end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                                        in_data_d = {in_data_q[27:0], spi_dq3_i, spi_dq2_i, spi_dq1_i, spi_dq0_i};
                                    end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                                        in_data_d = {in_data_q[19:0], spi_dq3_i, spi_dq2_i, spi_dq1_i, spi_dq0_i};
                                    end else begin
                                        in_data_d = {in_data_q[3:0], spi_dq3_i, spi_dq2_i, spi_dq1_i, spi_dq0_i};
                                    end
                                end
                                default: in_data_d = {in_data_q[6:0], spi_dq1_i};
                            endcase
                        end
                    end
                    // 最后一个沿
                    if (edge_cnt_q == total_edge_cnt_q) begin
                        state_d = S_END;
                    end
                end
            end

            S_END: begin
                if (tick) begin
                    state_d = S_IDLE;
                    ready_d = 1'b1;
                    data_valid_d = 1'b1;
                    if (!msb_first_q) begin
                        in_data_d[0] = in_data_q[31];
                        in_data_d[1] = in_data_q[30];
                        in_data_d[2] = in_data_q[29];
                        in_data_d[3] = in_data_q[28];
                        in_data_d[4] = in_data_q[27];
                        in_data_d[5] = in_data_q[26];
                        in_data_d[6] = in_data_q[25];
                        in_data_d[7] = in_data_q[24];
                        in_data_d[8] = in_data_q[23];
                        in_data_d[9] = in_data_q[22];
                        in_data_d[10] = in_data_q[21];
                        in_data_d[11] = in_data_q[20];
                        in_data_d[12] = in_data_q[19];
                        in_data_d[13] = in_data_q[18];
                        in_data_d[14] = in_data_q[17];
                        in_data_d[15] = in_data_q[16];
                        in_data_d[16] = in_data_q[15];
                        in_data_d[17] = in_data_q[14];
                        in_data_d[18] = in_data_q[13];
                        in_data_d[19] = in_data_q[12];
                        in_data_d[20] = in_data_q[11];
                        in_data_d[21] = in_data_q[10];
                        in_data_d[22] = in_data_q[9];
                        in_data_d[23] = in_data_q[8];
                        in_data_d[24] = in_data_q[7];
                        in_data_d[25] = in_data_q[6];
                        in_data_d[26] = in_data_q[5];
                        in_data_d[27] = in_data_q[4];
                        in_data_d[28] = in_data_q[3];
                        in_data_d[29] = in_data_q[2];
                        in_data_d[30] = in_data_q[1];
                        in_data_d[31] = in_data_q[0];
                    end
                end
            end

            default: ;
        endcase
    end

    // 沿个数
    always_comb begin
        total_edge_cnt_d = 8'd63;

        case (spi_mode_q)
            MODE_STAND_SPI: begin
                if (data_width_q == SPI_DATA_WIDTH_16) begin
                    total_edge_cnt_d = 8'd31;
                end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                    total_edge_cnt_d = 8'd63;
                end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                    total_edge_cnt_d = 8'd47;
                end else begin
                    total_edge_cnt_d = 8'd15;
                end
            end
            MODE_DUAL_SPI : begin
                if (data_width_q == SPI_DATA_WIDTH_16) begin
                    total_edge_cnt_d = 8'd15;
                end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                    total_edge_cnt_d = 8'd31;
                end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                    total_edge_cnt_d = 8'd23;
                end else begin
                    total_edge_cnt_d = 8'd7;
                end
            end
            MODE_QUAD_SPI : begin
                if (data_width_q == SPI_DATA_WIDTH_16) begin
                    total_edge_cnt_d = 8'd7;
                end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                    total_edge_cnt_d = 8'd15;
                end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                    total_edge_cnt_d = 8'd11;
                end else begin
                    total_edge_cnt_d = 8'd3;
                end
            end
            default: ;
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q          <= S_IDLE;
            edge_cnt_q       <= '0;
            total_edge_cnt_q <= '0;
            in_data_q        <= '0;
            out_data_q       <= '0;
            data_valid_q     <= '0;
            ready_q          <= '0;
            read_q           <= '0;
            spi_mode_q       <= '0;
            cp_mode_q        <= '0;
            data_width_q     <= '0;
            div_ratio_q      <= '0;
            msb_first_q      <= '0;
        end else begin
            state_q          <= state_d;
            edge_cnt_q       <= edge_cnt_d;
            total_edge_cnt_q <= total_edge_cnt_d;
            in_data_q        <= in_data_d;
            out_data_q       <= out_data_d;
            data_valid_q     <= data_valid_d;
            ready_q          <= ready_d;
            read_q           <= read_d;
            spi_mode_q       <= spi_mode_d;
            cp_mode_q        <= cp_mode_d;
            data_width_q     <= data_width_d;
            div_ratio_q      <= div_ratio_d;
            msb_first_q      <= msb_first_d;
        end
    end

    // 输入输出引脚
    always_comb begin
        spi_dq0_d = 1'b0;
        spi_dq1_d = 1'b0;
        spi_dq2_d = 1'b0;
        spi_dq3_d = 1'b0;
        spi_dq0_oe_d = 1'b0;
        spi_dq1_oe_d = 1'b0;
        spi_dq2_oe_d = 1'b0;
        spi_dq3_oe_d = 1'b0;

        case (spi_mode_q)
            MODE_STAND_SPI: begin
                if (data_width_q == SPI_DATA_WIDTH_16) begin
                    spi_dq0_d = out_data_d[15];
                end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                    spi_dq0_d = out_data_d[31];
                end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                    spi_dq0_d = out_data_d[23];
                end else begin
                    spi_dq0_d = out_data_d[7];
                end
                spi_dq0_oe_d = 1'b1;
            end

            MODE_DUAL_SPI: begin
                if (data_width_q == SPI_DATA_WIDTH_16) begin
                    spi_dq0_d = out_data_d[14];
                    spi_dq1_d = out_data_d[15];
                end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                    spi_dq0_d = out_data_d[30];
                    spi_dq1_d = out_data_d[31];
                end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                    spi_dq0_d = out_data_d[22];
                    spi_dq1_d = out_data_d[23];
                end else begin
                    spi_dq0_d = out_data_d[6];
                    spi_dq1_d = out_data_d[7];
                end
                if (read_q) begin
                    spi_dq0_oe_d = 1'b0;
                    spi_dq1_oe_d = 1'b0;
                end else begin
                    spi_dq0_oe_d = 1'b1;
                    spi_dq1_oe_d = 1'b1;
                end
            end

            MODE_QUAD_SPI: begin
                if (data_width_q == SPI_DATA_WIDTH_16) begin
                    spi_dq0_d = out_data_d[12];
                    spi_dq1_d = out_data_d[13];
                    spi_dq2_d = out_data_d[14];
                    spi_dq3_d = out_data_d[15];
                end else if (data_width_q == SPI_DATA_WIDTH_32) begin
                    spi_dq0_d = out_data_d[28];
                    spi_dq1_d = out_data_d[29];
                    spi_dq2_d = out_data_d[30];
                    spi_dq3_d = out_data_d[31];
                end else if (data_width_q == SPI_DATA_WIDTH_24) begin
                    spi_dq0_d = out_data_d[20];
                    spi_dq1_d = out_data_d[21];
                    spi_dq2_d = out_data_d[22];
                    spi_dq3_d = out_data_d[23];
                end else begin
                    spi_dq0_d = out_data_d[4];
                    spi_dq1_d = out_data_d[5];
                    spi_dq2_d = out_data_d[6];
                    spi_dq3_d = out_data_d[7];
                end
                if (read_q) begin
                    spi_dq0_oe_d = 1'b0;
                    spi_dq1_oe_d = 1'b0;
                    spi_dq2_oe_d = 1'b0;
                    spi_dq3_oe_d = 1'b0;
                end else begin
                    spi_dq0_oe_d = 1'b1;
                    spi_dq1_oe_d = 1'b1;
                    spi_dq2_oe_d = 1'b1;
                    spi_dq3_oe_d = 1'b1;
                end
            end

            default: ;
        endcase
    end

    assign spi_clk_oe_d = 1'b1;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            spi_clk_q    <= '0;
            spi_clk_oe_q <= '0;
            spi_dq0_q    <= '0;
            spi_dq0_oe_q <= '0;
            spi_dq1_q    <= '0;
            spi_dq1_oe_q <= '0;
            spi_dq2_q    <= '0;
            spi_dq2_oe_q <= '0;
            spi_dq3_q    <= '0;
            spi_dq3_oe_q <= '0;
        end else begin
            spi_clk_q    <= spi_clk_d;
            spi_clk_oe_q <= spi_clk_oe_d;
            spi_dq0_q    <= spi_dq0_d;
            spi_dq0_oe_q <= spi_dq0_oe_d;
            spi_dq1_q    <= spi_dq1_d;
            spi_dq1_oe_q <= spi_dq1_oe_d;
            spi_dq2_q    <= spi_dq2_d;
            spi_dq2_oe_q <= spi_dq2_oe_d;
            spi_dq3_q    <= spi_dq3_d;
            spi_dq3_oe_q <= spi_dq3_oe_d;
        end
    end

    assign data_o       = in_data_q;
    assign data_valid_o = data_valid_q;
    assign idle_o       = ready_q;

    assign spi_clk_o    = spi_clk_q;
    assign spi_clk_oe_o = spi_clk_oe_q;
    assign spi_dq0_o    = spi_dq0_q;
    assign spi_dq0_oe_o = spi_dq0_oe_q;
    assign spi_dq1_o    = spi_dq1_q;
    assign spi_dq1_oe_o = spi_dq1_oe_q;
    assign spi_dq2_o    = spi_dq2_q;
    assign spi_dq2_oe_o = spi_dq2_oe_q;
    assign spi_dq3_o    = spi_dq3_q;
    assign spi_dq3_oe_o = spi_dq3_oe_q;

    logic [15:0] ratio = 1 << div_ratio_q;

    clk_div #(
        .RATIO_WIDTH(16)
    ) u_clk_div (
        .clk_i(clk_i),
        .rst_ni(rst_ni || (~((state_q == S_IDLE) && start_i))),
        .en_i(state_q != S_IDLE),
        .ratio_i(ratio),
        .clk_o(tick)
    );

endmodule
