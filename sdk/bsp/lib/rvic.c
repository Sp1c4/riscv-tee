#include <stdint.h>

#include "../../bsp/include/rvic.h"


void rvic_irq_enable(rvic_int_id_e id)
{
    RVIC_REG(RVIC_ENABLE_REG_OFFSET) |= 1 << id;
}

void rvic_irq_disable(rvic_int_id_e id)
{
    RVIC_REG(RVIC_ENABLE_REG_OFFSET) &= ~(1 << id);
}

void rvic_clear_irq_pending(rvic_int_id_e id)
{
    RVIC_REG(RVIC_PENDING_REG_OFFSET) |= 1 << id;
}

void rvic_set_irq_prio_level(rvic_int_id_e id, uint8_t level)
{
    uint8_t reg;
    uint8_t index;

    reg = id >> 2;
    index = id % 4;

    RVIC_PRIO->prio[reg] &= ~(0xff << (index << 3));
    RVIC_PRIO->prio[reg] |= (level << (index << 3));
}
