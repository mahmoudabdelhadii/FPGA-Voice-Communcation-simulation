set_global_assignment -entity "BCH_204_128_10_enc" -library "lib_BCH_204_128_10_enc" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "BCH_204_128_10_enc" -library "lib_BCH_204_128_10_enc" -name IP_TOOL_VERSION "16.1"
set_global_assignment -entity "BCH_204_128_10_enc" -library "lib_BCH_204_128_10_enc" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_BCH_204_128_10_enc" -name SPD_FILE [file join $::quartus(sip_path) "../BCH_204_128_10_enc.spd"]
set_global_assignment -library "lib_BCH_204_128_10_enc" -name MISC_FILE [file join $::quartus(sip_path) "../../BCH_204_128_10_enc.qsys"]

set_global_assignment -library "lib_BCH_204_128_10_enc" -name MISC_FILE [file join $::quartus(sip_path) "BCH_204_128_10_enc.v"]
set_global_assignment -library "lib_BCH_204_128_10_enc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/bch_enc_package.vhd"]
set_global_assignment -library "lib_BCH_204_128_10_enc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/mentor/bch_encoder_core.vhd"]
set_global_assignment -library "lib_BCH_204_128_10_enc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/aldec/bch_encoder_core.vhd"]
set_global_assignment -library "lib_BCH_204_128_10_enc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/mentor/bch_encoder.vhd"]
set_global_assignment -library "lib_BCH_204_128_10_enc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/aldec/bch_encoder.vhd"]
set_global_assignment -library "lib_BCH_204_128_10_enc" -name MISC_FILE [file join $::quartus(sip_path) "submodules/top_enc.vhd"]
