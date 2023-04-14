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


module pinmux_core #(
    parameter int          GPIO_NUM             = 16,
    parameter int          I2C_NUM              = 2,
    parameter int          UART_NUM             = 3,
    parameter int          SPI_NUM              = 1
    )(
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic [GPIO_NUM-1:0] gpio_oe_i,
    input  logic [GPIO_NUM-1:0] gpio_val_i,
    output logic [GPIO_NUM-1:0] gpio_val_o,

    input  logic [I2C_NUM-1:0]  i2c_sda_oe_i,
    input  logic [I2C_NUM-1:0]  i2c_sda_val_i,
    output logic [I2C_NUM-1:0]  i2c_sda_val_o,
    input  logic [I2C_NUM-1:0]  i2c_scl_oe_i,
    input  logic [I2C_NUM-1:0]  i2c_scl_val_i,
    output logic [I2C_NUM-1:0]  i2c_scl_val_o,

    input  logic [UART_NUM-1:0] uart_tx_oe_i,
    input  logic [UART_NUM-1:0] uart_tx_val_i,
    output logic [UART_NUM-1:0] uart_tx_val_o,
    input  logic [UART_NUM-1:0] uart_rx_oe_i,
    input  logic [UART_NUM-1:0] uart_rx_val_i,
    output logic [UART_NUM-1:0] uart_rx_val_o,

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

    input  logic                reg_we_i,
    input  logic                reg_re_i,
    input  logic [31:0]         reg_wdata_i,
    input  logic [ 3:0]         reg_be_i,
    input  logic [31:0]         reg_addr_i,
    output logic [31:0]         reg_rdata_o
    );

    import pinmux_reg_pkg::*;

    pinmux_reg_pkg::pinmux_reg2hw_t reg2hw;

    logic [1:0] io0_mux;
    logic [1:0] io1_mux;
    logic [1:0] io2_mux;
    logic [1:0] io3_mux;
    logic [1:0] io4_mux;
    logic [1:0] io5_mux;
    logic [1:0] io6_mux;
    logic [1:0] io7_mux;
    logic [1:0] io8_mux;
    logic [1:0] io9_mux;
    logic [1:0] io10_mux;
    logic [1:0] io11_mux;
    logic [1:0] io12_mux;
    logic [1:0] io13_mux;
    logic [1:0] io14_mux;
    logic [1:0] io15_mux;

    assign io0_mux  = reg2hw.ctrl.io0_mux.q;
    assign io1_mux  = reg2hw.ctrl.io1_mux.q;
    assign io2_mux  = reg2hw.ctrl.io2_mux.q;
    assign io3_mux  = reg2hw.ctrl.io3_mux.q;
    assign io4_mux  = reg2hw.ctrl.io4_mux.q;
    assign io5_mux  = reg2hw.ctrl.io5_mux.q;
    assign io6_mux  = reg2hw.ctrl.io6_mux.q;
    assign io7_mux  = reg2hw.ctrl.io7_mux.q;
    assign io8_mux  = reg2hw.ctrl.io8_mux.q;
    assign io9_mux  = reg2hw.ctrl.io9_mux.q;
    assign io10_mux = reg2hw.ctrl.io10_mux.q;
    assign io11_mux = reg2hw.ctrl.io11_mux.q;
    assign io12_mux = reg2hw.ctrl.io12_mux.q;
    assign io13_mux = reg2hw.ctrl.io13_mux.q;
    assign io14_mux = reg2hw.ctrl.io14_mux.q;
    assign io15_mux = reg2hw.ctrl.io15_mux.q;

    // IO0
    always_comb begin
        io_val_o[0] = 1'b0;
        io_oe_o[0] = 1'b0;

        case (io0_mux)
            // GPIO0
            2'b00: begin
                io_val_o[0]      = gpio_val_i[0];
                io_oe_o[0]       = gpio_oe_i[0];
            end
            // UART0_TX
            2'b01: begin
                io_val_o[0]      = uart_tx_val_i[0];
                io_oe_o[0]       = uart_tx_oe_i[0];
            end
            // UART0_RX
            2'b10: begin
                io_val_o[0]      = uart_rx_val_i[0];
                io_oe_o[0]       = uart_rx_oe_i[0];
            end
            // GPIO0
            2'b11: begin
                io_val_o[0]      = gpio_val_i[0];
                io_oe_o[0]       = gpio_oe_i[0];
            end
            default: ;
        endcase
    end

    // IO1
    always_comb begin
        io_val_o[1] = 1'b0;
        io_oe_o[1] = 1'b0;

        case (io1_mux)
            // GPIO1
            2'b00: begin
                io_val_o[1]      = gpio_val_i[1];
                io_oe_o[1]       = gpio_oe_i[1];
            end
            // UART1_TX
            2'b01: begin
                io_val_o[1]      = uart_tx_val_i[1];
                io_oe_o[1]       = uart_tx_oe_i[1];
            end
            // UART1_RX
            2'b10: begin
                io_val_o[1]      = uart_rx_val_i[1];
                io_oe_o[1]       = uart_rx_oe_i[1];
            end
            // SPI_DQ0
            2'b11: begin
                io_val_o[1]      = spi_dq_val_i[0][0];
                io_oe_o[1]       = spi_dq_oe_i[0][0];
            end
            default: ;
        endcase
    end

    // IO2
    always_comb begin
        io_val_o[2] = 1'b0;
        io_oe_o[2] = 1'b0;

        case (io2_mux)
            // GPIO2
            2'b00: begin
                io_val_o[2]      = gpio_val_i[2];
                io_oe_o[2]       = gpio_oe_i[2];
            end
            // UART2_TX
            2'b01: begin
                io_val_o[2]      = uart_tx_val_i[2];
                io_oe_o[2]       = uart_tx_oe_i[2];
            end
            // UART2_RX
            2'b10: begin
                io_val_o[2]      = uart_rx_val_i[2];
                io_oe_o[2]       = uart_rx_oe_i[2];
            end
            // SPI_DQ1
            2'b11: begin
                io_val_o[2]      = spi_dq_val_i[0][1];
                io_oe_o[2]       = spi_dq_oe_i[0][1];
            end
            default: ;
        endcase
    end

    // IO3
    always_comb begin
        io_val_o[3] = 1'b0;
        io_oe_o[3] = 1'b0;

        case (io3_mux)
            // GPIO3
            2'b00: begin
                io_val_o[3]      = gpio_val_i[3];
                io_oe_o[3]       = gpio_oe_i[3];
            end
            // UART0_TX
            2'b01: begin
                io_val_o[3]      = uart_tx_val_i[0];
                io_oe_o[3]       = uart_tx_oe_i[0];
            end
            // UART0_RX
            2'b10: begin
                io_val_o[3]      = uart_rx_val_i[0];
                io_oe_o[3]       = uart_rx_oe_i[0];
            end
            // GPIO3
            2'b11: begin
                io_val_o[3]      = gpio_val_i[3];
                io_oe_o[3]       = gpio_oe_i[3];
            end
            default: ;
        endcase
    end

    // IO4
    always_comb begin
        io_val_o[4] = 1'b0;
        io_oe_o[4] = 1'b0;

        case (io4_mux)
            // GPIO4
            2'b00: begin
                io_val_o[4]      = gpio_val_i[4];
                io_oe_o[4]       = gpio_oe_i[4];
            end
            // UART1_TX
            2'b01: begin
                io_val_o[4]      = uart_tx_val_i[1];
                io_oe_o[4]       = uart_tx_oe_i[1];
            end
            // UART1_RX
            2'b10: begin
                io_val_o[4]      = uart_rx_val_i[1];
                io_oe_o[4]       = uart_rx_oe_i[1];
            end
            // SPI_DQ2
            2'b11: begin
                io_val_o[4]      = spi_dq_val_i[0][2];
                io_oe_o[4]       = spi_dq_oe_i[0][2];
            end
            default: ;
        endcase
    end

    // IO5
    always_comb begin
        io_val_o[5] = 1'b0;
        io_oe_o[5] = 1'b0;

        case (io5_mux)
            // GPIO5
            2'b00: begin
                io_val_o[5]      = gpio_val_i[5];
                io_oe_o[5]       = gpio_oe_i[5];
            end
            // UART2_TX
            2'b01: begin
                io_val_o[5]      = uart_tx_val_i[2];
                io_oe_o[5]       = uart_tx_oe_i[2];
            end
            // UART2_RX
            2'b10: begin
                io_val_o[5]      = uart_rx_val_i[2];
                io_oe_o[5]       = uart_rx_oe_i[2];
            end
            // SPI_DQ3
            2'b11: begin
                io_val_o[5]      = spi_dq_val_i[0][3];
                io_oe_o[5]       = spi_dq_oe_i[0][3];
            end
            default: ;
        endcase
    end

    // IO6
    always_comb begin
        io_val_o[6] = 1'b0;
        io_oe_o[6] = 1'b0;

        case (io6_mux)
            // GPIO6
            2'b00: begin
                io_val_o[6]      = gpio_val_i[6];
                io_oe_o[6]       = gpio_oe_i[6];
            end
            // I2C0_SCL
            2'b01: begin
                io_val_o[6]      = i2c_scl_val_i[0];
                io_oe_o[6]       = i2c_scl_oe_i[0];
            end
            // I2C0_SDA
            2'b10: begin
                io_val_o[6]      = i2c_sda_val_i[0];
                io_oe_o[6]       = i2c_sda_oe_i[0];
            end
            // SPI_CLK
            2'b11: begin
                io_val_o[6]      = spi_clk_val_i[0];
                io_oe_o[6]       = spi_clk_oe_i[0];
            end
            default: ;
        endcase
    end

    // IO7
    always_comb begin
        io_val_o[7] = 1'b0;
        io_oe_o[7] = 1'b0;

        case (io7_mux)
            // GPIO7
            2'b00: begin
                io_val_o[7]      = gpio_val_i[7];
                io_oe_o[7]       = gpio_oe_i[7];
            end
            // I2C1_SCL
            2'b01: begin
                io_val_o[7]      = i2c_scl_val_i[1];
                io_oe_o[7]       = i2c_scl_oe_i[1];
            end
            // I2C1_SDA
            2'b10: begin
                io_val_o[7]      = i2c_sda_val_i[1];
                io_oe_o[7]       = i2c_sda_oe_i[1];
            end
            // GPIO7
            2'b11: begin
                io_val_o[7]      = gpio_val_i[7];
                io_oe_o[7]       = gpio_oe_i[7];
            end
            default: ;
        endcase
    end

    // IO8
    always_comb begin
        io_val_o[8] = 1'b0;
        io_oe_o[8] = 1'b0;

        case (io8_mux)
            // GPIO8
            2'b00: begin
                io_val_o[8]      = gpio_val_i[8];
                io_oe_o[8]       = gpio_oe_i[8];
            end
            // I2C0_SCL
            2'b01: begin
                io_val_o[8]      = i2c_scl_val_i[0];
                io_oe_o[8]       = i2c_scl_oe_i[0];
            end
            // I2C0_SDA
            2'b10: begin
                io_val_o[8]      = i2c_sda_val_i[0];
                io_oe_o[8]       = i2c_sda_oe_i[0];
            end
            // SPI_SS
            2'b11: begin
                io_val_o[8]      = spi_ss_val_i[0];
                io_oe_o[8]       = spi_ss_oe_i[0];
            end
            default: ;
        endcase
    end

    // IO9
    always_comb begin
        io_val_o[9] = 1'b0;
        io_oe_o[9] = 1'b0;

        case (io9_mux)
            // GPIO9
            2'b00: begin
                io_val_o[9]      = gpio_val_i[9];
                io_oe_o[9]       = gpio_oe_i[9];
            end
            // I2C1_SCL
            2'b01: begin
                io_val_o[9]      = i2c_scl_val_i[1];
                io_oe_o[9]       = i2c_scl_oe_i[1];
            end
            // I2C1_SDA
            2'b10: begin
                io_val_o[9]      = i2c_sda_val_i[1];
                io_oe_o[9]       = i2c_sda_oe_i[1];
            end
            // GPIO9
            2'b11: begin
                io_val_o[9]      = gpio_val_i[9];
                io_oe_o[9]       = gpio_oe_i[9];
            end
            default: ;
        endcase
    end

    // IO10
    always_comb begin
        io_val_o[10] = 1'b0;
        io_oe_o[10] = 1'b0;

        case (io10_mux)
            // GPIO10
            2'b00: begin
                io_val_o[10]      = gpio_val_i[10];
                io_oe_o[10]       = gpio_oe_i[10];
            end
            // SPI_CLK
            2'b01: begin
                io_val_o[10]      = spi_clk_val_i[0];
                io_oe_o[10]       = spi_clk_oe_i[0];
            end
            default: begin
                io_val_o[10]      = gpio_val_i[10];
                io_oe_o[10]       = gpio_oe_i[10];
            end
        endcase
    end

    // IO11
    always_comb begin
        io_val_o[11] = 1'b0;
        io_oe_o[11] = 1'b0;

        case (io11_mux)
            // GPIO11
            2'b00: begin
                io_val_o[11]      = gpio_val_i[11];
                io_oe_o[11]       = gpio_oe_i[11];
            end
            // SPI_SS
            2'b01: begin
                io_val_o[11]      = spi_ss_val_i[0];
                io_oe_o[11]       = spi_ss_oe_i[0];
            end
            default: begin
                io_val_o[11]      = gpio_val_i[11];
                io_oe_o[11]       = gpio_oe_i[11];
            end
        endcase
    end

    // IO12
    always_comb begin
        io_val_o[12] = 1'b0;
        io_oe_o[12] = 1'b0;

        case (io12_mux)
            // GPIO12
            2'b00: begin
                io_val_o[12]      = gpio_val_i[12];
                io_oe_o[12]       = gpio_oe_i[12];
            end
            // SPI_DQ0
            2'b01: begin
                io_val_o[12]      = spi_dq_val_i[0][0];
                io_oe_o[12]       = spi_dq_oe_i[0][0];
            end
            default: begin
                io_val_o[12]      = gpio_val_i[12];
                io_oe_o[12]       = gpio_oe_i[12];
            end
        endcase
    end

    // IO13
    always_comb begin
        io_val_o[13] = 1'b0;
        io_oe_o[13] = 1'b0;

        case (io13_mux)
            // GPIO13
            2'b00: begin
                io_val_o[13]      = gpio_val_i[13];
                io_oe_o[13]       = gpio_oe_i[13];
            end
            // SPI_DQ1
            2'b01: begin
                io_val_o[13]      = spi_dq_val_i[0][1];
                io_oe_o[13]       = spi_dq_oe_i[0][1];
            end
            default: begin
                io_val_o[13]      = gpio_val_i[13];
                io_oe_o[13]       = gpio_oe_i[13];
            end
        endcase
    end

    // IO14
    always_comb begin
        io_val_o[14] = 1'b0;
        io_oe_o[14] = 1'b0;

        case (io14_mux)
            // GPIO14
            2'b00: begin
                io_val_o[14]      = gpio_val_i[14];
                io_oe_o[14]       = gpio_oe_i[14];
            end
            // SPI_DQ2
            2'b01: begin
                io_val_o[14]      = spi_dq_val_i[0][2];
                io_oe_o[14]       = spi_dq_oe_i[0][2];
            end
            default: begin
                io_val_o[14]      = gpio_val_i[14];
                io_oe_o[14]       = gpio_oe_i[14];
            end
        endcase
    end

    // IO15
    always_comb begin
        io_val_o[15] = 1'b0;
        io_oe_o[15] = 1'b0;

        case (io15_mux)
            // GPIO15
            2'b00: begin
                io_val_o[15]      = gpio_val_i[15];
                io_oe_o[15]       = gpio_oe_i[15];
            end
            // SPI_DQ3
            2'b01: begin
                io_val_o[15]      = spi_dq_val_i[0][3];
                io_oe_o[15]       = spi_dq_oe_i[0][3];
            end
            default: begin
                io_val_o[15]      = gpio_val_i[15];
                io_oe_o[15]       = gpio_oe_i[15];
            end
        endcase
    end

