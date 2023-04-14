RISCV_ARCH := rv32im
RISCV_ABI := ilp32
RISCV_MCMODEL := medlow


TARGET = timer


CFLAGS += -DSIMULATION
#CFLAGS += -Os
#ASM_SRCS +=
#LDFLAGS +=
#INCLUDES += -I.

C_SRCS := \
	main.c \


BSP_DIR = ../../bsp
include ../../bsp/bsp.mk
