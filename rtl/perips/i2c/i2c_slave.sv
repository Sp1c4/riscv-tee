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

module i2c_slave (
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic        enable_i,
    input  logic [7:0]  slave_addr_i,
    input  logic [7:0]  data_i,
    output logic [7:0]  addr_o,
    output logic        read_o,
    output logic        valid_o,
    output logic [7:0]  data_o,

    input  logic        scl_i,
    output logic        scl_o,
    output logic        scl_oe_o,
    input  logic        sda_i,
    output logic        sda_o,
    output logic        sda_oe_o
    );

    localparam S_IDLE  = 6'b000001;
    localparam S_START = 6'b000010;
    localparam S_ADDR  = 6'b000100;
    localparam S_REG   = 6'b001000;
    localparam S_DATA  = 6'b010000;
    localparam S_STOP  = 6'b100000;

    logic scl_raise_edge, scl_fall_edge;
    logic sda_raise_edge, sda_fall_edge;
    logic sda, scl;

    logic [5:0] state_d, state_q;
    logic sda_oe_d, sda_oe_q;
    logic scl_oe_d, scl_oe_q;
    logic sda_d, sda_q;
    logic scl_d, scl_q;
    logic [7:0] data_d, data_q;
    logic [7:0] addr_d, addr_q;
    logic read_d, read_q;
    logic send_ack_d, send_ack_q;
    logic [3:0] scl_raise_edge_cnt_d, scl_raise_edge_cnt_q;
    logic valid_d, valid_q;
    logic op_read_d, op_read_q;


    always_comb begin
        state_d = state_q;
        sda_oe_d = sda_oe_q;
        sda_d = sda_q;
        scl_oe_d = scl_oe_q;
        scl_d = scl_q;
        data_d = data_q;
        addr_d = addr_q;
        read_d = read_q;
        send_ack_d = send_ack_q;
        scl_raise_edge_cnt_d = scl_raise_edge_cnt_q;
        valid_d = valid_q;
        op_read_d = op_read_q;

        if (!enable_i) begin
            state_d = S_IDLE;
            sda_oe_d = 1'b0;
            sda_d = 1'b0;
            scl_oe_d = 1'b0;
            scl_d = 1'b0;
        end else begin
            case (state_q)
                S_IDLE: begin
                    sda_oe_d = 1'b0;
                    sda_d = 1'b0;
                    valid_d = 1'b0;
                    read_d = 1'b0;
                    // START信号
                    if (scl_i && sda_fall_edge) begin
                        state_d = S_ADDR;
                        send_ack_d = 1'b0;
                        scl_raise_edge_cnt_d = '0;
                        op_read_d = 1'b0;
                    end
                end

                S_ADDR: begin
                    // SCL上升沿采数据
                    if (scl_raise_edge) begin
                        scl_raise_edge_cnt_d = scl_raise_edge_cnt_q + 1'b1;
                        if (scl_raise_edge_cnt_q < 4'd8) begin
                            data_d = {data_q[6:0], sda};
                        end
                    end
                    // 下降沿发ACK信号
                    if ((scl_raise_edge_cnt_q == 4'd8) && scl_fall_edge) begin
                        // 地址对得上则回ACK信号
                        if (slave_addr_i[7:1] == data_q[7:1]) begin
                            sda_oe_d = 1'b1;
                            sda_d = 1'b0;
                            if (data_q[0]) begin
                                read_d = 1'b1;
                            end
                        // 否则回到S_IDLE状态
                        end else begin
                            state_d = S_IDLE;
                        end
                    end
                    // 释放SDA
                    if ((scl_raise_edge_cnt_q == 4'd9) && scl_fall_edge) begin
                        sda_oe_d = 1'b0;
                        scl_raise_edge_cnt_d = '0;
                        // 读
                        if (data_q[0]) begin
                            state_d = S_DATA;
                            op_read_d = 1'b1;
                            sda_oe_d = 1'b1;
                            data_d = {data_i[6:0], 1'b1};
                            sda_d = data_i[7];
                        // 写
                        end else begin
                            state_d = S_REG;
                            op_read_d = 1'b0;
                        end
                    end
                    // 收到STOP信号
                    if (scl_i && sda_raise_edge) begin
                        state_d = S_IDLE;
                    end
                end

                S_REG: begin
                    // SCL上升沿采数据
                    if (scl_raise_edge) begin
                        scl_raise_edge_cnt_d = scl_raise_edge_cnt_q + 1'b1;
                        if (scl_raise_edge_cnt_q < 4'd8) begin
                            data_d = {data_q[6:0], sda};
                        end
                    end
                    // 下降沿发ACK信号
                    if ((scl_raise_edge_cnt_q == 4'd8) && scl_fall_edge) begin
                        sda_oe_d = 1'b1;
                        sda_d = 1'b0;
                        addr_d = data_q;
                    end
                    // 释放SDA
                    if ((scl_raise_edge_cnt_q == 4'd9) && scl_fall_edge) begin
                        sda_oe_d = 1'b0;
                        scl_raise_edge_cnt_d = '0;
                        state_d = S_DATA;
                        op_read_d = 1'b0;
                    end
                    // 收到STOP信号
                    if (scl_i && sda_raise_edge) begin
                        state_d = S_IDLE;
                    end
                end

                S_DATA: begin
                    if (scl_raise_edge) begin
                        scl_raise_edge_cnt_d = scl_raise_edge_cnt_q + 1'b1;
                        if ((!op_read_q) && (scl_raise_edge_cnt_q < 4'd8)) begin
                            data_d = {data_q[6:0], sda};
                        end
                    end else if (scl_fall_edge) begin
                        if (op_read_q && (scl_raise_edge_cnt_q < 4'd8)) begin
                            sda_oe_d = 1'b1;
                            data_d = {data_q[6:0], 1'b1};
                            sda_d = data_q[7];
                        end
                    end
                    // 下降沿发ACK信号
                    if ((scl_raise_edge_cnt_q == 4'd8) && scl_fall_edge) begin
                        sda_oe_d = 1'b1;
                        // 回NACK
                        if (op_read_q) begin
                            sda_d = 1'b1;
                        // 回ACK
                        end else begin
                            sda_d = 1'b0;
                        end
                        valid_d = 1'b1;
                    end
                    // 释放SDA
                    if ((scl_raise_edge_cnt_q == 4'd9) && scl_fall_edge) begin
                        sda_oe_d = 1'b0;
                        op_read_d = 1'b0;
                    end
                    // 收到STOP信号
                    if (scl_i && sda_raise_edge) begin
                        state_d = S_IDLE;
                    end
                end

                default: ;
            endcase
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= S_IDLE;
            sda_oe_q <= 1'b0;
            sda_q <= 1'b0;
            scl_oe_q <= 1'b0;
            scl_q <= 1'b0;
            data_q <= '0;
            addr_q <= '0;
            read_q <= 1'b0;
            send_ack_q <= 1'b0;
            scl_raise_edge_cnt_q <= '0;
            valid_q <= 1'b0;
            op_read_q <= 1'b0;
        end else begin
            state_q <= state_d;
            sda_oe_q <= sda_oe_d;
            sda_q <= sda_d;
            scl_oe_q <= scl_oe_d;
            scl_q <= scl_d;
            data_q <= data_d;
            addr_q <= addr_d;
            read_q <= read_d;
            send_ack_q <= send_ack_d;
            scl_raise_edge_cnt_q <= scl_raise_edge_cnt_d;
            valid_q <= valid_d;
            op_read_q <= op_read_d;
        end
    end

    assign scl_oe_o = scl_oe_q;
    assign scl_o = scl_q;
    assign sda_oe_o = sda_oe_q;
    assign sda_o = sda_q;
    assign data_o = data_q;
    assign addr_o = addr_q;
    assign read_o = read_q;
    assign valid_o = valid_q;

    // SCL信号沿检测
    edge_detect scl_edge_detect (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .sig_i  (scl_i),
        .sig_o  (scl),
        .re_o   (scl_raise_edge),
        .fe_o   (scl_fall_edge)
    );

    // SDA信号沿检测
    edge_detect sda_edge_detect (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .sig_i  (sda_i),
        .sig_o  (sda),
        .re_o   (sda_raise_edge),
        .fe_o   (sda_fall_edge)
    );

endmodule
