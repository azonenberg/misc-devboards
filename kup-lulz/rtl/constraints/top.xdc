set_property PACKAGE_PIN C18 [get_ports clk_156m25_p]
set_property IOSTANDARD LVDS [get_ports clk_156m25_p]
set_property IOSTANDARD LVDS [get_ports clk_156m25_n]
set_property PACKAGE_PIN A24 [get_ports gpio_p]
create_clock -period 6.400 -name clk_156m25_p -waveform {0.000 3.200} [get_ports clk_156m25_p]

set_property PACKAGE_PIN V7 [get_ports refclk_p]
create_clock -period 6.400 -name refclk_p -waveform {0.000 3.200} [get_ports refclk_p]

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
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_156m25]
