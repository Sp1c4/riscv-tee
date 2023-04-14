VIVADO_BASE := /home/ubuntu/Xilinx/Vivado/2018.1/bin
VIVADO := $(VIVADO_BASE)/vivado

VIVADOFLAGS := \
	-nojournal -mode batch \
	-source scripts/init.tcl

.PHONY: synth
synth:
	$(VIVADO) $(VIVADOFLAGS) -source scripts/synth.tcl

.PHONY: impl
impl:
	$(VIVADO) $(VIVADOFLAGS) -source scripts/synth.tcl -source scripts/impl.tcl

.PHONY: bit
bit:
	$(VIVADO) $(VIVADOFLAGS) -source scripts/synth.tcl -source scripts/impl.tcl -source scripts/bit_stream.tcl -source scripts/report.tcl

.PHONY: clean
clean::
	rm -rf .Xil .ip_user_files *.log *.jou out usage_statistics_webtalk.xml usage_statistics_webtalk.html
