#include <stdint.h>

#include "../include/utils.h"
#include "../include/uart.h"
#include "../include/xprintf.h"


// send one char to uart
void uart0_putc(uint8_t c)
{
    while (UART_REG(UART0, UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_TXFULL_BIT));

    UART_REG(UART0, UART_TXDATA_REG_OFFSET) = c;
}

// Block, get one char from uart.
uint8_t uart0_getc()
{
    while ((UART_REG(UART0, UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_RXEMPTY_BIT)));

    return (UART_REG(UART0, UART_RXDATA_REG_OFFSET) & 0xff);
}

// send one char to uart
void uart1_putc(uint8_t c)
{
    while (UART_REG(UART1, UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_TXFULL_BIT));

    UART_REG(UART1, UART_TXDATA_REG_OFFSET) = c;
}

// Block, get one char from uart.
uint8_t uart1_getc()
{
    while ((UART_REG(UART1, UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_RXEMPTY_BIT)));

    return (UART_REG(UART1, UART_RXDATA_REG_OFFSET) & 0xff);
}

// send one char to uart
void uart2_putc(uint8_t c)
{
    while (UART_REG(UART2, UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_TXFULL_BIT));

    UART_REG(UART2, UART_TXDATA_REG_OFFSET) = c;
}

// Block, get one char from uart.
uint8_t uart2_getc()
{
    while ((UART_REG(UART2, UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_RXEMPTY_BIT)));

    return (UART_REG(UART2, UART_RXDATA_REG_OFFSET) & 0xff);
}

// 115200bps, 8 N 1
void uart_init(uint32_t base, myputc put)
{
    // enable tx and rx
    UART_REG(base, UART_CTRL_REG_OFFSET) |= (1 << UART_CTRL_TX_EN_BIT) | (1 << UART_CTRL_RX_EN_BIT);
    uart_set_baud_div(base, CPU_FREQ_HZ / 115200);
    xdev_out(put);
}

void uart_tx_enable(uint32_t base, uint8_t en)
{
    if (en)
        UART_REG(base, UART_CTRL_REG_OFFSET) |= 1 << UART_CTRL_TX_EN_BIT;
    else
        UART_REG(base, UART_CTRL_REG_OFFSET) &= ~(1 << UART_CTRL_TX_EN_BIT);
}

void uart_rx_enable(uint32_t base, uint8_t en)
{
    if (en)
        UART_REG(base, UART_CTRL_REG_OFFSET) |= 1 << UART_CTRL_RX_EN_BIT;
    else
        UART_REG(base, UART_CTRL_REG_OFFSET) &= ~(1 << UART_CTRL_RX_EN_BIT);
}

void uart_tx_fifo_empty_int_enable(uint32_t base, uint8_t en)
{
    if (en)
        UART_REG(base, UART_CTRL_REG_OFFSET) |= 1 << UART_CTRL_TX_FIFO_EMPTY_INT_EN_BIT;
    else
        UART_REG(base, UART_CTRL_REG_OFFSET) &= ~(1 << UART_CTRL_TX_FIFO_EMPTY_INT_EN_BIT);
}

void uart_rx_fifo_not_empty_int_enable(uint32_t base, uint8_t en)
{
    if (en)
        UART_REG(base, UART_CTRL_REG_OFFSET) |= 1 << UART_CTRL_RX_FIFO_NOT_EMPTY_INT_EN_BIT;
    else
        UART_REG(base, UART_CTRL_REG_OFFSET) &= ~(1 << UART_CTRL_RX_FIFO_NOT_EMPTY_INT_EN_BIT);
}

void uart_set_baud_div(uint32_t base, uint32_t div)
{
    UART_REG(base, UART_CTRL_REG_OFFSET) &= ~(UART_CTRL_BAUD_DIV_MASK << UART_CTRL_BAUD_DIV_OFFSET);
    UART_REG(base, UART_CTRL_REG_OFFSET) |= div << UART_CTRL_BAUD_DIV_OFFSET;
}

void uart_reset_tx_fifo(uint32_t base)
{
    UART_REG(base, UART_CTRL_REG_OFFSET) |= 1 << UART_CTRL_TX_FIFO_RST_BIT;
}

void uart_reset_rx_fifo(uint32_t base)
{
    UART_REG(base, UART_CTRL_REG_OFFSET) |= 1 << UART_CTRL_RX_FIFO_RST_BIT;
}

uint8_t uart_tx_fifo_full(uint32_t base)
{
    if (UART_REG(base, UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_TXFULL_BIT))
        return 1;
    else
        return 0;
}

uint8_t uart_rx_fifo_full(uint32_t base)
{
    if (UART_REG(base, UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_RXFULL_BIT))
        return 1;
    else
        return 0;
}

uint8_t uart_tx_fifo_empty(uint32_t base)
{
    if (UART_REG(base, UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_TXEMPTY_BIT))
        return 1;
    else
        return 0;
}

uint8_t uart_rx_fifo_empty(uint32_t base)
{
    if (UART_REG(base, UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_RXEMPTY_BIT))
        return 1;
    else
        return 0;
}

uint8_t uart_tx_idle(uint32_t base)
{
    if (UART_REG(base, UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_TXIDLE_BIT))
        return 1;
    else
        return 0;
}

uint8_t uart_rx_idle(uint32_t base)
{
    if (UART_REG(base, UART_STATUS_REG_OFFSET) & (1 << UART_STATUS_RXIDLE_BIT))
        return 1;
    else
        return 0;
}

uint8_t uart_get_rx_fifo_data(uint32_t base)
{
    uint8_t data;

    data = UART_REG(base, UART_RXDATA_REG_OFFSET);

    return data;
}

void uart_set_tx_fifo_data(uint32_t base, uint8_t data)
{
    UART_REG(base, UART_TXDATA_REG_OFFSET) = data;
}
