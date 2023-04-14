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

module pinmux_top #(
    parameter int          GPIO_NUM             = 16,
    parameter int          I2C_NUM              = 2,
    parameter int          UART_NUM             = 3,
    parameter int          SPI_NUM              = 1
    )(
    input  logic                clk_i,
    input  logic                rst_ni,
    // 16路GPIO
    input  logic [GPIO_NUM-1:0] gpio_oe_i,
    input  logic [GPIO_NUM-1:0] gpio_val_i,
    output logic [GPIO_NUM-1:0] gpio_val_o,
    // 2路I2C
    input  logic [I2C_NUM-1:0]  i2c_sda_oe_i,
    input  logic [I2C_NUM-1:0]  i2c_sda_val_i,
    output logic [I2C_NUM-1:0]  i2c_sda_val_o,
    input  logic [I2C_NUM-1:0]  i2c_scl_oe_i,
    input  logic [I2C_NUM-1:0]  i2c_scl_val_i,
    output logic [I2C_NUM-1:0]  i2c_scl_val_o,
    // 3路UART
    input  logic [UART_NUM-1:0] uart_tx_oe_i,
    input  logic [UART_NUM-1:0] uart_tx_val_i,
    output logic [UART_NUM-1:0] uart_tx_val_o,
    input  logic [UART_NUM-1:0] uart_rx_oe_i,
    input  logic [UART_NUM-1:0] uart_rx_val_i,
    output logic [UART_NUM-1:0] uart_rx_val_o,
    // 1路SPI
    input  logic [SPI_NUM-1:0]  spi_clk_oe_i,
    input  logic [SPI_NUM-1:0]  spi_clk_val_i,
    output logic [SPI_NUM-1:0]  spi_clk_val_o,
    input  logic [SPI_NUM-1:0]  spi_ss_oe_i,
    input  logic [SPI_NUM-1:0]  spi_ss_val_i,
    output logic [SPI_NUM-1:0]  spi_ss_val_o,
    input  logic [        3:0]  spi_dq_oe_i [SPI_NUM-1:0],
    input  logic [        3:0]  spi_dq_val_i[SPI_NUM-1:0],
    output logic [        3:0]  spi_dq_val_o[SPI_NUM-1:0],

    input  logic [GPIO_NUM-1:0] io_val_i,
    output logic [GPIO_NUM-1:0] io_val_o,
    output logic [GPIO_NUM-1:0] io_oe_o,

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

    pinmux_core #(
        .GPIO_NUM(GPIO_NUM),
        .I2C_NUM(I2C_NUM),
        .UART_NUM(UART_NUM),
        .SPI_NUM(SPI_NUM)
    ) u_pinmux_core (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .gpio_oe_i,
        .gpio_val_i,
        .gpio_val_o,
        .i2c_sda_oe_i,
        .i2c_sda_val_i,
        .i2c_sda_val_o,
        .i2c_scl_oe_i,
        .i2c_scl_val_i,
        .i2c_scl_val_o,
        .uart_tx_oe_i,
        .uart_tx_val_i,
        .uart_tx_val_o,
        .uart_rx_oe_i,
        .uart_rx_val_i,
        .uart_rx_val_o,
        .spi_clk_oe_i,
        .spi_clk_val_i,
        .spi_clk_val_o,
        .spi_ss_oe_i,
        .spi_ss_val_i,
        .spi_ss_val_o,
        .spi_dq_oe_i,
        .spi_dq_val_i,
        .spi_dq_val_o,
        .io_val_i,
        .io_val_o,
        .io_oe_o,
        .reg_we_i   (we),
        .reg_re_i   (re),
        .reg_wdata_i(data_i),
        .reg_be_i   (be_i),
        .reg_addr_i (addr),
        .reg_rdata_o(reg_rdata)
    );

endmodule
