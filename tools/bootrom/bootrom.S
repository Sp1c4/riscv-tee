
    .global entry
    .option norvc

entry:
    // enable quad spi mode
    lui	a1, 0x2c00
    sw	zero, 0(a1)

    // xip base address(0x02000000)
    lui	a0, 0x2000

    // jump to xip base address
    jalr  a0

loop:
    j loop
