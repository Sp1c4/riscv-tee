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

module i2c_master (
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic        enable_i,
    input  logic [15:0] div_ratio_i,
    input  logic        read_i,
    input  logic [7:0]  slave_addr_i,
    input  logic [7:0]  slave_reg_i,
    input  logic [7:0]  slave_data_i,
    input  logic        start_i,
    output logic        ready_o,
    output logic        error_o,
    output logic [7:0]  data_o,

    input  logic        scl_i,
    output logic        scl_o,
    output logic        scl_oe_o,
    input  logic        sda_i,
    output logic        sda_o,
    output logic        sda_oe_o
    );

    localparam S_IDLE        = 6'b000001;
    localparam S_START       = 6'b000010;
    localparam S_ADDR        = 6'b000100;
    localparam S_REG         = 6'b001000;
    localparam S_DATA        = 6'b010000;
    localparam S_STOP        = 6'b100000;

    logic tick;

    logic error_d, error_q;
    logic [7:0] data_d, data_q;
    logic [4:0] edge_cnt_d, edge_cnt_q;
    logic [7:0] shift_reg_d, shift_reg_q;
    logic [5:0] state_d, state_q;
    logic sda_d, sda_q;
    logic scl_d, scl_q;
    logic sda_oe_d, sda_oe_q;
    logic scl_oe_d, scl_oe_q;
    logic op_read_d, op_read_q;


    always_comb begin
        state_d = state_q;
        shift_reg_d = shift_reg_q;
        scl_d = scl_q;
        sda_oe_d = sda_oe_q;
        scl_oe_d = scl_oe_q;
        sda_d = sda_q;
        edge_cnt_d = edge_cnt_q;
        data_d = data_q;
        error_d = error_q;
        op_read_d = op_read_q;

        if (!enable_i) begin
            sda_d = 1'b0;
            sda_oe_d = 1'b0;
            scl_d = 1'b0;
            scl_oe_d = 1'b0;
            state_d = S_IDLE;
        end else begin
            case (state_q)
                S_IDLE: begin
                    sda_d = 1'b1;
                    sda_oe_d = 1'b1;
                    scl_d = 1'b1;
                    scl_oe_d = 1'b1;
                    if (start_i) begin
                        state_d = S_START;
                        error_d = 1'b0;
                        data_d = '0;
                        op_read_d = 1'b0;
                    end
                end

                S_START: begin
                    if (tick) begin
                        sda_d = 1'b0;
                        edge_cnt_d = '0;
                        state_d = S_ADDR;
                        shift_reg_d = {slave_addr_i[7:1], op_read_q};
                    end
                end

                S_ADDR: begin
                    if (tick) begin
                        scl_d = ~scl_q;
                        edge_cnt_d = edge_cnt_q + 1'b1;
                        // 下降沿释放SDA，准备接收ACK
                        if (edge_cnt_q == 5'd16) begin
                            sda_oe_d = 1'b0;
                        // 上升沿接收ACK
                        end else if (edge_cnt_q == 5'd17) begin
                            // NACK
                            if (sda_i) begin
                                error_d = 1'b1;
                            // ACK
                            end else begin
                                if (op_read_q) begin
                                    state_d = S_DATA;
                                end else begin
                                    state_d = S_REG;
                                    shift_reg_d = slave_reg_i;
                                end
                                edge_cnt_d = '0;
                            end
                        // 最后一个下降沿
                        end else if (edge_cnt_q == 5'd18) begin
                            sda_d = 1'b0;
                            sda_oe_d = 1'b1;
                        // 最后一个上升沿
                        end else if (edge_cnt_q == 5'd19) begin
                            state_d = S_STOP;
                        end else begin
                            // 发数据
                            if (scl_q) begin
                                // 左移一位(MSB first)
                                shift_reg_d = {shift_reg_q[6:0], 1'b1};
                                sda_d = shift_reg_q[7];
                                sda_oe_d = 1'b1;
                            end
                        end
                    end
                end

                S_REG: begin
                    if (tick) begin
                        scl_d = ~scl_q;
                        edge_cnt_d = edge_cnt_q + 1'b1;
                        // 下降沿释放SDA，准备接收ACK
                        if (edge_cnt_q == 5'd16) begin
                            sda_oe_d = 1'b0;
                        // 上升沿接收ACK
                        end else if (edge_cnt_q == 5'd17) begin
                            // NACK
                            if (sda_i) begin
                                error_d = 1'b1;
                            // ACK
                            end else begin
                                // 写操作，转去S_DATA状态
                                if (!read_i) begin
                                    state_d = S_DATA;
                                    shift_reg_d = slave_data_i;
                                    edge_cnt_d = '0;
                                // 读操作，发送STOP信号
                                end else begin
                                    op_read_d = 1'b1;
                                end
                            end
                        // 最后一个下降沿
                        end else if (edge_cnt_q == 5'd18) begin
                            sda_d = 1'b0;
                            sda_oe_d = 1'b1;
                        // 最后一个上升沿
                        end else if (edge_cnt_q == 5'd19) begin
                            state_d = S_STOP;
                        end else begin
                            // 发数据
                            if (scl_q) begin
                                // 左移一位(MSB first)
                                shift_reg_d = {shift_reg_q[6:0], 1'b1};
                                sda_d = shift_reg_q[7];
                                sda_oe_d = 1'b1;
                            end
                        end
                    end
                end

                S_DATA: begin
                    if (tick) begin
                        scl_d = ~scl_q;
                        edge_cnt_d = edge_cnt_q + 1'b1;
                        // 下降沿释放SDA，准备接收ACK
                        if (edge_cnt_q == 5'd16) begin
                            sda_oe_d = 1'b0;
                        // 上升沿接收ACK
                        end else if (edge_cnt_q == 5'd17) begin
                            // NACK
                            if (sda_i ^ op_read_q) begin
                                error_d = 1'b1;
                            // ACK
                            end else begin
                                error_d = 1'b0;
                            end
                            op_read_d = 1'b0;
                        // 最后一个下降沿
                        end else if (edge_cnt_q == 5'd18) begin
                            sda_d = 1'b0;
                            sda_oe_d = 1'b1;
                        // 最后一个上升沿
                        end else if (edge_cnt_q == 5'd19) begin
                            state_d = S_STOP;
                        end else begin
                            // 读数据
                            if (op_read_q && (~scl_q)) begin
                                data_d = {data_q[6:0], sda_i};
                            // 发数据
                            end else if ((~op_read_q) && scl_q) begin
                                // 左移一位(MSB first)
                                shift_reg_d = {shift_reg_q[6:0], 1'b1};
                                sda_d = shift_reg_q[7];
                                sda_oe_d = 1'b1;
                            end
                        end
                    end
                end

                S_STOP: begin
                    if (tick) begin
                        sda_d = 1'b1;
                        if (op_read_q) begin
                            state_d = S_START;
                        end else begin
                            state_d = S_IDLE;
                        end
                    end
                end

                default: ;
            endcase
        end
    end

    assign scl_o = scl_q;
    assign scl_oe_o = scl_oe_q;
    assign sda_o = sda_q;
    assign sda_oe_o = sda_oe_q;
    assign data_o = data_q;
    assign ready_o = (state_q == S_IDLE);
    assign error_o = error_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= S_IDLE;
            shift_reg_q <= '0;
            scl_q <= 1'b0;
            sda_q <= 1'b0;
            sda_oe_q <= 1'b0;
            scl_oe_q <= 1'b0;
            edge_cnt_q <= '0;
            data_q <= '0;
            error_q <= 1'b0;
            op_read_q <= 1'b0;
        end else begin
            state_q <= state_d;
            shift_reg_q <= shift_reg_d;
            scl_q <= scl_d;
            sda_q <= sda_d;
            sda_oe_q <= sda_oe_d;
            scl_oe_q <= scl_oe_d;
            edge_cnt_q <= edge_cnt_d;
            data_q <= data_d;
            error_q <= error_d;
            op_read_q <= op_read_d;
        end
    end

    logic [15:0] ratio = {1'b0, div_ratio_i[15:1]};

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
