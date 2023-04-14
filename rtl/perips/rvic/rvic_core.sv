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

module rvic_core (
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic [31:0] src_i,
    output logic [ 7:0] irq_id_o,
    output logic        irq_o,

    input  logic        reg_we_i,
    input  logic        reg_re_i,
    input  logic [31:0] reg_wdata_i,
    input  logic [ 3:0] reg_be_i,
    input  logic [31:0] reg_addr_i,
    output logic [31:0] reg_rdata_o
    );

    import rvic_reg_pkg::*;

    rvic_reg_pkg::rvic_reg2hw_t reg2hw;
    rvic_reg_pkg::rvic_hw2reg_t hw2reg;

    logic [31:0] priority_array[8];
    logic [31:0] irq_enable;
    logic [31:0] irq_pending;

    assign priority_array[0] = reg2hw.priority0.q;
    assign priority_array[1] = reg2hw.priority1.q;
    assign priority_array[2] = reg2hw.priority2.q;
    assign priority_array[3] = reg2hw.priority3.q;
    assign priority_array[4] = reg2hw.priority4.q;
    assign priority_array[5] = reg2hw.priority5.q;
    assign priority_array[6] = reg2hw.priority6.q;
    assign priority_array[7] = reg2hw.priority7.q;

    assign irq_enable = reg2hw.enable.q;
    assign irq_pending = reg2hw.pending.q;


    // 找出优先级最高(优先级值最大)的中断源
    // 二分法查找

    logic [7:0] each_prio[32];

    for (genvar i = 0; i < 8; i = i + 1) begin
        for (genvar j = 0; j < 4; j = j + 1) begin
            // 只有当中断使能并且有中断请求，优先级才有效
            assign each_prio[i*4+j] = priority_array[i][8*j+7:8*j] & {8{irq_enable[i*4+j]}} & {8{src_i[i*4+j] | irq_pending[i*4+j]}};
        end
    end

    typedef struct packed {
        logic [7:0]  id;
        logic [7:0]  prio;
    } int_info_t;

    int_info_t l1_max[16];
    always_comb begin
        for (int i = 0; i < 16; i = i + 1) begin
            if (each_prio[2*i+1] > each_prio[2*i]) begin
                l1_max[i].id   = 2*i+1;
                l1_max[i].prio = each_prio[2*i+1];
            end else begin
                l1_max[i].id   = 2*i;
                l1_max[i].prio = each_prio[2*i];
            end
        end
    end

    int_info_t l2_max[8];
    always_comb begin
        for (int i = 0; i < 8; i = i + 1) begin
            if (l1_max[2*i+1].prio > l1_max[2*i].prio) begin
                l2_max[i].id   = l1_max[2*i+1].id;
                l2_max[i].prio = l1_max[2*i+1].prio;
            end else begin
                l2_max[i].id   = l1_max[2*i].id;
                l2_max[i].prio = l1_max[2*i].prio;
            end
        end
    end

    int_info_t l3_max[4];
    always_comb begin
        for (int i = 0; i < 4; i = i + 1) begin
            if (l2_max[2*i+1].prio > l2_max[2*i].prio) begin
                l3_max[i].id   = l2_max[2*i+1].id;
                l3_max[i].prio = l2_max[2*i+1].prio;
            end else begin
                l3_max[i].id   = l2_max[2*i].id;
                l3_max[i].prio = l2_max[2*i].prio;
            end
        end
    end

    int_info_t l4_max[2];
    always_comb begin
        for (int i = 0; i < 2; i = i + 1) begin
            if (l3_max[2*i+1].prio > l3_max[2*i].prio) begin
                l4_max[i].id   = l3_max[2*i+1].id;
                l4_max[i].prio = l3_max[2*i+1].prio;
            end else begin
                l4_max[i].id   = l3_max[2*i].id;
                l4_max[i].prio = l3_max[2*i].prio;
            end
        end
    end

    logic [7:0] irq_id;

    // 最终查找结果
    assign irq_id = (l4_max[1].prio > l4_max[0].prio) ? l4_max[1].id : l4_max[0].id;

    // 将irq_id打一拍后，irq_id_o就与irq_o同步
    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            irq_id_o <= 8'h0;
        end else begin
            irq_id_o <= irq_id;
        end
    end

    // 只要有pending就向MCU发起中断请求
    assign irq_o = |irq_pending;

    // 最多32个中断源
    logic [4:0] id = irq_id[4:0];

    // 硬件置位pending
    assign hw2reg.pending.de = src_i[id] & irq_enable[id];
    assign hw2reg.pending.d  = irq_pending | (1 << id);

    rvic_reg_top u_rvic_reg_top (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .reg2hw     (reg2hw),
        .hw2reg     (hw2reg),
        .reg_we     (reg_we_i),
        .reg_re     (reg_re_i),
        .reg_wdata  (reg_wdata_i),
        .reg_be     (reg_be_i),
        .reg_addr   (reg_addr_i),
        .reg_rdata  (reg_rdata_o)
    );

endmodule
