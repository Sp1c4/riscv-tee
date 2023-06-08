#include <stdint.h>

#include "../include/uart.h"
#include "../include/xprintf.h"



int main()
{
    uart_init();
    xprintf("core0 IOPMP OPEN\n");
    xprintf("core0 IOPMP CLOSE\n");
    xprintf("core1 IOPMP OPEN\n");

    while (1);
}
