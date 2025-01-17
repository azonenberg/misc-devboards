set_property PACKAGE_PIN C18 [get_ports clk_156m25_p]
set_property IOSTANDARD LVDS [get_ports clk_156m25_p]
set_property IOSTANDARD LVDS [get_ports clk_156m25_n]
set_property PACKAGE_PIN A24 [get_ports gpio_p]
create_clock -period 6.400 -name clk_156m25_p -waveform {0.000 3.200} [get_ports clk_156m25_p]

set_property PACKAGE_PIN V7 [get_ports refclk_p]
create_clock -period 6.400 -name refclk_p -waveform {0.000 3.200} [get_ports refclk_p]
