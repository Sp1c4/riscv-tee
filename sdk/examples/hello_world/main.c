#include <stdint.h>

#include "../../bsp/include/sim_ctrl.h"
#include "../../bsp/include/uart.h"
#include "../../bsp/include/xprintf.h"
#include "../../bsp/include/pinmux.h"


int main()
{
#ifdef SIMULATION
    sim_ctrl_init();
#else
    uart_init(UART0, uart0_putc);
    pinmux_set_io0_func(IO0_UART0_TX);
    pinmux_set_io3_func(IO3_UART0_RX);
#endif

    xprintf("hello world\n");

    while (1);
}
