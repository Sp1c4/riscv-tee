#include <stdint.h>

#include "../../bsp/include/uart.h"
#include "../../bsp/include/i2c.h"
#include "../../bsp/include/xprintf.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/pinmux.h"


#define SLAVE_ADDR   (0xA0)

static volatile uint8_t i2c_done;

static void i2c_master_write(uint8_t addr, uint8_t data)
{
    i2c_done = 0;
    i2c_master_set_write(I2C0, 1);
    i2c_master_set_info(I2C0, SLAVE_ADDR, addr, data);
    i2c_start(I2C0);

    while (!i2c_done);
}

static uint8_t i2c_master_read(uint8_t addr)
{
    i2c_done = 0;
    i2c_master_set_write(I2C0, 0);
    i2c_master_set_info(I2C0, SLAVE_ADDR, addr, 0);
    i2c_start(I2C0);

    while (!i2c_done);

    return (i2c_master_get_data(I2C0));
}

int main()
{
    uint8_t data, i;

    // UART0引脚配置
    pinmux_set_io0_func(IO0_UART0_TX);
    pinmux_set_io3_func(IO3_UART0_RX);
    // I2C0引脚配置
    pinmux_set_io6_func(IO6_I2C0_SCL);
    pinmux_set_io8_func(IO8_I2C0_SDA);
    // 初始化串口0
    uart_init(UART0, uart0_putc);
    // 设置I2C0时钟, 200KHZ
    i2c_set_clk(I2C0, 0x7D);
    // 设置I2C0 master模式
    i2c_set_mode(I2C0, I2C_MODE_MASTER);
    // 使能I2C0模块中断
    i2c_set_interrupt_enable(I2C0, 1);
    // 设置I2C0中断优先级为1
    rvic_set_irq_prio_level(RVIC_I2C0_INT_ID, 1);
    // 使能RVIC中断
    rvic_irq_enable(RVIC_I2C0_INT_ID);
    // 使能CPU中断
    global_irq_enable();

    // 写测试
    for (i = 0; i < 10; i++) {
        i2c_master_write(i, i);
        xprintf("write[%d] = 0x%x\n", i, i);
        busy_wait(100 * 1000);
    }

    // 读测试
    for (i = 0; i < 10; i++) {
        data = i2c_master_read(i);
        xprintf("read[%d] = 0x%x\n", i, data);
    }

    while (1);
}

// I2C0中断处理函数
void i2c0_irq_handler()
{
    i2c_done = 1;

    i2c_clear_irq_pending(I2C0);
    rvic_clear_irq_pending(RVIC_I2C0_INT_ID);
}
