#include <stdint.h>

#include "../include/spi.h"


void spi_set_clk_div(uint32_t base, uint16_t div)
{
    SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_CLK_DIV_MASK << SPI_CTRL0_CLK_DIV_OFFSET);
    SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= div << SPI_CTRL0_CLK_DIV_OFFSET;
}

void spi_set_role_mode(uint32_t base, spi_role_mode_e mode)
{
    if (mode == SPI_ROLE_MODE_MASTER)
        SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(1 << SPI_CTRL0_ROLE_MODE_BIT);
    else
        SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_ROLE_MODE_BIT;
}

void spi_set_spi_mode(uint32_t base, spi_spi_mode_e mode)
{
    switch (mode) {
        case SPI_MODE_STANDARD:
            SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_SPI_MODE_MASK << SPI_CTRL0_SPI_MODE_OFFSET);
            break;

        case SPI_MODE_DUAL:
            SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_SPI_MODE_MASK << SPI_CTRL0_SPI_MODE_OFFSET);
            SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_SPI_MODE_OFFSET;
            break;

        case SPI_MODE_QUAD:
            SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_SPI_MODE_MASK << SPI_CTRL0_SPI_MODE_OFFSET);
            SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= 2 << SPI_CTRL0_SPI_MODE_OFFSET;
            break;
    }
}

void spi_set_cp_mode(uint32_t base, spi_cp_mode_e mode)
{
    switch (mode) {
        case SPI_CPOL_0_CPHA_0:
            SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_CP_MODE_MASK << SPI_CTRL0_CP_MODE_OFFSET);
            break;

        case SPI_CPOL_0_CPHA_1:
            SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_CP_MODE_MASK << SPI_CTRL0_CP_MODE_OFFSET);
            SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_CP_MODE_OFFSET;
            break;

        case SPI_CPOL_1_CPHA_0:
            SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_CP_MODE_MASK << SPI_CTRL0_CP_MODE_OFFSET);
            SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= 2 << SPI_CTRL0_CP_MODE_OFFSET;
            break;

        case SPI_CPOL_1_CPHA_1:
            SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= 3 << SPI_CTRL0_CP_MODE_OFFSET;
            break;
    }
}

void spi_set_enable(uint32_t base, uint8_t en)
{
    if (en)
        SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_ENABLE_BIT;
    else
        SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(1 << SPI_CTRL0_ENABLE_BIT);
}

void spi_set_interrupt_enable(uint32_t base, uint8_t en)
{
    if (en)
        SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_INT_EN_BIT;
    else
        SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(1 << SPI_CTRL0_INT_EN_BIT);
}

void spi_set_msb_first(uint32_t base)
{
    SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_MSB_FIRST_BIT;
}

void spi_set_lsb_first(uint32_t base)
{
    SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(1 << SPI_CTRL0_MSB_FIRST_BIT);
}

void spi_set_txdata(uint32_t base, uint8_t data)
{
    SPI_REG(base, SPI_TXDATA_REG_OFFSET) = data;
}

uint8_t spi_get_rxdata(uint32_t base)
{
    return (SPI_REG(base, SPI_RXDATA_REG_OFFSET) & 0xff);
}

uint8_t spi_reset_rxfifo(uint32_t base)
{
    uint8_t data;

    data = 0;

    while (!(SPI_REG(base, SPI_STATUS_REG_OFFSET) & (1 << SPI_STATUS_RX_FIFO_EMPTY_BIT))) {
        data = SPI_REG(base, SPI_RXDATA_REG_OFFSET);
    }

    return data;
}

void spi_set_ss_ctrl_by_sw(uint32_t base, uint8_t yes)
{
    if (yes)
        SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_SS_SW_CTRL_BIT;
    else
        SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(1 << SPI_CTRL0_SS_SW_CTRL_BIT);
}

void spi_set_ss_level(uint32_t base, uint8_t level)
{
    if (level)
        SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_SS_LEVEL_BIT;
    else
        SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(1 << SPI_CTRL0_SS_LEVEL_BIT);
}

uint8_t spi_tx_fifo_full(uint32_t base)
{
    if (SPI_REG(base, SPI_STATUS_REG_OFFSET) & (1 << SPI_STATUS_TX_FIFO_FULL_BIT))
        return 1;
    else
        return 0;
}

uint8_t spi_tx_fifo_empty(uint32_t base)
{
    if (SPI_REG(base, SPI_STATUS_REG_OFFSET) & (1 << SPI_STATUS_TX_FIFO_EMPTY_BIT))
        return 1;
    else
        return 0;
}

uint8_t spi_rx_fifo_full(uint32_t base)
{
    if (SPI_REG(base, SPI_STATUS_REG_OFFSET) & (1 << SPI_STATUS_RX_FIFO_FULL_BIT))
        return 1;
    else
        return 0;
}

uint8_t spi_rx_fifo_empty(uint32_t base)
{
    if (SPI_REG(base, SPI_STATUS_REG_OFFSET) & (1 << SPI_STATUS_RX_FIFO_EMPTY_BIT))
        return 1;
    else
        return 0;
}

uint8_t spi_get_interrupt_pending(uint32_t base)
{
    if (SPI_REG(base, SPI_CTRL0_REG_OFFSET) & (1 << SPI_CTRL0_INT_PENDING_BIT))
        return 1;
    else
        return 0;
}

void spi_clear_interrupt_pending(uint32_t base)
{
    SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= (1 << SPI_CTRL0_INT_PENDING_BIT);
}

void spi_master_set_read(uint32_t base)
{
    SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= 1 << SPI_CTRL0_READ_BIT;
}

void spi_master_set_write(uint32_t base)
{
    SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(1 << SPI_CTRL0_READ_BIT);
}

void spi_master_set_ss_delay(uint32_t base, uint8_t clk_num)
{
    SPI_REG(base, SPI_CTRL0_REG_OFFSET) &= ~(SPI_CTRL0_SS_DELAY_MASK << SPI_CTRL0_SS_DELAY_OFFSET);
    SPI_REG(base, SPI_CTRL0_REG_OFFSET) |= (clk_num & SPI_CTRL0_SS_DELAY_MASK) << SPI_CTRL0_SS_DELAY_OFFSET;
}

uint8_t spi_master_transmiting(uint32_t base)
{
    if (SPI_REG(base, SPI_STATUS_REG_OFFSET) & (1 << SPI_STATUS_BUSY_BIT))
        return 1;
    else
        return 0;
}

void spi_master_write_bytes(uint32_t base, uint8_t write_data[], uint32_t count)
{
    uint32_t i;

    spi_master_set_write(base);

    for (i = 0; i < count; i++) {
        spi_set_txdata(base, write_data[i]);
        while (spi_master_transmiting(base));
    }
}

void spi_master_read_bytes(uint32_t base, uint8_t read_data[], uint32_t count)
{
    uint32_t i;

    spi_master_set_read(base);

    for (i = 0; i < count; i++) {
        spi_set_txdata(base, 0xff);
        while (spi_master_transmiting(base));
        read_data[i] = spi_get_rxdata(base);
    }
}
