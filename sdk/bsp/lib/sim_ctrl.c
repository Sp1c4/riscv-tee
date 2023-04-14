#include <stdint.h>

#include "../include/xprintf.h"
#include "../include/sim_ctrl.h"


static void myputchar(unsigned char c) {
    *(volatile int *)SIM_STDOUT_REG = c;
}

void sim_ctrl_init()
{
    xdev_out(myputchar);
}

void sim_end()
{
    *(volatile int *)SIM_END_REG = 1;
}

void sim_dump_enable(uint8_t en)
{
    if (en)
        *(volatile int *)SIM_DUMP_REG = 1;
    else
        *(volatile int *)SIM_DUMP_REG = 0;
}
