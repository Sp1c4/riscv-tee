// Generated register defines for spi

// Copyright information found in source file:
// Copyright lowRISC contributors.

// Licensing information found in source file:
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef _SPI_REG_DEFS_
#define _SPI_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define SPI_PARAM_REG_WIDTH 32

#define SPI0_BASE_ADDR              (0x07000000)

#define SPI0                        (SPI0_BASE_ADDR)

#define SPI_REG(base, offset)       (*((volatile uint32_t *)(base + offset)))

#define SPI_TX_FIFO_LEN    (8)
#define SPI_RX_FIFO_LEN    SPI_TX_FIFO_LEN

typedef enum {
    SPI_ROLE_MODE_MASTER = 0,
    SPI_ROLE_MODE_SLAVE
} spi_role_mode_e;

typedef enum {
    SPI_CPOL_0_CPHA_0 = 0,
    SPI_CPOL_0_CPHA_1,
    SPI_CPOL_1_CPHA_0,
    SPI_CPOL_1_CPHA_1
} spi_cp_mode_e;

typedef enum {
    SPI_MODE_STANDARD = 0,
    SPI_MODE_DUAL,
    SPI_MODE_QUAD
} spi_spi_mode_e;

void spi_set_clk_div(uint32_t base, uint16_t div);
void spi_set_role_mode(uint32_t base, spi_role_mode_e mode);
void spi_set_spi_mode(uint32_t base, spi_spi_mode_e mode);
void spi_set_cp_mode(uint32_t base, spi_cp_mode_e mode);
void spi_set_enable(uint32_t base, uint8_t en);
void spi_set_interrupt_enable(uint32_t base, uint8_t en);
void spi_set_msb_first(uint32_t base);
void spi_set_lsb_first(uint32_t base);
void spi_set_txdata(uint32_t base, uint8_t data);
uint8_t spi_get_rxdata(uint32_t base);
uint8_t spi_reset_rxfifo(uint32_t base);
uint8_t spi_tx_fifo_full(uint32_t base);
uint8_t spi_tx_fifo_empty(uint32_t base);
uint8_t spi_rx_fifo_full(uint32_t base);
uint8_t spi_rx_fifo_empty(uint32_t base);
void spi_set_ss_ctrl_by_sw(uint32_t base, uint8_t yes);
void spi_set_ss_level(uint32_t base, uint8_t level);
uint8_t spi_get_interrupt_pending(uint32_t base);
void spi_clear_interrupt_pending(uint32_t base);
void spi_master_set_read(uint32_t base);
void spi_master_set_write(uint32_t base);
void spi_master_set_ss_delay(uint32_t base, uint8_t clk_num);
uint8_t spi_master_transmiting(uint32_t base);
void spi_master_write_bytes(uint32_t base, uint8_t write_data[], uint32_t count);
void spi_master_read_bytes(uint32_t base, uint8_t read_data[], uint32_t count);

// SPI control 0 register
#define SPI_CTRL0_REG_OFFSET 0x0
#define SPI_CTRL0_REG_RESVAL 0x0
#define SPI_CTRL0_ENABLE_BIT 0
#define SPI_CTRL0_INT_EN_BIT 1
#define SPI_CTRL0_INT_PENDING_BIT 2
#define SPI_CTRL0_ROLE_MODE_BIT 3
#define SPI_CTRL0_CP_MODE_MASK 0x3
#define SPI_CTRL0_CP_MODE_OFFSET 4
#define SPI_CTRL0_CP_MODE_FIELD \
  ((bitfield_field32_t) { .mask = SPI_CTRL0_CP_MODE_MASK, .index = SPI_CTRL0_CP_MODE_OFFSET })
#define SPI_CTRL0_SPI_MODE_MASK 0x3
#define SPI_CTRL0_SPI_MODE_OFFSET 6
#define SPI_CTRL0_SPI_MODE_FIELD \
  ((bitfield_field32_t) { .mask = SPI_CTRL0_SPI_MODE_MASK, .index = SPI_CTRL0_SPI_MODE_OFFSET })
#define SPI_CTRL0_READ_BIT 8
#define SPI_CTRL0_MSB_FIRST_BIT 9
#define SPI_CTRL0_SS_SW_CTRL_BIT 10
#define SPI_CTRL0_SS_LEVEL_BIT 11
#define SPI_CTRL0_SS_DELAY_MASK 0xf
#define SPI_CTRL0_SS_DELAY_OFFSET 12
#define SPI_CTRL0_SS_DELAY_FIELD \
  ((bitfield_field32_t) { .mask = SPI_CTRL0_SS_DELAY_MASK, .index = SPI_CTRL0_SS_DELAY_OFFSET })
#define SPI_CTRL0_TX_FIFO_RESET_BIT 16
#define SPI_CTRL0_RX_FIFO_RESET_BIT 17
#define SPI_CTRL0_CLK_DIV_MASK 0x7
#define SPI_CTRL0_CLK_DIV_OFFSET 29
#define SPI_CTRL0_CLK_DIV_FIELD \
  ((bitfield_field32_t) { .mask = SPI_CTRL0_CLK_DIV_MASK, .index = SPI_CTRL0_CLK_DIV_OFFSET })

// SPI status register
#define SPI_STATUS_REG_OFFSET 0x4
#define SPI_STATUS_REG_RESVAL 0x0
#define SPI_STATUS_TX_FIFO_FULL_BIT 0
#define SPI_STATUS_TX_FIFO_EMPTY_BIT 1
#define SPI_STATUS_RX_FIFO_FULL_BIT 2
#define SPI_STATUS_RX_FIFO_EMPTY_BIT 3
#define SPI_STATUS_BUSY_BIT 4

// SPI TX data register
#define SPI_TXDATA_REG_OFFSET 0x8
#define SPI_TXDATA_REG_RESVAL 0x0

// SPI RX data register
#define SPI_RXDATA_REG_OFFSET 0xc
#define SPI_RXDATA_REG_RESVAL 0x0

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _SPI_REG_DEFS_
// End generated register defines for spi