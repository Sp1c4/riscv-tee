target := bootrom

BIN2MEM := ../BinToMem.py

RISCV_TOOLS_PATH := /opt/riscv32/bin
RISCV_TOOLS_PREFIX := riscv32-unknown-elf-

GCC?=$(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)gcc)
OBJCOPY?=$(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)objcopy)
OBJDUMP?=$(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)objdump)

all:
	$(GCC) -Tlink.ld bootrom.S -march=rv32im -mabi=ilp32 -mcmodel=medlow -nostartfiles -nostdlib -static -Wl,--no-gc-sections -o $(target).elf
	$(OBJCOPY) -O binary $(target).elf $(target).bin
	$(OBJDUMP) -d $(target).elf --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data  > $(target).dump
	$(BIN2MEM) $(target).bin $(target).mem

clean:
	rm -f *.img *.dump *.bin *.sv *.elf *.mem
