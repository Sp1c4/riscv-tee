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

module spi_master (
    input  logic       clk_i,
    input  logic       rst_ni,

    input  logic       start_i,         // 开始传输
    input  logic       read_i,          // 0: write, 1: read
    input  logic [7:0] data_i,          // 字节输入
    input  logic [1:0] spi_mode_i,      // 0: SPI, 1: Dual SPI, 2: Quad SPI, 3: SPI
    input  logic [1:0] cp_mode_i,       // [1]表示CPOL, [0]表示CPHA
    input  logic [2:0] div_ratio_i,     // 分频比
    input  logic       msb_first_i,     // 1: MSB, 0: LSB
    input  logic [3:0] ss_delay_cnt_i,  // SS信号延时时钟个数, 当ss_sw_ctrl_i=0时才有效
    input  logic       ss_sw_ctrl_i,    // 软件控制SS信号
    input  logic       ss_level_i,      // SS输出电平，仅当ss_sw_ctrl_i=1时有效
    output logic [7:0] data_o,          // 接收到的数据
    output logic       ready_o,         // 1: IDLE, 0: 正在传输
    output logic       data_valid_o,    // 接收到的数据有效

    // CLK
    output logic       spi_clk_o,
    output logic       spi_clk_oe_o,
    // SS
    output logic       spi_ss_o,
    output logic       spi_ss_oe_o,
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

    localparam S_IDLE           = 4'b0001;
    localparam S_SS_ACTIVE      = 4'b0010;
    localparam S_TRANSMIT       = 4'b0100;
    localparam S_SS_INACTIVE    = 4'b1000;

    logic data_valid;
    logic [7:0] in_data;

    logic [3:0] state_d, state_q;
    logic [3:0] ss_delay_cnt_d, ss_delay_cnt_q;
    logic [7:0] out_data_d, out_data_q;
    logic start_d, start_q;
    logic ready_d, ready_q;

    logic spi_ss_d, spi_ss_q;
    logic spi_ss_oe_d, spi_ss_oe_q;

    always_comb begin
        state_d = state_q;
        ss_delay_cnt_d = ss_delay_cnt_q;
        out_data_d = out_data_q;
        start_d = 1'b0;
        ready_d = ready_q;
        spi_ss_d = spi_ss_q;
        spi_ss_oe_d = spi_ss_oe_q;

        case (state_q)
            S_IDLE: begin
                spi_ss_oe_d = 1'b1;
                spi_ss_d = 1'b1;
                ready_d = 1'b1;
                if (start_i) begin
                    out_data_d = data_i;
                    if (ss_sw_ctrl_i) begin
                        state_d = S_TRANSMIT;
                        start_d = 1'b1;
                    end else begin
                        state_d = S_SS_ACTIVE;
                    end
                    ss_delay_cnt_d = '0;
                    ready_d = 1'b0;
                end
            end

            S_SS_ACTIVE: begin
                spi_ss_d = 1'b0;
                ss_delay_cnt_d = ss_delay_cnt_q + 1'b1;
                if (ss_delay_cnt_q == ss_delay_cnt_i) begin
                    state_d = S_TRANSMIT;
                    start_d = 1'b1;
                end
            end

            S_TRANSMIT: begin
                // 还有数据要传输
                if (data_valid && start_i) begin
                    out_data_d = data_i;
                    start_d = 1'b1;
                // 没有数据要传输
                end else if (data_valid && (!start_i)) begin
                    if (ss_sw_ctrl_i) begin
                        state_d = S_IDLE;
                    end else begin
                        state_d = S_SS_INACTIVE;
                    end
                    ss_delay_cnt_d = '0;
                end
            end

            S_SS_INACTIVE: begin
                ss_delay_cnt_d = ss_delay_cnt_q + 1'b1;
                if (ss_delay_cnt_q == ss_delay_cnt_i) begin
                    state_d = S_IDLE;
                end
            end

            default: ;
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= S_IDLE;
            ss_delay_cnt_q <= '0;
            out_data_q <= '0;
            start_q <= '0;
            ready_q <= '0;
        end else begin
            state_q <= state_d;
            ss_delay_cnt_q <= ss_delay_cnt_d;
            out_data_q <= out_data_d;
            start_q <= start_d;
            ready_q <= ready_d;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            spi_ss_q    <= '0;
            spi_ss_oe_q <= '0;
        end else begin
            spi_ss_q    <= spi_ss_d;
            spi_ss_oe_q <= spi_ss_oe_d;
        end
    end

    assign data_valid_o = data_valid;
    assign data_o = in_data;
    assign ready_o = ready_q;

    assign spi_ss_o = ss_sw_ctrl_i ? ss_level_i : spi_ss_q;
    assign spi_ss_oe_o = spi_ss_oe_q;

    spi_transmit_byte master_transmit_byte (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .start_i    (start_q),
        .slave_mode_i(1'b0),
        .read_i     (read_i),
        .spi_mode_i (spi_mode_i),
        .cp_mode_i  (cp_mode_i),
        .data_i     (out_data_q),
        .div_ratio_i(div_ratio_i),
        .msb_first_i(msb_first_i),
        .data_o     (in_data),
        .ready_o    (),
        .data_valid_o(data_valid),
        .spi_clk_i  (),
        .spi_clk_o  (spi_clk_o),
        .spi_clk_oe_o(spi_clk_oe_o),
        .spi_ss_i   (),
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
        .spi_dq3_oe_o(spi_dq3_oe_o)
    );

endmodule
