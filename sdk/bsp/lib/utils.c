#include <stdint.h>

#include "../include/utils.h"



uint64_t get_cycle_value()
{
    uint64_t cycle;

    cycle = read_csr(cycle);
    cycle += (uint64_t)(read_csr(cycleh)) << 32;

    return cycle;
}

void busy_wait(uint32_t us)
{
    uint64_t tmp;
    uint32_t count;

    count = us * CPU_FREQ_MHZ;
    tmp = get_cycle_value();

    while (get_cycle_value() < (tmp + count));
}

void global_irq_enable()
{
    asm volatile("csrs  mstatus, %0\n" : : "r"(0x8));
}

void global_irq_disable()
{
    asm volatile("csrc  mstatus, %0\n" : : "r"(0x8));
}

void mtime_irq_enable()
{
    asm volatile("csrs  mie, %0\n" : : "r"(0x80));
}

void mtime_irq_disable()
{
    asm volatile("csrc  mie, %0\n" : : "r"(0x80));
}
