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

module gpio_top #(
    parameter int GPIO_NUM = 2
    )(
    input  logic                clk_i,
    input  logic                rst_ni,

    output logic [GPIO_NUM-1:0] gpio_oe_o,
    output logic [GPIO_NUM-1:0] gpio_data_o,
    input  logic [GPIO_NUM-1:0] gpio_data_i,
    output logic                irq_gpio0_o,
    output logic                irq_gpio1_o,
    output logic                irq_gpio2_4_o,
    output logic                irq_gpio5_7_o,
    output logic                irq_gpio8_o,
    output logic                irq_gpio9_o,
    output logic                irq_gpio10_12_o,
    output logic                irq_gpio13_15_o,

    // OBI总线接口信号
    input  logic                req_i,
    input  logic                we_i,
    input  logic [ 3:0]         be_i,
    input  logic [31:0]         addr_i,
    input  logic [31:0]         data_i,
    output logic                gnt_o,
    output logic                rvalid_o,
    output logic [31:0]         data_o
    );

    logic re;
    logic we;
    logic [31:0] addr;
    logic [31:0] reg_rdata;

    assign gnt_o = req_i;

    // 读信号
    assign re = req_i & (!we_i);
    // 写信号
    assign we = req_i & we_i;
    // 去掉基地址
    assign addr = {16'h0, addr_i[15:0]};

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rvalid_o <= '0;
            data_o <= '0;
        end else begin
            rvalid_o <= req_i;
            data_o <= reg_rdata;
        end
    end

    gpio_core #(
        .GPIO_NUM(GPIO_NUM)
    ) u_gpio_core (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .gpio_oe_o  (gpio_oe_o),
        .gpio_data_o(gpio_data_o),
        .gpio_data_i(gpio_data_i),
        .irq_gpio0_o(irq_gpio0_o),
        .irq_gpio1_o(irq_gpio1_o),
        .irq_gpio2_4_o(irq_gpio2_4_o),
        .irq_gpio5_7_o(irq_gpio5_7_o),
        .irq_gpio8_o(irq_gpio8_o),
        .irq_gpio9_o(irq_gpio9_o),
        .irq_gpio10_12_o(irq_gpio10_12_o),
        .irq_gpio13_15_o(irq_gpio13_15_o),
        .reg_we_i   (we),
        .reg_re_i   (re),
        .reg_wdata_i(data_i),
        .reg_be_i   (be_i),
        .reg_addr_i (addr),
        .reg_rdata_o(reg_rdata)
    );

endmodule
