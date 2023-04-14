// Generated register defines for pinmux

// Copyright information found in source file:
// Copyright lowRISC contributors.

// Licensing information found in source file:
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef _PINMUX_REG_DEFS_
#define _PINMUX_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define PINMUX_PARAM_REG_WIDTH 32

#define PINMUX_BASE_ADDR      (0x08000000)
#define PINMUX_REG(offset)    (*((volatile uint32_t *)(PINMUX_BASE_ADDR + offset)))

typedef enum {
    IO0_GPIO0 = 0x0,
    IO0_UART0_TX,
    IO0_UART0_RX,
} pinmux_io0_e;

typedef enum {
    IO1_GPIO1 = 0x0,
    IO1_UART1_TX,
    IO1_UART1_RX,
    IO1_SPI_DQ0,
} pinmux_io1_e;

typedef enum {
    IO2_GPIO2 = 0x0,
    IO2_UART2_TX,
    IO2_UART2_RX,
    IO2_SPI_DQ1,
} pinmux_io2_e;

typedef enum {
    IO3_GPIO3 = 0x0,
    IO3_UART0_TX,
    IO3_UART0_RX,
} pinmux_io3_e;

typedef enum {
    IO4_GPIO4 = 0x0,
    IO4_UART1_TX,
    IO4_UART1_RX,
    IO4_SPI_DQ2,
} pinmux_io4_e;

typedef enum {
    IO5_GPIO5 = 0x0,
    IO5_UART2_TX,
    IO5_UART2_RX,
    IO5_SPI_DQ3,
} pinmux_io5_e;

typedef enum {
    IO6_GPIO6 = 0x0,
    IO6_I2C0_SCL,
    IO6_I2C0_SDA,
    IO6_SPI_CLK,
} pinmux_io6_e;

typedef enum {
    IO7_GPIO7 = 0x0,
    IO7_I2C1_SCL,
    IO7_I2C1_SDA,
} pinmux_io7_e;

typedef enum {
    IO8_GPIO8 = 0x0,
    IO8_I2C0_SCL,
    IO8_I2C0_SDA,
    IO8_SPI_SS,
} pinmux_io8_e;

typedef enum {
    IO9_GPIO9 = 0x0,
    IO9_I2C1_SCL,
    IO9_I2C1_SDA,
} pinmux_io9_e;

typedef enum {
    IO10_GPIO10 = 0x0,
    IO10_SPI_CLK,
} pinmux_io10_e;

typedef enum {
    IO11_GPIO11 = 0x0,
    IO11_SPI_SS,
} pinmux_io11_e;

typedef enum {
    IO12_GPIO12 = 0x0,
    IO12_SPI_DQ0,
} pinmux_io12_e;

typedef enum {
    IO13_GPIO13 = 0x0,
    IO13_SPI_DQ1,
} pinmux_io13_e;

typedef enum {
    IO14_GPIO14 = 0x0,
    IO14_SPI_DQ2,
} pinmux_io14_e;

typedef enum {
    IO15_GPIO15 = 0x0,
    IO15_SPI_DQ3,
} pinmux_io15_e;

void pinmux_set_io0_func(pinmux_io0_e func);
void pinmux_set_io1_func(pinmux_io1_e func);
void pinmux_set_io2_func(pinmux_io2_e func);
void pinmux_set_io3_func(pinmux_io3_e func);
void pinmux_set_io4_func(pinmux_io4_e func);
void pinmux_set_io5_func(pinmux_io5_e func);
void pinmux_set_io6_func(pinmux_io6_e func);
void pinmux_set_io7_func(pinmux_io7_e func);
void pinmux_set_io8_func(pinmux_io8_e func);
void pinmux_set_io9_func(pinmux_io9_e func);
void pinmux_set_io10_func(pinmux_io10_e func);
void pinmux_set_io11_func(pinmux_io11_e func);
void pinmux_set_io12_func(pinmux_io12_e func);
void pinmux_set_io13_func(pinmux_io13_e func);
void pinmux_set_io14_func(pinmux_io14_e func);
void pinmux_set_io15_func(pinmux_io15_e func);

