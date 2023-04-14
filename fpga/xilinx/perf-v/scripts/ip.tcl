
create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name mmcm_main_clk -dir $ipdir -force

set_property -dict [list \
CONFIG.PRIM_IN_FREQ {50.000} \
CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {25.000} \
CONFIG.RESET_TYPE {ACTIVE_LOW} \
CONFIG.RESET_PORT {resetn}] \
[get_ips mmcm_main_clk]
