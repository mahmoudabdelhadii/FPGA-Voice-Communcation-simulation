set_global_assignment -entity "RSencoder" -library "lib_RSencoder" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "RSencoder" -library "lib_RSencoder" -name IP_TOOL_VERSION "16.1"
set_global_assignment -entity "RSencoder" -library "lib_RSencoder" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_RSencoder" -name SPD_FILE [file join $::quartus(sip_path) "../RSencoder.spd"]
set_global_assignment -library "lib_RSencoder" -name MISC_FILE [file join $::quartus(sip_path) "../../RSencoder.qsys"]

set_global_assignment -library "lib_RSencoder" -name MISC_FILE [file join $::quartus(sip_path) "RSencoder.v"]
set_global_assignment -library "lib_RSencoder" -name MISC_FILE [file join $::quartus(sip_path) "submodules/RSencoder_highspeed_rs_0.v"]
set_global_assignment -library "lib_RSencoder" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_highspeed_rs_enc_lagr_pkg.sv"]
set_global_assignment -library "lib_RSencoder" -name MISC_FILE [file join $::quartus(sip_path) "submodules/mentor/altera_highspeed_rs_enc_pkg.sv"]
set_global_assignment -library "lib_RSencoder" -name MISC_FILE [file join $::quartus(sip_path) "submodules/aldec/altera_highspeed_rs_enc_pkg.sv"]
set_global_assignment -library "lib_RSencoder" -name MISC_FILE [file join $::quartus(sip_path) "submodules/mentor/altera_highspeed_rs_enc.sv"]
set_global_assignment -library "lib_RSencoder" -name MISC_FILE [file join $::quartus(sip_path) "submodules/aldec/altera_highspeed_rs_enc.sv"]
set_global_assignment -library "lib_RSencoder" -name MISC_FILE [file join $::quartus(sip_path) "submodules/mentor/altera_highspeed_rs_enc_syndrome.sv"]
set_global_assignment -library "lib_RSencoder" -name MISC_FILE [file join $::quartus(sip_path) "submodules/aldec/altera_highspeed_rs_enc_syndrome.sv"]
set_global_assignment -library "lib_RSencoder" -name MISC_FILE [file join $::quartus(sip_path) "submodules/mentor/altera_highspeed_rs_enc_interpolation.sv"]
set_global_assignment -library "lib_RSencoder" -name MISC_FILE [file join $::quartus(sip_path) "submodules/aldec/altera_highspeed_rs_enc_interpolation.sv"]
