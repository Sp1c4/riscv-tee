// Generated register defines for rvic

// Copyright information found in source file:
// Copyright lowRISC contributors.

// Licensing information found in source file:
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef _RVIC_REG_DEFS_
#define _RVIC_REG_DEFS_

#ifdef __cplusplus
extern "C" {
#endif
// Register width
#define RVIC_PARAM_REG_WIDTH 32

#define RVIC_BASE      (0xD0000000)
#define RVIC_REG(addr) (*((volatile uint32_t *)(RVIC_BASE + addr)))

#define RVIC_PRIO_REG_NUM  (8)

typedef struct {
    volatile uint32_t prio[RVIC_PRIO_REG_NUM];
} rvic_prio_t;

#define RVIC_PRIO  ((rvic_prio_t *)(RVIC_BASE + RVIC_PRIORITY0_REG_OFFSET))

typedef enum {
    RVIC_INT_ID_0 = 0,
    RVIC_INT_ID_1,
    RVIC_INT_ID_2,
    RVIC_INT_ID_3,
    RVIC_INT_ID_4,
    RVIC_INT_ID_5,
    RVIC_INT_ID_6,
    RVIC_INT_ID_7,
    RVIC_INT_ID_8,
    RVIC_INT_ID_9,
    RVIC_INT_ID_10,
    RVIC_INT_ID_11,
    RVIC_INT_ID_12,
    RVIC_INT_ID_13,
    RVIC_INT_ID_14,
    RVIC_INT_ID_15,
    RVIC_INT_ID_16,
    RVIC_INT_ID_17,
    RVIC_INT_ID_18,
    RVIC_INT_ID_19,
    RVIC_INT_ID_20,
    RVIC_INT_ID_21,
    RVIC_INT_ID_22,
    RVIC_INT_ID_23,
    RVIC_INT_ID_24,
    RVIC_INT_ID_25,
    RVIC_INT_ID_26,
    RVIC_INT_ID_27,
    RVIC_INT_ID_28,
    RVIC_INT_ID_29,
    RVIC_INT_ID_30,
    RVIC_INT_ID_31,
} rvic_int_id_e;

#define RVIC_TIMER0_INT_ID      RVIC_INT_ID_0
#define RVIC_UART0_INT_ID       RVIC_INT_ID_1
#define RVIC_GPIO0_INT_ID       RVIC_INT_ID_2
#define RVIC_GPIO1_INT_ID       RVIC_INT_ID_3
#define RVIC_I2C0_INT_ID        RVIC_INT_ID_4
#define RVIC_SPI0_INT_ID        RVIC_INT_ID_5
#define RVIC_GPIO2_4_INT_ID     RVIC_INT_ID_6
#define RVIC_GPIO5_7_INT_ID     RVIC_INT_ID_7
#define RVIC_GPIO8_INT_ID       RVIC_INT_ID_8
#define RVIC_GPIO9_INT_ID       RVIC_INT_ID_9
#define RVIC_GPIO10_12_INT_ID   RVIC_INT_ID_10
#define RVIC_GPIO13_15_INT_ID   RVIC_INT_ID_11
#define RVIC_UART1_INT_ID       RVIC_INT_ID_12
#define RVIC_UART2_INT_ID       RVIC_INT_ID_13
#define RVIC_I2C1_INT_ID        RVIC_INT_ID_14
#define RVIC_TIMER1_INT_ID      RVIC_INT_ID_15
#define RVIC_TIMER2_INT_ID      RVIC_INT_ID_16

void rvic_irq_enable(rvic_int_id_e id);
void rvic_irq_disable(rvic_int_id_e id);
void rvic_clear_irq_pending(rvic_int_id_e id);
void rvic_set_irq_prio_level(rvic_int_id_e id, uint8_t level);

// RVIC interrupt enable register
#define RVIC_ENABLE_REG_OFFSET 0x0
#define RVIC_ENABLE_REG_RESVAL 0x0

// RVIC interrupt pending register
#define RVIC_PENDING_REG_OFFSET 0x4
#define RVIC_PENDING_REG_RESVAL 0x0

// RVIC interrupt priority0 register
#define RVIC_PRIORITY0_REG_OFFSET 0x8
#define RVIC_PRIORITY0_REG_RESVAL 0x0

// RVIC interrupt priority1 register
#define RVIC_PRIORITY1_REG_OFFSET 0xc
#define RVIC_PRIORITY1_REG_RESVAL 0x0

// RVIC interrupt priority2 register
#define RVIC_PRIORITY2_REG_OFFSET 0x10
#define RVIC_PRIORITY2_REG_RESVAL 0x0

// RVIC interrupt priority3 register
#define RVIC_PRIORITY3_REG_OFFSET 0x14
#define RVIC_PRIORITY3_REG_RESVAL 0x0

// RVIC interrupt priority4 register
#define RVIC_PRIORITY4_REG_OFFSET 0x18
#define RVIC_PRIORITY4_REG_RESVAL 0x0

// RVIC interrupt priority5 register
#define RVIC_PRIORITY5_REG_OFFSET 0x1c
#define RVIC_PRIORITY5_REG_RESVAL 0x0

// RVIC interrupt priority6 register
#define RVIC_PRIORITY6_REG_OFFSET 0x20
#define RVIC_PRIORITY6_REG_RESVAL 0x0

// RVIC interrupt priority7 register
#define RVIC_PRIORITY7_REG_OFFSET 0x24
#define RVIC_PRIORITY7_REG_RESVAL 0x0

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // _RVIC_REG_DEFS_
// End generated register defines for rvic