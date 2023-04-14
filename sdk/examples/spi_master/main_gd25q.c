#include <stdint.h>

#include "../../bsp/include/uart.h"
#include "../../bsp/include/spi.h"
#include "../../bsp/include/xprintf.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/pinmux.h"
#include "../../bsp/include/sim_ctrl.h"
#include "../../bsp/include/flash_gd25q.h"


#define BUFFER_SIZE   (64)

uint8_t program_data[BUFFER_SIZE];
uint8_t read_data[BUFFER_SIZE];

// 标准三线SPI测试
static void standard_spi_test()
{
    uint16_t i;
    gd25q_id_t id;

    xprintf("Standard SPI test started...\n");

    flash_gd25q_set_spi_mode(SPI_MODE_STANDARD);
    // 读flash ID
    id = flash_gd25q_read_id();
    xprintf("manf id = 0x%2x\n", id.manf_id);
    xprintf("dev id = 0x%2x\n", id.dev_id);

    // 初始化要编程的数据
    for (i = 0; i < BUFFER_SIZE; i++)
        program_data[i] = i + 1;

    // 擦除第0个扇区
    flash_gd25q_sector_erase(0);
    xprintf("program data: \n");
    // 打印要编程的数据
    for (i = 0; i < BUFFER_SIZE; i++)
        xprintf("0x%x\n", program_data[i]);
    // 编程第1页
    flash_gd25q_page_program(program_data, BUFFER_SIZE, 1);
    // 读第1页
    flash_gd25q_read(read_data, BUFFER_SIZE, GD25Q_PAGE_TO_ADDR(1));
    xprintf("read data: \n");
    // 打印读出来的数据
    for (i = 0; i < BUFFER_SIZE; i++)
        xprintf("0x%x\n", read_data[i]);

    for (i = 0; i < BUFFER_SIZE; i++) {
        if (program_data[i] != read_data[i]) {
            xprintf("test failed!!!\n");
            return;
        }
    }

    xprintf("Standard SPI test succ...\n");
}

// QSPI测试
static void quad_spi_test()
{
    uint16_t i;

    xprintf("\nQuad SPI test started...\n");

    // 使能QSPI模式
    flash_gd25q_enable_quad_mode(1);
    flash_gd25q_set_spi_mode(SPI_MODE_QUAD);

    // 初始化要编程的数据
    for (i = 0; i < BUFFER_SIZE; i++)
        program_data[i] = i + 2;

    // 擦除第1个扇区
    flash_gd25q_sector_erase(1);
    xprintf("program data: \n");
    // 打印要编程的数据
    for (i = 0; i < BUFFER_SIZE; i++)
        xprintf("0x%x\n", program_data[i]);
    // 编程第16页
    flash_gd25q_page_program(program_data, BUFFER_SIZE, 16);
    // 读第16页
    flash_gd25q_read(read_data, BUFFER_SIZE, GD25Q_PAGE_TO_ADDR(16));
    xprintf("read data: \n");
    // 打印读出来的数据
    for (i = 0; i < BUFFER_SIZE; i++)
        xprintf("0x%x\n", read_data[i]);

    // 失能QSPI模式
    flash_gd25q_enable_quad_mode(0);
    spi_set_spi_mode(SPI0, SPI_MODE_STANDARD);
    flash_gd25q_set_spi_mode(SPI_MODE_STANDARD);

    for (i = 0; i < BUFFER_SIZE; i++) {
        if (program_data[i] != read_data[i]) {
            xprintf("test failed!!!\n");
            return;
        }
    }

    xprintf("Quad SPI test succ...\n");
}

int main()
{
    // UART引脚配置
    pinmux_set_io0_func(IO0_UART0_TX);
    pinmux_set_io3_func(IO3_UART0_RX);
    // SPI引脚配置
    pinmux_set_io10_func(IO10_SPI_CLK);
    pinmux_set_io11_func(IO11_SPI_SS);
    pinmux_set_io12_func(IO12_SPI_DQ0);
    pinmux_set_io13_func(IO13_SPI_DQ1);
    pinmux_set_io14_func(IO14_SPI_DQ2);
    pinmux_set_io15_func(IO15_SPI_DQ3);

    uart_init(UART0, uart0_putc);
    // 115200bps
    uart_set_baud_div(UART0, 0x68);
    flash_gd25q_init(SPI0, 5);

    standard_spi_test();
    quad_spi_test();

    while (1);
}
