#include <stdint.h>

#include "../../bsp/include/gpio.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/pinmux.h"

int main()
{
    // IO7用作GPIO7
    pinmux_set_io7_func(IO7_GPIO7);
    // gpio7输出模式
    gpio_set_mode(GPIO7, GPIO_MODE_OUTPUT);

    while (1) {
        gpio_set_output_data(GPIO7, 1);  // GPIO7输出高
        busy_wait(500000);
        gpio_set_output_data(GPIO7, 0);  // GPIO7输出低
        busy_wait(500000);
    }
}
