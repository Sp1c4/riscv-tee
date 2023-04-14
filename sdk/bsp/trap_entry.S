#define REGBYTES  4
#define STORE     sw
#define LOAD      lw

    .section      .text.vector
    .align 2
    .global trap_entry
    .global vector_table

vector_table:
    .word illegal_instruction_handler
    .word instruction_addr_misaligned_handler
    .word ecall_handler
    .word ebreak_handler
    .word load_misaligned_handler
    .word store_misaligned_handler
    .word handle_exception_unknown
    .word handle_exception_unknown
    .word timer0_irq_handler
    .word uart0_irq_handler
    .word gpio0_irq_handler
    .word gpio1_irq_handler
    .word i2c0_irq_handler
    .word spi0_irq_handler
    .word gpio2_4_irq_handler
    .word gpio5_7_irq_handler
    .word gpio8_irq_handler
    .word gpio9_irq_handler
    .word gpio10_12_irq_handler
    .word gpio13_15_irq_handler
    .word uart1_irq_handler
    .word uart2_irq_handler
    .word i2c1_irq_handler
    .word timer1_irq_handler
    .word timer2_irq_handler
    /* add your ISR here */

.weak illegal_instruction_handler
.weak instruction_addr_misaligned_handler
.weak ecall_handler
.weak ebreak_handler
.weak load_misaligned_handler
.weak store_misaligned_handler
.weak handle_exception_unknown
.weak timer0_irq_handler
.weak uart0_irq_handler
.weak gpio0_irq_handler
.weak gpio1_irq_handler
.weak i2c0_irq_handler
.weak spi0_irq_handler
.weak gpio2_4_irq_handler
.weak gpio5_7_irq_handler
.weak gpio8_irq_handler
.weak gpio9_irq_handler
.weak gpio10_12_irq_handler
.weak gpio13_15_irq_handler
.weak uart1_irq_handler
.weak uart2_irq_handler
.weak i2c1_irq_handler
.weak timer1_irq_handler
.weak timer2_irq_handler

handle_exception_unknown:
    j handle_exception_unknown

illegal_instruction_handler:
#ifdef SIMULATION
    call sim_ctrl_init
    la a0, illegal_instruction_msg
    jal ra, xputs
#endif
illegal_instruction_loop:
    j illegal_instruction_loop

instruction_addr_misaligned_handler:
    j instruction_addr_misaligned_handler

ecall_handler:
    j ecall_handler

ebreak_handler:
    j ebreak_handler

load_misaligned_handler:
    j load_misaligned_handler

store_misaligned_handler:
    j store_misaligned_handler

timer0_irq_handler:
    j timer0_irq_handler

uart0_irq_handler:
    j uart0_irq_handler

gpio0_irq_handler:
    j gpio0_irq_handler

gpio1_irq_handler:
    j gpio1_irq_handler

i2c0_irq_handler:
    j i2c0_irq_handler

spi0_irq_handler:
    j spi0_irq_handler

gpio2_4_irq_handler:
    j gpio2_4_irq_handler

gpio5_7_irq_handler:
    j gpio5_7_irq_handler

gpio8_irq_handler:
    j gpio8_irq_handler

gpio9_irq_handler:
    j gpio9_irq_handler

gpio10_12_irq_handler:
    j gpio10_12_irq_handler

gpio13_15_irq_handler:
    j gpio13_15_irq_handler

uart1_irq_handler:
    j uart1_irq_handler

uart2_irq_handler:
    j uart2_irq_handler

i2c1_irq_handler:
    j i2c1_irq_handler

timer1_irq_handler:
    j timer1_irq_handler

timer2_irq_handler:
    j timer2_irq_handler

/* 异常和中断总入口 */
trap_entry:
    addi sp, sp, -32*17
    sw x1,   0*4(sp)
    sw x5,   1*4(sp)
    sw x6,   2*4(sp)
    sw x7,   3*4(sp)
    sw x10,  4*4(sp)
    sw x11,  5*4(sp)
    sw x12,  6*4(sp)
    sw x13,  7*4(sp)
    sw x14,  8*4(sp)
    sw x15,  9*4(sp)
    sw x16, 10*4(sp)
    sw x17, 11*4(sp)
    sw x28, 12*4(sp)
    sw x29, 13*4(sp)
    sw x30, 14*4(sp)
    sw x31, 15*4(sp)
    /* 保存异常(中断)返回地址 */
    csrr x10, mepc
    sw x10, 16*4(sp)

    /* 使能全局中断 */
    csrrsi x0, mstatus, 0x8

    /* 读取异常(中断)号 */
    csrr a1, mcause
    /* 计算偏移地址: id * 4 */
    slli a1, a1, 2
    la a0, vector_table
    add a1, a0, a1
    /* 读取异常(中断)处理函数地址 */
    lw a1, 0(a1)
    /* 跳转到异常(中断)处理函数 */
    jalr ra, 0(a1)

    /* 恢复异常(中断)返回地址 */
    lw x10,  16*4(sp)
    csrw mepc, x10
    lw x1,   0*4(sp)
    lw x5,   1*4(sp)
    lw x6,   2*4(sp)
    lw x7,   3*4(sp)
    lw x10,  4*4(sp)
    lw x11,  5*4(sp)
    lw x12,  6*4(sp)
    lw x13,  7*4(sp)
    lw x14,  8*4(sp)
    lw x15,  9*4(sp)
    lw x16, 10*4(sp)
    lw x17, 11*4(sp)
    lw x28, 12*4(sp)
    lw x29, 13*4(sp)
    lw x30, 14*4(sp)
    lw x31, 15*4(sp)
    addi sp, sp, 32*17
    mret

#ifdef SIMULATION
.section .rodata
illegal_instruction_msg:
	.string "illegal instruction exception handler entered\n"
#endif
