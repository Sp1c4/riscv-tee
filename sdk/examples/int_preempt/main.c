#include <stdint.h>

#include "../../bsp/include/timer.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/gpio.h"
#include "../../bsp/include/uart.h"
#include "../../bsp/include/xprintf.h"
#include "../../bsp/include/pinmux.h"

/* 1.设置GPIO9中断优先级比timer0中断优先级高.
 * 2.count初始值为0，在timer0中断处理程序里等待count计数值为3, GPIO9每次中断触发时将count计数加1，
 *   当count计数值等于3时，将GPIO7状态每500ms取反.
*/

static volatile uint32_t count;

int main()
{
    count = 0;

    // 配置UART0引脚
    pinmux_set_io0_func(IO0_UART0_TX);
    pinmux_set_io3_func(IO3_UART0_RX);
    // 初始化UART0
    uart_init(UART0, uart0_putc);
    // 设置timer0 25分频
    timer_set_clk_div(TIMER0, 25);
    // timer0定时10ms
    timer_set_value(TIMER0, 10000);
    // 清timer0中断pending
    timer_clear_int_pending(TIMER0);
    // 使能timer0中断
    timer_set_int_enable(TIMER0, 1);
    // 设置timer0自动装载模式
    timer_set_mode_ontshot(TIMER0);
    // timer0中断优先级为1
    rvic_set_irq_prio_level(RVIC_TIMER0_INT_ID, 1);
    // 使能RVIC中断
    rvic_irq_enable(RVIC_TIMER0_INT_ID);
    // 使能全局中断
    global_irq_enable();
    // 启动timer0
    timer_start(TIMER0, 1);

    // IO7用作GPIO7
    pinmux_set_io7_func(IO7_GPIO7);
    // IO9用作GPIO9
    pinmux_set_io9_func(IO9_GPIO9);
    // gpio7输出模式
    gpio_set_mode(GPIO7, GPIO_MODE_OUTPUT);
    // gpio9输入模式
    gpio_set_mode(GPIO9, GPIO_MODE_INPUT);
    // gpio9双沿中断
    gpio_set_interrupt_mode(GPIO9, GPIO_INTR_DOUBLE_EDGE);
    rvic_irq_enable(RVIC_GPIO9_INT_ID);
    // gpio9中断优先级为2
    rvic_set_irq_prio_level(RVIC_GPIO9_INT_ID, 2);

    while (1) {
        if (count == 3) {
            gpio_set_output_toggle(GPIO7); // toggle led
            busy_wait(500 * 1000);
        }
    }
}

// timer0中断处理函数
void timer0_irq_handler()
{
    timer_clear_int_pending(TIMER0);
    rvic_clear_irq_pending(RVIC_TIMER0_INT_ID);

    xprintf("timer0 isr enter\n");
    // GPIO0对应LED为灭
    gpio_set_output_data(GPIO7, 1);

    while (count != 3);

    xprintf("timer0 isr exit\n");
}

// GPIO9中断处理函数
void gpio9_irq_handler()
{
    gpio_clear_intr_pending(GPIO9);
    rvic_clear_irq_pending(RVIC_GPIO9_INT_ID);

    xprintf("gpio1 isr\n");

    count++;
}
