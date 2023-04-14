#include <stdint.h>

#include "../../bsp/include/timer.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/gpio.h"
#include "../../bsp/include/pinmux.h"

static volatile uint32_t count;

int main()
{
    count = 0;

#ifdef SIMULATION

    timer_set_clk_div(TIMER0, 50);
    timer_set_value(TIMER0, 100);    // 100us period
    timer_clear_int_pending(TIMER0);
    timer_set_int_enable(TIMER0, 1);
    timer_set_mode_auto_reload(TIMER0);
    rvic_set_irq_prio_level(RVIC_TIMER0_INT_ID, 1);
    rvic_irq_enable(RVIC_TIMER0_INT_ID);
    global_irq_enable();

    timer_start(TIMER0, 1);

    while (1) {
        if (count == 3) {
            timer_start(TIMER0, 0);
            // TODO: do something
            set_test_pass();
            break;
        }
    }

    return 0;

#else

    // timer0时钟25分频，即1MHZ
    timer_set_clk_div(TIMER0, 25);
    // timer0定时时间10ms
    timer_set_value(TIMER0, 10000);
    // 清timer0中断pending
    timer_clear_int_pending(TIMER0);
    // 使能timer0中断
    timer_set_int_enable(TIMER0, 1);
    // 设置timer0自动装载模式
    timer_set_mode_auto_reload(TIMER0);
    // 设置timer0中断优先级为1
    rvic_set_irq_prio_level(RVIC_TIMER0_INT_ID, 1);
    // 使能RVIC中断
    rvic_irq_enable(RVIC_TIMER0_INT_ID);
    // 使能全局中断
    global_irq_enable();

    // 启动timer0
    timer_start(TIMER0, 1);

    // IO7用作GPIO7
    pinmux_set_io7_func(IO7_GPIO7);
    // GPIO7输出使能
    gpio_set_mode(GPIO7, GPIO_MODE_OUTPUT);

    while (1) {
        // 500ms
        if (count == 50) {
            count = 0;
            // 取反GPIO7状态
            gpio_set_output_toggle(GPIO7); // toggle led
        }
    }
#endif
}

// timer0中断处理函数
void timer0_irq_handler()
{
    timer_clear_int_pending(TIMER0);
    rvic_clear_irq_pending(RVIC_TIMER0_INT_ID);

    count++;
}
