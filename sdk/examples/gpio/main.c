#include <stdint.h>

#include "../../bsp/include/gpio.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/pinmux.h"

int main()
{
    // IO7用作GPIO7
    pinmux_set_io7_func(IO7_GPIO7);
    // IO9用作GPIO9
    pinmux_set_io9_func(IO9_GPIO9);
    // gpio7输出模式
    gpio_set_mode(GPIO7, GPIO_MODE_OUTPUT);
    // gpio9输入模式
    gpio_set_mode(GPIO9, GPIO_MODE_INPUT);
    // gpio9双沿中断模式
    gpio_set_interrupt_mode(GPIO9, GPIO_INTR_DOUBLE_EDGE);
    // 使能RVIC中断
    rvic_irq_enable(RVIC_GPIO9_INT_ID);
    // gpio9中断优先级为1
    rvic_set_irq_prio_level(RVIC_GPIO9_INT_ID, 1);
    // 使能全局中断
    global_irq_enable();

    while (1);
}

// GPIO9中断处理函数
void gpio9_irq_handler()
{
    gpio_clear_intr_pending(GPIO9);
    rvic_clear_irq_pending(RVIC_GPIO9_INT_ID);

    // 如果GPIO9输入高
    if (gpio_get_input_data(GPIO9))
        gpio_set_output_data(GPIO7, 1);  // GPIO7输出高
    // 如果GPIO9输入低
    else
        gpio_set_output_data(GPIO7, 0);  // GPIO7输出低
}
