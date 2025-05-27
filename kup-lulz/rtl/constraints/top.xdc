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

set_property IOSTANDARD LVCMOS33 [get_ports sfp0_rx_los]
set_property PACKAGE_PIN F14 [get_ports sfp0_rx_los]

set_property IOSTANDARD LVCMOS33 [get_ports qsfp0_i2c_scl]
set_property IOSTANDARD LVCMOS33 [get_ports qsfp0_i2c_sda]
set_property IOSTANDARD LVCMOS33 [get_ports qsfp0_i2c_sel_n]
set_property IOSTANDARD LVCMOS33 [get_ports qsfp0_int_n]
set_property IOSTANDARD LVCMOS33 [get_ports qsfp0_lpmode]
set_property IOSTANDARD LVCMOS33 [get_ports qsfp0_present_n]
set_property IOSTANDARD LVCMOS33 [get_ports qsfp0_rst_n]
set_property PACKAGE_PIN B9 [get_ports qsfp0_i2c_scl]
set_property PACKAGE_PIN A9 [get_ports qsfp0_i2c_sda]
set_property PACKAGE_PIN E12 [get_ports qsfp0_i2c_sel_n]
set_property PACKAGE_PIN B10 [get_ports qsfp0_int_n]
set_property PACKAGE_PIN C12 [get_ports qsfp0_lpmode]
set_property PACKAGE_PIN A10 [get_ports qsfp0_present_n]
set_property PACKAGE_PIN F12 [get_ports qsfp0_rst_n]

set_property PACKAGE_PIN H7 [get_ports refclk2_p]

set_property PACKAGE_PIN C4 [get_ports qsfp0_lane1_rx_p]
set_property PACKAGE_PIN B2 [get_ports qsfp0_lane2_rx_p]
set_property PACKAGE_PIN A4 [get_ports qsfp0_lane3_rx_p]

########################################################################################################################
# Clocks

create_clock -period 6.400 -name clk_156m25_p -waveform {0.000 3.200} [get_ports clk_156m25_p]
create_clock -period 6.400 -name refclk_p -waveform {0.000 3.200} [get_ports refclk_p]
create_clock -period 6.400 -name refclk2_p -waveform {0.000 3.200} [get_ports refclk2_p]

create_generated_clock -name sccb_apb_rxclk -source [get_pins sfp_quad_225/artix_bridge/lane/channel/QPLL1CLK] -master_clock [get_clocks {qpll_clkout[1]_1}] [get_pins sfp_quad_225/artix_bridge/lane/channel/RXOUTCLK]
create_generated_clock -name sccb_apb_txclk -source [get_pins sfp_quad_225/artix_bridge/lane/channel/QPLL1CLK] -master_clock [get_clocks {qpll_clkout[1]_1}] [get_pins sfp_quad_225/artix_bridge/lane/channel/TXOUTCLK]
create_generated_clock -name clk_fabric -source [get_pins clocks/pll/CLKIN1] -master_clock [get_clocks clk_156m25_p] [get_pins clocks/pll/CLKOUT0]
create_generated_clock -name clk_156m25 -source [get_pins clocks/pll/CLKIN1] -master_clock [get_clocks clk_156m25_p] [get_pins clocks/pll/CLKOUT1]
create_generated_clock -name phy1_lane0_rxclk -source [get_pins {qsfp_quad_227/serdes[1].lane/channel/QPLL1CLK}] -master_clock [get_clocks {qpll_clkout[1]}] [get_pins {qsfp_quad_227/serdes[1].lane/channel/RXOUTCLK}]
create_generated_clock -name phy1_lane0_txclk -source [get_pins {qsfp_quad_227/serdes[1].lane/channel/QPLL1CLK}] -master_clock [get_clocks {qpll_clkout[1]}] [get_pins {qsfp_quad_227/serdes[1].lane/channel/TXOUTCLK}]
create_generated_clock -name phy1_lane1_rxclk -source [get_pins {qsfp_quad_227/serdes[2].lane/channel/QPLL1CLK}] -master_clock [get_clocks {qpll_clkout[1]}] [get_pins {qsfp_quad_227/serdes[2].lane/channel/RXOUTCLK}]
create_generated_clock -name phy1_lane1_txclk -source [get_pins {qsfp_quad_227/serdes[2].lane/channel/QPLL1CLK}] -master_clock [get_clocks {qpll_clkout[1]}] [get_pins {qsfp_quad_227/serdes[2].lane/channel/TXOUTCLK}]
create_generated_clock -name phy1_lane2_rxclk -source [get_pins {qsfp_quad_227/serdes[3].lane/channel/QPLL1CLK}] -master_clock [get_clocks {qpll_clkout[1]}] [get_pins {qsfp_quad_227/serdes[3].lane/channel/RXOUTCLK}]
create_generated_clock -name phy1_lane2_txclk -source [get_pins {qsfp_quad_227/serdes[3].lane/channel/QPLL1CLK}] -master_clock [get_clocks {qpll_clkout[1]}] [get_pins {qsfp_quad_227/serdes[3].lane/channel/TXOUTCLK}]
create_generated_clock -name mgmt_xg_rxclk -source [get_pins sfp_quad_225/xg_mgmt/serdes/channel/QPLL0CLK] -master_clock [get_clocks {qpll_clkout[0]_1}] [get_pins sfp_quad_225/xg_mgmt/serdes/channel/RXOUTCLK]
create_generated_clock -name mgmt_xg_txclk -source [get_pins sfp_quad_225/xg_mgmt/serdes/channel/QPLL0CLK] -master_clock [get_clocks {qpll_clkout[0]_1}] [get_pins sfp_quad_225/xg_mgmt/serdes/channel/TXOUTCLK]
create_generated_clock -name phy0_lane0_rxclk -source [get_pins {smpm_quad_224/lanes[0].lane/channel/QPLL1CLK}] -master_clock [get_clocks {qpll_clkout[1]_2}] [get_pins {smpm_quad_224/lanes[0].lane/channel/RXOUTCLK}]
create_generated_clock -name phy0_lane0_txclk -source [get_pins {smpm_quad_224/lanes[0].lane/channel/QPLL1CLK}] -master_clock [get_clocks {qpll_clkout[1]_2}] [get_pins {smpm_quad_224/lanes[0].lane/channel/TXOUTCLK}]
create_generated_clock -name phy0_lane1_rxclk -source [get_pins {smpm_quad_224/lanes[1].lane/channel/QPLL1CLK}] -master_clock [get_clocks {qpll_clkout[1]_2}] [get_pins {smpm_quad_224/lanes[1].lane/channel/RXOUTCLK}]
create_generated_clock -name phy0_lane1_txclk -source [get_pins {smpm_quad_224/lanes[1].lane/channel/QPLL1CLK}] -master_clock [get_clocks {qpll_clkout[1]_2}] [get_pins {smpm_quad_224/lanes[1].lane/channel/TXOUTCLK}]
create_generated_clock -name phy0_lane2_rxclk -source [get_pins {smpm_quad_224/lanes[2].lane/channel/QPLL1CLK}] -master_clock [get_clocks {qpll_clkout[1]_2}] [get_pins {smpm_quad_224/lanes[2].lane/channel/RXOUTCLK}]
create_generated_clock -name phy0_lane2_txclk -source [get_pins {smpm_quad_224/lanes[2].lane/channel/QPLL1CLK}] -master_clock [get_clocks {qpll_clkout[1]_2}] [get_pins {smpm_quad_224/lanes[2].lane/channel/TXOUTCLK}]

