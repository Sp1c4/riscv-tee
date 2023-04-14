// Generated register defines for timer

// Copyright information found in source file:
// Copyright lowRISC contributors.

// Licensing information found in source file:
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef _TIMER_REG_DEFS_
#define _TIMER_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define TIMER_PARAM_REG_WIDTH 32

#define TIMER0_BASE_ADDR            (0x04000000)
#define TIMER1_BASE_ADDR            (0x0C000000)
#define TIMER2_BASE_ADDR            (0x0D000000)

#define TIMER0                      (TIMER0_BASE_ADDR)
#define TIMER1                      (TIMER1_BASE_ADDR)
#define TIMER2                      (TIMER2_BASE_ADDR)

#define TIMER_REG(base, offset)     (*((volatile uint32_t *)(base + offset)))

void timer_start(uint32_t base, uint8_t en);
void timer_set_value(uint32_t base, uint32_t val);
void timer_set_int_enable(uint32_t base, uint8_t en);
void timer_clear_int_pending(uint32_t base);
uint8_t timer_get_int_pending(uint32_t base);
uint32_t timer_get_current_count(uint32_t base);
void timer_set_mode_auto_reload(uint32_t base);
void timer_set_mode_ontshot(uint32_t base);
void timer_set_clk_div(uint32_t base, uint32_t div);

// Timer control register
#define TIMER_CTRL_REG_OFFSET 0x0
#define TIMER_CTRL_REG_RESVAL 0x0
#define TIMER_CTRL_EN_BIT 0
#define TIMER_CTRL_INT_EN_BIT 1
#define TIMER_CTRL_INT_PENDING_BIT 2
#define TIMER_CTRL_MODE_BIT 3
#define TIMER_CTRL_CLK_DIV_MASK 0xffffff
#define TIMER_CTRL_CLK_DIV_OFFSET 8
#define TIMER_CTRL_CLK_DIV_FIELD \
  ((bitfield_field32_t) { .mask = TIMER_CTRL_CLK_DIV_MASK, .index = TIMER_CTRL_CLK_DIV_OFFSET })

// Timer expired value register
#define TIMER_VALUE_REG_OFFSET 0x4
#define TIMER_VALUE_REG_RESVAL 0x0

// Timer current count register
#define TIMER_COUNT_REG_OFFSET 0x8
#define TIMER_COUNT_REG_RESVAL 0x0

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _TIMER_REG_DEFS_
// End generated register defines for timer