// Pinmux control register
#define PINMUX_CTRL_REG_OFFSET 0x0
#define PINMUX_CTRL_REG_RESVAL 0x0
#define PINMUX_CTRL_IO0_MUX_MASK 0x3
#define PINMUX_CTRL_IO0_MUX_OFFSET 0
#define PINMUX_CTRL_IO0_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO0_MUX_MASK, .index = PINMUX_CTRL_IO0_MUX_OFFSET })
#define PINMUX_CTRL_IO1_MUX_MASK 0x3
#define PINMUX_CTRL_IO1_MUX_OFFSET 2
#define PINMUX_CTRL_IO1_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO1_MUX_MASK, .index = PINMUX_CTRL_IO1_MUX_OFFSET })
#define PINMUX_CTRL_IO2_MUX_MASK 0x3
#define PINMUX_CTRL_IO2_MUX_OFFSET 4
#define PINMUX_CTRL_IO2_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO2_MUX_MASK, .index = PINMUX_CTRL_IO2_MUX_OFFSET })
#define PINMUX_CTRL_IO3_MUX_MASK 0x3
#define PINMUX_CTRL_IO3_MUX_OFFSET 6
#define PINMUX_CTRL_IO3_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO3_MUX_MASK, .index = PINMUX_CTRL_IO3_MUX_OFFSET })
#define PINMUX_CTRL_IO4_MUX_MASK 0x3
#define PINMUX_CTRL_IO4_MUX_OFFSET 8
#define PINMUX_CTRL_IO4_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO4_MUX_MASK, .index = PINMUX_CTRL_IO4_MUX_OFFSET })
#define PINMUX_CTRL_IO5_MUX_MASK 0x3
#define PINMUX_CTRL_IO5_MUX_OFFSET 10
#define PINMUX_CTRL_IO5_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO5_MUX_MASK, .index = PINMUX_CTRL_IO5_MUX_OFFSET })
#define PINMUX_CTRL_IO6_MUX_MASK 0x3
#define PINMUX_CTRL_IO6_MUX_OFFSET 12
#define PINMUX_CTRL_IO6_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO6_MUX_MASK, .index = PINMUX_CTRL_IO6_MUX_OFFSET })
#define PINMUX_CTRL_IO7_MUX_MASK 0x3
#define PINMUX_CTRL_IO7_MUX_OFFSET 14
#define PINMUX_CTRL_IO7_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO7_MUX_MASK, .index = PINMUX_CTRL_IO7_MUX_OFFSET })
#define PINMUX_CTRL_IO8_MUX_MASK 0x3
#define PINMUX_CTRL_IO8_MUX_OFFSET 16
#define PINMUX_CTRL_IO8_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO8_MUX_MASK, .index = PINMUX_CTRL_IO8_MUX_OFFSET })
#define PINMUX_CTRL_IO9_MUX_MASK 0x3
#define PINMUX_CTRL_IO9_MUX_OFFSET 18
#define PINMUX_CTRL_IO9_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO9_MUX_MASK, .index = PINMUX_CTRL_IO9_MUX_OFFSET })
#define PINMUX_CTRL_IO10_MUX_MASK 0x3
#define PINMUX_CTRL_IO10_MUX_OFFSET 20
#define PINMUX_CTRL_IO10_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO10_MUX_MASK, .index = PINMUX_CTRL_IO10_MUX_OFFSET })
#define PINMUX_CTRL_IO11_MUX_MASK 0x3
#define PINMUX_CTRL_IO11_MUX_OFFSET 22
#define PINMUX_CTRL_IO11_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO11_MUX_MASK, .index = PINMUX_CTRL_IO11_MUX_OFFSET })
#define PINMUX_CTRL_IO12_MUX_MASK 0x3
#define PINMUX_CTRL_IO12_MUX_OFFSET 24
#define PINMUX_CTRL_IO12_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO12_MUX_MASK, .index = PINMUX_CTRL_IO12_MUX_OFFSET })
#define PINMUX_CTRL_IO13_MUX_MASK 0x3
#define PINMUX_CTRL_IO13_MUX_OFFSET 26
#define PINMUX_CTRL_IO13_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO13_MUX_MASK, .index = PINMUX_CTRL_IO13_MUX_OFFSET })
#define PINMUX_CTRL_IO14_MUX_MASK 0x3
#define PINMUX_CTRL_IO14_MUX_OFFSET 28
#define PINMUX_CTRL_IO14_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO14_MUX_MASK, .index = PINMUX_CTRL_IO14_MUX_OFFSET })
#define PINMUX_CTRL_IO15_MUX_MASK 0x3
#define PINMUX_CTRL_IO15_MUX_OFFSET 30
#define PINMUX_CTRL_IO15_MUX_FIELD \
  ((bitfield_field32_t) { .mask = PINMUX_CTRL_IO15_MUX_MASK, .index = PINMUX_CTRL_IO15_MUX_OFFSET })

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _PINMUX_REG_DEFS_
// End generated register defines for pinmux