///////////////////////////////////////////////////////////////////////////////////////////

    assign gpio_val_o[ 0] = ( io0_mux == 2'b00) ? io_val_i[ 0] : 1'b0;
    assign gpio_val_o[ 1] = ( io1_mux == 2'b00) ? io_val_i[ 1] : 1'b0;
    assign gpio_val_o[ 2] = ( io2_mux == 2'b00) ? io_val_i[ 2] : 1'b0;
    assign gpio_val_o[ 3] = ( io3_mux == 2'b00) ? io_val_i[ 3] : 1'b0;
    assign gpio_val_o[ 4] = ( io4_mux == 2'b00) ? io_val_i[ 4] : 1'b0;
    assign gpio_val_o[ 5] = ( io5_mux == 2'b00) ? io_val_i[ 5] : 1'b0;
    assign gpio_val_o[ 6] = ( io6_mux == 2'b00) ? io_val_i[ 6] : 1'b0;
    assign gpio_val_o[ 7] = ( io7_mux == 2'b00) ? io_val_i[ 7] : 1'b0;
    assign gpio_val_o[ 8] = ( io8_mux == 2'b00) ? io_val_i[ 8] : 1'b0;
    assign gpio_val_o[ 9] = ( io9_mux == 2'b00) ? io_val_i[ 9] : 1'b0;
    assign gpio_val_o[10] = (io10_mux == 2'b00) ? io_val_i[10] : 1'b0;
    assign gpio_val_o[11] = (io11_mux == 2'b00) ? io_val_i[11] : 1'b0;
    assign gpio_val_o[12] = (io12_mux == 2'b00) ? io_val_i[12] : 1'b0;
    assign gpio_val_o[13] = (io13_mux == 2'b00) ? io_val_i[13] : 1'b0;
    assign gpio_val_o[14] = (io14_mux == 2'b00) ? io_val_i[14] : 1'b0;
    assign gpio_val_o[15] = (io15_mux == 2'b00) ? io_val_i[15] : 1'b0;

    assign uart_tx_val_o[0] = (io0_mux == 2'b01) ? io_val_i[0] :
                              (io3_mux == 2'b01) ? io_val_i[3] :
                              1'b0;
    assign uart_rx_val_o[0] = (io0_mux == 2'b10) ? io_val_i[0] :
                              (io3_mux == 2'b10) ? io_val_i[3] :
                              1'b0;
    assign uart_tx_val_o[1] = (io1_mux == 2'b01) ? io_val_i[1] :
                              (io4_mux == 2'b01) ? io_val_i[4] :
                              1'b0;
    assign uart_rx_val_o[1] = (io1_mux == 2'b10) ? io_val_i[1] :
                              (io4_mux == 2'b10) ? io_val_i[4] :
                              1'b0;
    assign uart_tx_val_o[2] = (io2_mux == 2'b01) ? io_val_i[2] :
                              (io5_mux == 2'b01) ? io_val_i[5] :
                              1'b0;
    assign uart_rx_val_o[2] = (io2_mux == 2'b10) ? io_val_i[2] :
                              (io5_mux == 2'b10) ? io_val_i[5] :
                              1'b0;

    assign i2c_scl_val_o[0] = (io6_mux == 2'b01) ? io_val_i[6] :
                              (io8_mux == 2'b01) ? io_val_i[8] :
                              1'b0;
    assign i2c_sda_val_o[0] = (io6_mux == 2'b10) ? io_val_i[6] :
                              (io8_mux == 2'b10) ? io_val_i[8] :
                              1'b0;
    assign i2c_scl_val_o[1] = (io7_mux == 2'b01) ? io_val_i[7] :
                              (io9_mux == 2'b01) ? io_val_i[9] :
                              1'b0;
    assign i2c_sda_val_o[1] = (io7_mux == 2'b10) ? io_val_i[7] :
                              (io9_mux == 2'b10) ? io_val_i[9] :
                              1'b0;

    assign spi_clk_val_o[0]   = (io10_mux == 2'b01) ? io_val_i[10] :
                                (io6_mux == 2'b11)  ? io_val_i[6] :
                                1'b0;
    assign spi_ss_val_o[0]    = (io11_mux == 2'b01) ? io_val_i[11] :
                                (io8_mux == 2'b11)  ? io_val_i[8] :
                                1'b0;
    assign spi_dq_val_o[0][0] = (io12_mux == 2'b01) ? io_val_i[12] :
                                (io1_mux == 2'b11)  ? io_val_i[1] :
                                1'b0;
    assign spi_dq_val_o[0][1] = (io13_mux == 2'b01) ? io_val_i[13] :
                                (io2_mux == 2'b11)  ? io_val_i[2] :
                                1'b0;
    assign spi_dq_val_o[0][2] = (io14_mux == 2'b01) ? io_val_i[14] :
                                (io4_mux == 2'b11)  ? io_val_i[4] :
                                1'b0;
    assign spi_dq_val_o[0][3] = (io15_mux == 2'b01) ? io_val_i[15] :
                                (io5_mux == 2'b11)  ? io_val_i[5] :
                                1'b0;

    pinmux_reg_top u_pinmux_reg_top (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .reg2hw     (reg2hw),
        .reg_we     (reg_we_i),
        .reg_re     (reg_re_i),
        .reg_wdata  (reg_wdata_i),
        .reg_be     (reg_be_i),
        .reg_addr   (reg_addr_i),
        .reg_rdata  (reg_rdata_o)
    );

endmodule
