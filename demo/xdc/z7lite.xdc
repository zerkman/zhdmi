# Hardware PL clock @50 MHz
create_clock -period 20.000 [get_ports sys_clk]
set_property PACKAGE_PIN N18 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]

# PL Push buttons
set_property PACKAGE_PIN P16 [get_ports {key[0]}]
set_property PACKAGE_PIN T12 [get_ports {key[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {key[*]}]

# PL LEDs
set_property PACKAGE_PIN P15 [get_ports {led[0]}]
set_property PACKAGE_PIN U12 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

# HDMI
set_property PACKAGE_PIN U18 [get_ports hdmi_tx_clk_p]
set_property PACKAGE_PIN V20 [get_ports {hdmi_tx_d_p[0]}]
set_property PACKAGE_PIN T20 [get_ports {hdmi_tx_d_p[1]}]
set_property PACKAGE_PIN N20 [get_ports {hdmi_tx_d_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_d_p[*]}]
set_property IOSTANDARD TMDS_33 [get_ports hdmi_tx_clk_p]