########################################################################################################################
# CDC constraints

set _xlnx_shared_i0 [get_cells -hierarchical -filter { NAME =~  "*sync*" && NAME =~  "*reg_a_ff*" }]
set _xlnx_shared_i1 [get_cells -hierarchical -filter { NAME =~  "*sync*" && NAME =~  "*reg_b*" }]
set _xlnx_shared_i2 [get_cells -hierarchical -filter { NAME =~  "*sync*" && NAME =~  "*tx_a_reg*" }]
set _xlnx_shared_i3 [get_cells -hierarchical -filter { NAME =~  "*sync*" && NAME =~  "*dout1_reg*" }]
set _xlnx_shared_i4 [get_cells -hierarchical -filter { NAME =~  "*sync*" && NAME =~  "*a_ff*" }]
set _xlnx_shared_i5 [get_cells -hierarchical -filter { NAME =~  "*sync*" && NAME =~  "*dout0_reg*" }]

set_max_delay -datapath_only -from $_xlnx_shared_i0 -to $_xlnx_shared_i1 2.500
set_bus_skew -from $_xlnx_shared_i0 -to $_xlnx_shared_i1 2.500

set_max_delay -datapath_only -from $_xlnx_shared_i2 -to $_xlnx_shared_i3 2.500
set_bus_skew -from $_xlnx_shared_i2 -to $_xlnx_shared_i3 2.500

set_max_delay -datapath_only -from $_xlnx_shared_i5 -to $_xlnx_shared_i3 2.500
set_bus_skew -from $_xlnx_shared_i5 -to $_xlnx_shared_i3 2.500

set_max_delay -datapath_only -from $_xlnx_shared_i4 -to $_xlnx_shared_i1 2.500
set_bus_skew -from $_xlnx_shared_i4 -to $_xlnx_shared_i1 2.500

set_max_delay -datapath_only -from $_xlnx_shared_i5 -to $_xlnx_shared_i3 2.500
set_bus_skew -from $_xlnx_shared_i5 -to $_xlnx_shared_i3 2.500

# this is a LUTRAM driving a fabric flop, false path from write to read
set _xlnx_shared_i6 [get_cells -hierarchical -filter { NAME =~  "*fifomem*" }]
set_false_path -from [get_clocks sccb_apb_rxclk] -through $_xlnx_shared_i6 -to [get_clocks mgmt_xg_txclk]

########################################################################################################################
# Put the timestamp in the bitstream USERCODE

set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]

########################################################################################################################
# Debugging

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_156m25]
