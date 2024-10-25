
# General
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]

# HDMI
set_property IOSTANDARD TMDS_33 [get_ports hdmi_tx_clk_p]
set_property PACKAGE_PIN R7 [get_ports hdmi_tx_clk_p]

set_property IOSTANDARD TMDS_33 [get_ports {hdmi_tx_d_p[*]}]
set_property PACKAGE_PIN P8 [get_ports {hdmi_tx_d_p[0]}]
set_property PACKAGE_PIN P10 [get_ports {hdmi_tx_d_p[1]}]
set_property PACKAGE_PIN P11 [get_ports {hdmi_tx_d_p[2]}]
