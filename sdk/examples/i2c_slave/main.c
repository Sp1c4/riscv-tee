#include <stdint.h>

#include "../../bsp/include/uart.h"
#include "../../bsp/include/i2c.h"
#include "../../bsp/include/xprintf.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/pinmux.h"


#define SLAVE_ADDR   (0xAA)

typedef enum {
    OP_NONE = 0,
    OP_READ,
    OP_WRITE,
} op_e;

static volatile op_e op;

int main()
{
    // UART0引脚配置
    pinmux_set_io0_func(IO0_UART0_TX);
    pinmux_set_io3_func(IO3_UART0_RX);
    // I2C0引脚配置
    pinmux_set_io6_func(IO6_I2C0_SCL);
    pinmux_set_io8_func(IO8_I2C0_SDA);
    // 初始化串口0
    uart_init(UART0, uart0_putc);
    // 设置I2C0为slave模式
    i2c_set_mode(I2C0, I2C_MODE_SLAVE);
    // 设置slave地址
    i2c_slave_set_address(I2C0, SLAVE_ADDR);
    // 使能I2C0中断
    i2c_set_interrupt_enable(I2C0, 1);
    // I2C0 ready
    i2c_slave_set_ready(I2C0, 1);

    // 设置I2C0中断优先级为1
    rvic_set_irq_prio_level(RVIC_I2C0_INT_ID, 1);
    // 使能I2C0中断
    rvic_irq_enable(RVIC_I2C0_INT_ID);
    // 使能全局中断
    global_irq_enable();

    // 启动I2C0
    i2c_start(I2C0);

    op = OP_NONE;

    while (1) {
        if (op == OP_READ) {
            xprintf("master read addr = 0x%x\n", i2c_slave_get_op_address(I2C0));
            i2c_slave_set_rsp_data(I2C0, 0x12345678);
            i2c_slave_set_ready(I2C0, 1);
            op = OP_NONE;
        } else if (op == OP_WRITE) {
            xprintf("master write addr = 0x%x\n", i2c_slave_get_op_address(I2C0));
            xprintf("master write data = 0x%x\n", i2c_slave_get_op_data(I2C0));
            i2c_slave_set_ready(I2C0, 1);
            op = OP_NONE;
        }
    }
}

// I2C0中断处理函数
void i2c0_irq_handler()
{
    // master是否为读操作
    if (i2c_slave_op_read(I2C0))
        op = OP_READ;
    else
        op = OP_WRITE;

    i2c_clear_irq_pending(I2C0);
    rvic_clear_irq_pending(RVIC_I2C0_INT_ID);
}
