
PROG := ../sdk/examples/simple/simple.mem
PROG_DIR := $(shell dirname $(PROG))

MAKE := make
VERILATOR := verilator

VERI_FLAGS += +vcd
VERI_CFLAGS += -DVL_DEBUG

VERI_VFLAGS += -DTRACE_ENABLED

RTL_FILES = ../rtl.flist

VERI_OBJ_DIR := cobj_dir

ifeq ($(findstring +vcd,$(VERI_FLAGS)),+vcd)
VERI_TRACE = "--trace"
VERI_CFLAGS += "-DVCD_TRACE"
else
VERI_TRACE =
endif

SIM_SRC := sim_jtag.sv sim_ctrl.sv

SIM_SRC += tb_top_verilator.sv \
           tb_top_verilator.cpp \
           tinyriscv_soc_top.sv

SIM_TOP_MODULE := tb_top_verilator

.DEFAULT_GOAL := sim
all: sim

.PHONY: recompile
recompile:
	rm -rf $(VERI_OBJ_DIR) testbench_verilator
	$(MAKE) -C ./remote_bitbang clean
	$(MAKE) -C $(PROG_DIR) clean
	$(MAKE) compile

.PHONY: compile
compile: remote_bitbang/librbs.so $(PROG) testbench_verilator

testbench_verilator:
	$(VERILATOR) --cc --sv --exe \
		$(VERI_TRACE) \
		--Wno-lint --Wno-UNOPTFLAT \
		--Wno-MODDUP --top-module \
		$(SIM_TOP_MODULE) \
		-f $(RTL_FILES) \
		$(SIM_SRC) \
		--Mdir $(VERI_OBJ_DIR) \
		$(VERI_VFLAGS) \
		-LDFLAGS "-L../remote_bitbang \
		-Wl,--enable-new-dtags -Wl,-rpath,remote_bitbang -lrbs" \
		-CFLAGS "-std=gnu++11 $(VERI_CFLAGS)"
	$(MAKE) -C $(VERI_OBJ_DIR) -f V$(SIM_TOP_MODULE).mk
	cp $(VERI_OBJ_DIR)/V$(SIM_TOP_MODULE) testbench_verilator

remote_bitbang/librbs.so:
	$(MAKE) -C ./remote_bitbang all

$(PROG):
	$(MAKE) -C $(PROG_DIR)

.PHONY: run
run:
	./testbench_verilator "+firmware=$(PROG)"

.PHONY: sim
sim: recompile run

.PHONY: clean
clean:
	rm -rf $(VERI_OBJ_DIR) testbench_verilator *.log *.vcd
	$(MAKE) -C ./remote_bitbang clean
	$(MAKE) -C $(PROG_DIR) clean

.PHONY: help
help:
	@echo 'rebuild all:'
	@echo 'make PROG=/path/file.mem recompile'
	@echo 'run directly:'
	@echo 'make PROG=/path/file.mem run'
	@echo 'rebuild & run:'
	@echo 'make PROG=/path/file.mem sim'
	@echo 'clean obj files:'
	@echo 'make PROG=/path/file.mem clean'
