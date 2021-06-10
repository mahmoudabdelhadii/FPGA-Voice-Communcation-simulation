set_global_assignment -entity "carrier_freq" -library "lib_carrier_freq" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "carrier_freq" -library "lib_carrier_freq" -name IP_TOOL_VERSION "16.1"
set_global_assignment -entity "carrier_freq" -library "lib_carrier_freq" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_carrier_freq" -name SPD_FILE [file join $::quartus(sip_path) "carrier_freq.spd"]

set_global_assignment -library "lib_carrier_freq" -name MISC_FILE [file join $::quartus(sip_path) "carrier_freq_sim/carrier_freq.vo"]
