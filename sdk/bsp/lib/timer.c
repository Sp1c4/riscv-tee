#include <stdint.h>

#include "../include/timer.h"


void timer_start(uint32_t base, uint8_t en)
{
    if (en)
        TIMER_REG(base, TIMER_CTRL_REG_OFFSET) |= 1 << TIMER_CTRL_EN_BIT;
    else
        TIMER_REG(base, TIMER_CTRL_REG_OFFSET) &= ~(1 << TIMER_CTRL_EN_BIT);
}

void timer_set_value(uint32_t base, uint32_t val)
{
    TIMER_REG(base, TIMER_VALUE_REG_OFFSET) = val;
}

void timer_set_int_enable(uint32_t base, uint8_t en)
{
    if (en)
        TIMER_REG(base, TIMER_CTRL_REG_OFFSET) |= 1 << TIMER_CTRL_INT_EN_BIT;
    else
        TIMER_REG(base, TIMER_CTRL_REG_OFFSET) &= ~(1 << TIMER_CTRL_INT_EN_BIT);
}

void timer_clear_int_pending(uint32_t base)
{
    TIMER_REG(base, TIMER_CTRL_REG_OFFSET) |= 1 << TIMER_CTRL_INT_PENDING_BIT;
}

uint8_t timer_get_int_pending(uint32_t base)
{
    if (TIMER_REG(base, TIMER_CTRL_REG_OFFSET) & (1 << TIMER_CTRL_INT_PENDING_BIT))
        return 1;
    else
        return 0;
}

uint32_t timer_get_current_count(uint32_t base)
{
    return TIMER_REG(base, TIMER_COUNT_REG_OFFSET);
}

void timer_set_mode_auto_reload(uint32_t base)
{
    TIMER_REG(base, TIMER_CTRL_REG_OFFSET) |= 1 << TIMER_CTRL_MODE_BIT;
}

void timer_set_mode_ontshot(uint32_t base)
{
    TIMER_REG(base, TIMER_CTRL_REG_OFFSET) &= ~(1 << TIMER_CTRL_MODE_BIT);
}

void timer_set_clk_div(uint32_t base, uint32_t div)
{
    TIMER_REG(base, TIMER_CTRL_REG_OFFSET) &= ~(TIMER_CTRL_CLK_DIV_MASK << TIMER_CTRL_CLK_DIV_OFFSET);
    TIMER_REG(base, TIMER_CTRL_REG_OFFSET) |= div << TIMER_CTRL_CLK_DIV_OFFSET;
}
