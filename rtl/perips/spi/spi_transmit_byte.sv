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


module spi_transmit_byte (
    input  logic       clk_i,
    input  logic       rst_ni,

    input  logic       start_i,         // 开始传输
    input  logic       slave_mode_i,    // 0: master, 1: slave.目前暂不支持slave模式!!!
    input  logic       read_i,          // 0: write, 1: read
    input  logic [1:0] spi_mode_i,      // 0: SPI, 1: Dual SPI, 2: Quad SPI, 3: SPI
    input  logic [1:0] cp_mode_i,       // [1]表示CPOL, [0]表示CPHA
    input  logic [7:0] data_i,          // 字节输入
    input  logic [2:0] div_ratio_i,     // 分频比
    input  logic       msb_first_i,     // 1: MSB, 0: LSB
    output logic [7:0] data_o,          // 接收到的数据输出
    output logic       ready_o,         // 1: IDLE, 0: 正在传输
    output logic       data_valid_o,    // 数据输出有效

    // CLK
    input  logic       spi_clk_i,
    output logic       spi_clk_o,
    output logic       spi_clk_oe_o,
    // SS(slave模式使用)
    input  logic       spi_ss_i,
    // MOSI(DQ0)
    input  logic       spi_dq0_i,
    output logic       spi_dq0_o,
    output logic       spi_dq0_oe_o,
    // MISO(DQ1)
    input  logic       spi_dq1_i,
    output logic       spi_dq1_o,
    output logic       spi_dq1_oe_o,
    // DQ2
    input  logic       spi_dq2_i,
    output logic       spi_dq2_o,
    output logic       spi_dq2_oe_o,
    // DQ3
    input  logic       spi_dq3_i,
    output logic       spi_dq3_o,
    output logic       spi_dq3_oe_o
    );

    localparam MODE_STAND_SPI = 2'b00;
    localparam MODE_DUAL_SPI  = 2'b01;
    localparam MODE_QUAD_SPI  = 2'b10;

    localparam S_IDLE = 3'b001;
    localparam S_DATA = 3'b010;
    localparam S_END  = 3'b100;

    logic tick;

    logic [2:0] state_d, state_q;
    logic [4:0] edge_cnt_d, edge_cnt_q;
    logic [7:0] in_data_d, in_data_q;
    logic [7:0] out_data_d, out_data_q;
    logic [4:0] total_edge_cnt_d, total_edge_cnt_q;
    logic data_valid_d, data_valid_q;
    logic ready_d, ready_q;

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

        spi_clk_d = spi_clk_q;

        case (state_q)
            S_IDLE: begin
                spi_clk_d = cp_mode_i[1];
                data_valid_d = 1'b0;
                ready_d = 1'b1;
                if (start_i) begin
                    edge_cnt_d = '0;
                    ready_d = 1'b0;
                    state_d = S_DATA;
                    if (msb_first_i) begin
                        out_data_d = data_i;
                    end else begin
                        out_data_d[7] = data_i[0];
                        out_data_d[6] = data_i[1];
                        out_data_d[5] = data_i[2];
                        out_data_d[4] = data_i[3];
                        out_data_d[3] = data_i[4];
                        out_data_d[2] = data_i[5];
                        out_data_d[1] = data_i[6];
                        out_data_d[0] = data_i[7];
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
                        if (cp_mode_i[0]) begin
                            // 第一个bit(s)在IDLE状态时已经送出了
                            if (edge_cnt_q != 5'd0) begin
                                case (spi_mode_i)
                                    MODE_STAND_SPI: out_data_d = {out_data_q[6:0], 1'b0};
                                    MODE_DUAL_SPI : out_data_d = {out_data_q[5:0], 2'b0};
                                    MODE_QUAD_SPI : out_data_d = {out_data_q[3:0], 4'b0};
                                    default:        out_data_d = {out_data_q[6:0], 1'b0};
                                endcase
                            end
                        // 采数据
                        end else begin
                            case (spi_mode_i)
                                MODE_STAND_SPI: in_data_d = {in_data_q[6:0], spi_dq1_i};
                                MODE_DUAL_SPI : in_data_d = {in_data_q[5:0], spi_dq1_i, spi_dq0_i};
                                MODE_QUAD_SPI : in_data_d = {in_data_q[3:0], spi_dq3_i, spi_dq2_i, spi_dq1_i, spi_dq0_i};
                                default       : in_data_d = {in_data_q[6:0], spi_dq1_i};
                            endcase
                        end
                    // 第偶数个沿(2, 4, 6...)
                    end else begin
                        // 出数据
                        if (!cp_mode_i[0]) begin
                            case (spi_mode_i)
                                MODE_STAND_SPI: out_data_d = {out_data_q[6:0], 1'b0};
                                MODE_DUAL_SPI : out_data_d = {out_data_q[5:0], 2'b0};
                                MODE_QUAD_SPI : out_data_d = {out_data_q[3:0], 4'b0};
                                default:        out_data_d = {out_data_q[6:0], 1'b0};
                            endcase
                        // 采数据
                        end else begin
                            case (spi_mode_i)
                                MODE_STAND_SPI: in_data_d = {in_data_q[6:0], spi_dq1_i};
                                MODE_DUAL_SPI : in_data_d = {in_data_q[5:0], spi_dq1_i, spi_dq0_i};
                                MODE_QUAD_SPI : in_data_d = {in_data_q[3:0], spi_dq3_i, spi_dq2_i, spi_dq1_i, spi_dq0_i};
                                default       : in_data_d = {in_data_q[6:0], spi_dq1_i};
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
                    data_valid_d = 1'b1;
                    if (!msb_first_i) begin
                        in_data_d[0] = in_data_q[7];
                        in_data_d[1] = in_data_q[6];
                        in_data_d[2] = in_data_q[5];
                        in_data_d[3] = in_data_q[4];
                        in_data_d[4] = in_data_q[3];
                        in_data_d[5] = in_data_q[2];
                        in_data_d[6] = in_data_q[1];
                        in_data_d[7] = in_data_q[0];
                    end
                end
            end

            default: ;
        endcase
    end

    always_comb begin
        total_edge_cnt_d = 5'd15;

        case (spi_mode_i)
            MODE_STAND_SPI: total_edge_cnt_d = 5'd15;
            MODE_DUAL_SPI : total_edge_cnt_d = 5'd7;
            MODE_QUAD_SPI : total_edge_cnt_d = 5'd3;
            default: ;
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= S_IDLE;
            edge_cnt_q <= '0;
            total_edge_cnt_q <= '0;
            in_data_q <= '0;
            out_data_q <= '0;
            data_valid_q <= '0;
            ready_q <= '0;
        end else begin
            state_q <= state_d;
            edge_cnt_q <= edge_cnt_d;
            total_edge_cnt_q <= total_edge_cnt_d;
            in_data_q <= in_data_d;
            out_data_q <= out_data_d;
            data_valid_q <= data_valid_d;
            ready_q <= ready_d;
        end
    end

    always_comb begin
        spi_dq0_d = 1'b0;
        spi_dq1_d = 1'b0;
        spi_dq2_d = 1'b0;
        spi_dq3_d = 1'b0;
        spi_dq0_oe_d = 1'b0;
        spi_dq1_oe_d = 1'b0;
        spi_dq2_oe_d = 1'b0;
        spi_dq3_oe_d = 1'b0;

        case (spi_mode_i)
            MODE_STAND_SPI: begin
                spi_dq0_d = out_data_d[7];
                spi_dq0_oe_d = 1'b1;
            end

            MODE_DUAL_SPI: begin
                spi_dq0_d = out_data_d[6];
                spi_dq1_d = out_data_d[7];
                if (read_i) begin
                    spi_dq0_oe_d = 1'b0;
                    spi_dq1_oe_d = 1'b0;
                end else begin
                    spi_dq0_oe_d = 1'b1;
                    spi_dq1_oe_d = 1'b1;
                end
            end

            MODE_QUAD_SPI: begin
                spi_dq0_d = out_data_d[4];
                spi_dq1_d = out_data_d[5];
                spi_dq2_d = out_data_d[6];
                spi_dq3_d = out_data_d[7];
                if (read_i) begin
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

    assign spi_clk_oe_d = slave_mode_i ? 1'b0 : 1'b1;

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

    assign data_o = in_data_q;
    assign data_valid_o = data_valid_q;
    assign ready_o = ready_q;

    assign spi_clk_o = spi_clk_q;
    assign spi_clk_oe_o = spi_clk_oe_q;
    assign spi_dq0_o = spi_dq0_q;
    assign spi_dq0_oe_o = spi_dq0_oe_q;
    assign spi_dq1_o = spi_dq1_q;
    assign spi_dq1_oe_o = spi_dq1_oe_q;
    assign spi_dq2_o = spi_dq2_q;
    assign spi_dq2_oe_o = spi_dq2_oe_q;
    assign spi_dq3_o = spi_dq3_q;
    assign spi_dq3_oe_o = spi_dq3_oe_q;

    logic [15:0] ratio = 1 << div_ratio_i;

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
