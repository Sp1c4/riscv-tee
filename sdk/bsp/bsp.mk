RISCV_TOOLS_PATH := /opt/riscv32/bin
RISCV_TOOLS_PREFIX := riscv32-unknown-elf-

RISCV_GCC     := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)gcc)
RISCV_AS      := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)as)
RISCV_GXX     := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)g++)
RISCV_OBJDUMP := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)objdump)
RISCV_GDB     := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)gdb)
RISCV_AR      := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)ar)
RISCV_OBJCOPY := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)objcopy)
RISCV_READELF := $(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)readelf)

BIN_TO_MEM    := $(BSP_DIR)/../../tools/BinToMem.py

.PHONY: all
all: $(TARGET)

ASM_SRCS += $(BSP_DIR)/crt0.S
ASM_SRCS += $(BSP_DIR)/trap_entry.S

C_SRCS += $(BSP_DIR)/lib/utils.c
C_SRCS += $(BSP_DIR)/lib/xprintf.c
C_SRCS += $(BSP_DIR)/lib/uart.c
C_SRCS += $(BSP_DIR)/lib/sim_ctrl.c
C_SRCS += $(BSP_DIR)/lib/timer.c
C_SRCS += $(BSP_DIR)/lib/gpio.c
C_SRCS += $(BSP_DIR)/lib/rvic.c
C_SRCS += $(BSP_DIR)/lib/i2c.c
C_SRCS += $(BSP_DIR)/lib/spi.c
C_SRCS += $(BSP_DIR)/lib/pinmux.c
C_SRCS += $(BSP_DIR)/lib/flash_n25q.c
C_SRCS += $(BSP_DIR)/lib/flash_gd25q.c
C_SRCS += $(BSP_DIR)/lib/flash_ctrl.c

LINKER_SCRIPT := $(BSP_DIR)/link_rom.lds

INCLUDES += -I$(BSP_DIR)

LDFLAGS += -T $(LINKER_SCRIPT) -nostartfiles -Wl,--gc-sections -Wl,--check-sections

ASM_OBJS := $(ASM_SRCS:.S=.o)
C_OBJS := $(C_SRCS:.c=.o)

LINK_OBJS += $(ASM_OBJS) $(C_OBJS)
LINK_DEPS += $(LINKER_SCRIPT)

CLEAN_OBJS += $(TARGET) $(LINK_OBJS) $(TARGET).dump $(TARGET).bin $(TARGET).hex $(TARGET).mem

CFLAGS += -march=$(RISCV_ARCH)
CFLAGS += -mabi=$(RISCV_ABI)
CFLAGS += -mcmodel=$(RISCV_MCMODEL) -ffunction-sections -fdata-sections -fno-builtin-printf -fno-builtin-malloc

$(TARGET): $(LINK_OBJS) $(LINK_DEPS) Makefile
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) $(LINK_OBJS) -o $@ $(LDFLAGS)
	$(RISCV_OBJCOPY) -O binary $@ $@.bin
	$(RISCV_OBJDUMP) --disassemble-all $@ > $@.dump
	$(BIN_TO_MEM) $@.bin $@.mem

$(ASM_OBJS): %.o: %.S
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

$(C_OBJS): %.o: %.c
	$(RISCV_GCC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

.PHONY: clean
clean:
	rm -f $(CLEAN_OBJS)
