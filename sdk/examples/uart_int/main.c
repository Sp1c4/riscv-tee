#include <stdint.h>

#include "../../bsp/include/uart.h"
#include "../../bsp/include/xprintf.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/pinmux.h"


#define UART_TXB	(80)


static volatile struct {
	uint16_t	tri, twi, tct;
	uint8_t tbuf[UART_TXB];
} fifo;

static void uart_putc(uint8_t c)
{
	uint16_t i;

	if (fifo.tct >= UART_TXB)
        return;

	i = fifo.twi;
	fifo.tbuf[i] = c;
	fifo.twi = ++i % UART_TXB;

    global_irq_disable();
	fifo.tct++;
    // 使能TX FIFO空中断
    uart_tx_fifo_empty_int_enable(UART0, 1);
    global_irq_enable();
}

int main()
{
    // UART0引脚配置
    pinmux_set_io0_func(IO0_UART0_TX);
    pinmux_set_io3_func(IO3_UART0_RX);
    // UART0初始化
    uart_init(UART0, uart_putc);
    // 使能RVIC中断
    rvic_irq_enable(RVIC_UART0_INT_ID);
    // 设置UART0中断优先级为1
    rvic_set_irq_prio_level(RVIC_UART0_INT_ID, 1);
    // 使能RX FIFO非空中断
    uart_rx_fifo_not_empty_int_enable(UART0, 1);
    // 使能全局中断
    global_irq_enable();

    fifo.tri = 0; fifo.twi = 0; fifo.tct = 0;

    xprintf("uart interrupt test\n");
    while (1);
}

// UART0中断处理函数
void uart0_irq_handler()
{
    uint16_t i, count, index;
    uint8_t data;

    // 如果RX FIFO非空
    while (!uart_rx_fifo_empty(UART0)) {
        data = uart_get_rx_fifo_data(UART0);
        uart_set_tx_fifo_data(UART0, data);
    }
    // 如果TX FIFO为空
    if (uart_tx_fifo_empty(UART0) && (fifo.tct > 0)) {
        count = fifo.tct;
        if (count > UART_TX_FIFO_LEN)
            count = UART_TX_FIFO_LEN;
        for (index = 0; index < count; index++) {
            fifo.tct--;
            i = fifo.tri;
            // 发送数据
            uart_set_tx_fifo_data(UART0, fifo.tbuf[i]);
            fifo.tri = ++i % UART_TXB;
        }
        // 如果发完数据，则关闭TX FIFO空中断
        if (fifo.tct == 0)
            uart_tx_fifo_empty_int_enable(UART0, 0);
    }

    rvic_clear_irq_pending(RVIC_UART0_INT_ID);
}
