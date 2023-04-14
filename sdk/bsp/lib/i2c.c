#include <stdint.h>

#include "../include/i2c.h"


void i2c_set_clk(uint32_t base, uint16_t clk_div)
{
    I2C_REG(base, I2C_CTRL_REG_OFFSET) &= ~(I2C_CTRL_CLK_DIV_MASK << I2C_CTRL_CLK_DIV_OFFSET);
    I2C_REG(base, I2C_CTRL_REG_OFFSET) |= clk_div << I2C_CTRL_CLK_DIV_OFFSET;
}

void i2c_set_mode(uint32_t base, i2c_mode_e mode)
{
    if (mode == I2C_MODE_MASTER)
        I2C_REG(base, I2C_CTRL_REG_OFFSET) &= ~(1 << I2C_CTRL_MODE_BIT);
    else
        I2C_REG(base, I2C_CTRL_REG_OFFSET) |= 1 << I2C_CTRL_MODE_BIT;
}

void i2c_master_set_write(uint32_t base, uint8_t yes)
{
    if (yes)
        I2C_REG(base, I2C_CTRL_REG_OFFSET) &= ~(1 << I2C_CTRL_WRITE_BIT);
    else
        I2C_REG(base, I2C_CTRL_REG_OFFSET) |= 1 << I2C_CTRL_WRITE_BIT;
}

void i2c_set_interrupt_enable(uint32_t base, uint8_t en)
{
    if (en)
        I2C_REG(base, I2C_CTRL_REG_OFFSET) |= 1 << I2C_CTRL_INT_EN_BIT;
    else
        I2C_REG(base, I2C_CTRL_REG_OFFSET) &= ~(1 << I2C_CTRL_INT_EN_BIT);
}

void i2c_clear_irq_pending(uint32_t base)
{
    I2C_REG(base, I2C_CTRL_REG_OFFSET) |= 1 << I2C_CTRL_INT_PENDING_BIT;
}

uint8_t i2c_get_irq_pending(uint32_t base)
{
    if (I2C_REG(base, I2C_CTRL_REG_OFFSET) & (1 << I2C_CTRL_INT_PENDING_BIT))
        return 1;
    else
        return 0;
}

void i2c_master_set_info(uint32_t base, uint8_t addr, uint8_t reg, uint8_t data)
{
    I2C_REG(base, I2C_MASTER_DATA_REG_OFFSET) = (addr << I2C_MASTER_DATA_ADDRESS_OFFSET) |
                                                         (reg << I2C_MASTER_DATA_REGREG_OFFSET) |
                                                         (data << I2C_MASTER_DATA_DATA_OFFSET);
}

uint8_t i2c_master_get_data(uint32_t base)
{
    uint8_t data;

    data = (I2C_REG(base, I2C_MASTER_DATA_REG_OFFSET) >> I2C_MASTER_DATA_DATA_OFFSET) & I2C_MASTER_DATA_DATA_MASK;

    return data;
}

void i2c_slave_set_address(uint32_t base, uint8_t addr)
{
    I2C_REG(base, I2C_CTRL_REG_OFFSET) &= ~(I2C_CTRL_SLAVE_ADDR_MASK << I2C_CTRL_SLAVE_ADDR_OFFSET);
    I2C_REG(base, I2C_CTRL_REG_OFFSET) |= addr << I2C_CTRL_SLAVE_ADDR_OFFSET;
}

void i2c_slave_set_ready(uint32_t base, uint8_t yes)
{
    if (yes)
        I2C_REG(base, I2C_CTRL_REG_OFFSET) |= 1 << I2C_CTRL_SLAVE_RDY_BIT;
    else
        I2C_REG(base, I2C_CTRL_REG_OFFSET) &= ~(1 << I2C_CTRL_SLAVE_RDY_BIT);
}

uint8_t i2c_slave_op_read(uint32_t base)
{
    if (I2C_REG(base, I2C_CTRL_REG_OFFSET) & (1 << I2C_CTRL_SLAVE_WR_BIT))
        return 1;
    else
        return 0;
}

uint32_t i2c_slave_get_op_address(uint32_t base)
{
    return (I2C_REG(base, I2C_SLAVE_ADDR_REG_OFFSET));
}

uint32_t i2c_slave_get_op_data(uint32_t base)
{
    return (I2C_REG(base, I2C_SLAVE_WDATA_REG_OFFSET));
}

void i2c_slave_set_rsp_data(uint32_t base, uint32_t data)
{
    I2C_REG(base, I2C_SLAVE_RDATA_REG_OFFSET) = data;
}

void i2c_start(uint32_t base)
{
    I2C_REG(base, I2C_CTRL_REG_OFFSET) |= 1 << I2C_CTRL_START_BIT;
}

void i2c_stop(uint32_t base)
{
    I2C_REG(base, I2C_CTRL_REG_OFFSET) &= ~(1 << I2C_CTRL_START_BIT);
}
