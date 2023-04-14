export RISCV_TARGET       ?= tinyriscv
export RISCV_PREFIX       ?= /opt/riscv32/bin/riscv32-unknown-elf-

CURDIR = $(shell pwd)

export ROOTDIR    = $(CURDIR)
export TARGETDIR ?= $(ROOTDIR)/riscv-target
export BIN_TO_MEM = $(CURDIR)/../../tools/BinToMem.py

default: all

all:
	$(MAKE) RISCV_TARGET=$(RISCV_TARGET) RISCV_DEVICE=rv32i RISCV_PREFIX=$(RISCV_PREFIX) RISCV_ISA=rv32i run -C $(ROOTDIR)/riscv-test-suite/rv32i
	$(MAKE) RISCV_TARGET=$(RISCV_TARGET) RISCV_DEVICE=rv32im RISCV_PREFIX=$(RISCV_PREFIX) RISCV_ISA=rv32im run -C $(ROOTDIR)/riscv-test-suite/rv32im
	$(MAKE) RISCV_TARGET=$(RISCV_TARGET) RISCV_DEVICE=rv32Zicsr RISCV_PREFIX=$(RISCV_PREFIX) RISCV_ISA=rv32Zicsr run -C $(ROOTDIR)/riscv-test-suite/rv32Zicsr
	$(MAKE) RISCV_TARGET=$(RISCV_TARGET) RISCV_DEVICE=rv32Zifencei RISCV_PREFIX=$(RISCV_PREFIX) RISCV_ISA=rv32Zifencei run -C $(ROOTDIR)/riscv-test-suite/rv32Zifencei

clean:
	rm -rf build_generated
