set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

set_property IOSTANDARD LVCMOS33 [get_ports *]
set_property PACKAGE_PIN N14 [get_ports clk32]

# ~32.768 MHz
create_clock -period 30.518 -name clk32 [get_ports clk32]

set_property PACKAGE_PIN F15 [get_ports {led[0]}]
set_property PACKAGE_PIN E16 [get_ports {led[1]}]
set_property PACKAGE_PIN C14 [get_ports {led[2]}]
set_property PACKAGE_PIN B14 [get_ports {led[3]}]
set_property PACKAGE_PIN B9 [get_ports {led[4]}]
set_property PACKAGE_PIN A7 [get_ports {led[5]}]
set_property PACKAGE_PIN B4 [get_ports {led[6]}]
set_property PACKAGE_PIN D1 [get_ports {led[7]}]

set_property PACKAGE_PIN T15 [get_ports {btn}]
