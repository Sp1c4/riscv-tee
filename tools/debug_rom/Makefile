# See LICENSE.SiFive for license details

target := debug_rom_snd_scratch

BIN2MEM := ../BinToMem.py

RISCV_TOOLS_PATH := /opt/riscv32/bin
RISCV_TOOLS_PREFIX := riscv32-unknown-elf-

GCC?=$(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)gcc)
OBJCOPY?=$(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)objcopy)
OBJDUMP?=$(abspath $(RISCV_TOOLS_PATH)/$(RISCV_TOOLS_PREFIX)objdump)

all:
	$(GCC) -DSND_SCRATCH=1 -Tlink.ld debug_rom.S -nostdlib -fPIC -static -Wl,--no-gc-sections -o $(target).elf
	$(OBJCOPY) -O binary $(target).elf $(target).bin
	$(OBJDUMP) -d $(target).elf --disassemble-all --disassemble-zeroes --section=.text --section=.text.startup --section=.text.init --section=.data  > $(target).dump
	$(BIN2MEM) $(target).bin $(target).mem

clean:
	rm -f *.img *.dump *.bin *.sv *.elf *.mem
