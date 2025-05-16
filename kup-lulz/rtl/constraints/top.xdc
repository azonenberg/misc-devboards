########################################################################################################################
# Pin constraints

set_property PACKAGE_PIN C18 [get_ports clk_156m25_p]
set_property IOSTANDARD LVDS [get_ports clk_156m25_p]
set_property IOSTANDARD LVDS [get_ports clk_156m25_n]
set_property PACKAGE_PIN A24 [get_ports gpio_p]

set_property PACKAGE_PIN V7 [get_ports refclk_p]

set_property PACKAGE_PIN AF7 [get_ports smpm_0_tx_p]

set_property PACKAGE_PIN AE4 [get_ports smpm_1_rx_p]

set_property IOSTANDARD LVCMOS33 [get_ports {sfp0_rs[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sfp0_rs[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports sfp0_tx_disable]
set_property PACKAGE_PIN P2 [get_ports sfp_0_rx_p]
set_property PACKAGE_PIN T2 [get_ports sfp_1_rx_p]
set_property PACKAGE_PIN C11 [get_ports sfp0_tx_disable]
set_property PACKAGE_PIN G14 [get_ports {sfp0_rs[1]}]
set_property PACKAGE_PIN G12 [get_ports {sfp0_rs[0]}]

set_property PACKAGE_PIN AD2 [get_ports smpm_2_rx_p]

########################################################################################################################
# Clocks

create_clock -period 6.400 -name clk_156m25_p -waveform {0.000 3.200} [get_ports clk_156m25_p]
create_clock -period 6.400 -name refclk_p -waveform {0.000 3.200} [get_ports refclk_p]

########################################################################################################################
# CDC constraints

# Synchronizer max delays: 5 ns (200 MHz) is << 1 cycle of both clocks
#set_max_delay -datapath_only -from [get_cells -hierarchical -filter { NAME =~  "*sync*" && NAME =~  "*a_ff*" }] -to [get_cells -hierarchical -filter { NAME =~  "*sync*" && NAME =~  "*reg_b*" }] 5.000
#set_max_delay -from [get_cells -hierarchical -filter { NAME =~  "*sync*" && NAME =~  "*dout0_reg*" }] -to [get_cells -hierarchical -filter { NAME =~  "*sync*" && NAME =~  "*dout1_reg*" }] 5.000
#set_max_delay -from [get_cells -hierarchical -filter { NAME =~  "*sync*" && NAME =~  "*tx_a_reg*" }] -to [get_cells -hierarchical -filter { NAME =~  "*sync*" && NAME =~  "*dout1_reg*" }] 5.000

# APB clock domain crossings: 5 ns (200 MHz) is << 1 cycle of both clocks

########################################################################################################################
# Put the timestamp in the bitstream USERCODE

set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]

########################################################################################################################
# Debugging

set_property IOSTANDARD LVCMOS33 [get_ports sfp0_rx_los]
set_property PACKAGE_PIN F14 [get_ports sfp0_rx_los]

set_clock_groups -asynchronous -group [get_clocks rxoutclk_raw] -group [get_clocks txoutclk_raw]

set_clock_groups -asynchronous -group [get_clocks rxoutclk_raw] -group [get_clocks rxoutclk_raw_1]
set_clock_groups -asynchronous -group [get_clocks txoutclk_raw_2] -group [get_clocks rxoutclk_raw_2]
set_clock_groups -asynchronous -group [get_clocks txoutclk_raw_3] -group [get_clocks rxoutclk_raw_3]
set_clock_groups -asynchronous -group [get_clocks txoutclk_raw_4] -group [get_clocks rxoutclk_raw_4]
set_clock_groups -asynchronous -group [get_clocks rxoutclk_raw] -group [get_clocks txoutclk_raw_1]
set_clock_groups -asynchronous -group [get_clocks rxoutclk_raw_2] -group [get_clocks txoutclk_raw_2]
set_clock_groups -asynchronous -group [get_clocks rxoutclk_raw_3] -group [get_clocks txoutclk_raw_3]
set_clock_groups -asynchronous -group [get_clocks rxoutclk_raw_4] -group [get_clocks txoutclk_raw_4]
set_clock_groups -asynchronous -group [get_clocks txoutclk_raw_1] -group [get_clocks rxoutclk_raw]

set_clock_groups -asynchronous -group [get_clocks txoutclk_raw_2] -group [get_clocks clk_156m25_p]
set_clock_groups -asynchronous -group [get_clocks clk_156m25_p] -group [get_clocks txoutclk_raw_2]

set_false_path -from [get_clocks rxoutclk_raw] -to [get_clocks clk_156m25_p]

set_clock_groups -asynchronous -group [get_clocks txoutclk_raw_3] -group [get_clocks clk_156m25_p]
set_clock_groups -asynchronous -group [get_clocks txoutclk_raw_4] -group [get_clocks clk_156m25_p]
set_clock_groups -asynchronous -group [get_clocks clk_156m25_p] -group [get_clocks rxoutclk_raw]
set_clock_groups -asynchronous -group [get_clocks txoutclk_raw_2] -group [get_clocks rxoutclk_raw]
set_clock_groups -asynchronous -group [get_clocks rxoutclk_raw] -group [get_clocks txoutclk_raw_2]
set_clock_groups -asynchronous -group [get_clocks clk_156m25_p] -group [get_clocks txoutclk_raw_3]
set_clock_groups -asynchronous -group [get_clocks clk_156m25_p] -group [get_clocks txoutclk_raw_4]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_156m25]

set_clock_groups -asynchronous -group [get_clocks txoutclk_raw_2] -group [get_clocks clk_156m25_out_raw]
set_clock_groups -asynchronous -group [get_clocks txoutclk_raw_3] -group [get_clocks clk_156m25_out_raw]
set_clock_groups -asynchronous -group [get_clocks txoutclk_raw_4] -group [get_clocks clk_156m25_out_raw]
set_clock_groups -asynchronous -group [get_clocks clk_156m25_out_raw] -group [get_clocks txoutclk_raw_2]
set_clock_groups -asynchronous -group [get_clocks clk_156m25_out_raw] -group [get_clocks txoutclk_raw_3]
set_clock_groups -asynchronous -group [get_clocks clk_156m25_out_raw] -group [get_clocks txoutclk_raw_4]
