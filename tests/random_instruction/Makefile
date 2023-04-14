TORTURE_PATH := ../../tools/riscv-torture

NUM := 0
export NUM

src_dir := .

default: all

SRCS := $(wildcard $(src_dir)/*.S)

ELFS = $(patsubst %.S, %, $(SRCS))

#--------------------------------------------------------------------
# Build rules
#--------------------------------------------------------------------

RISCV_PREFIX ?= /opt/riscv32/bin/riscv32-unknown-elf-
RISCV_GCC ?= $(RISCV_PREFIX)gcc
RISCV_LD ?= $(RISCV_PREFIX)ld
RISCV_GCC_OPTS ?= -march=rv32im -mabi=ilp32 -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump --disassemble-all
RISCV_OBJCOPY ?= $(RISCV_PREFIX)objcopy

BIN_TO_MEM := $(src_dir)/../../tools/BinToMem.py

#------------------------------------------------------------
# Build assembly tests

%.o:%.S riscv_test.h
	$(RISCV_GCC) -c $< $(RISCV_GCC_OPTS) -I$(src_dir) -o $@

$(ELFS):%:%.o
	$(RISCV_LD) $< -T$(src_dir)/link.ld -o $@
	$(RISCV_OBJDUMP) $@ > $@.dump
	$(RISCV_OBJCOPY) -O verilog $@  $@.verilog
	$(RISCV_OBJCOPY) -O binary $@ $@.bin
	$(BIN_TO_MEM) $@.bin $@.mem

all: $(ELFS)

gen:
	make -C $(TORTURE_PATH) gen
	mv $(TORTURE_PATH)/output/test*.S .

clean:
	rm -rf *.o $(ELFS) *.dump *.mem *.verilog *.bin
