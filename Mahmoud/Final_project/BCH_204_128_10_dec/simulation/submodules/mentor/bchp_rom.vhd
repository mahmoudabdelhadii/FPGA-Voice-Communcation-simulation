-- (C) 2001-2016 Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions and other 
-- software and tools, and its AMPP partner logic functions, and any output 
-- files any of the foregoing (including device programming or simulation 
-- files), and any associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License Subscription 
-- Agreement, Intel MegaCore Function License Agreement, or other applicable 
-- license agreement, including, without limitation, that your use is for the 
-- sole purpose of programming logic devices manufactured by Intel and sold by 
-- Intel or its authorized distributors.  Please refer to the applicable 
-- agreement for further details.


library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.altera_mf_components.all; 

entity bchp_rom is
  generic
    (
      mem_width : positive := 4
      );
  port
    (
      address : in  std_logic_vector (mem_width-1 downto 0);
      clock   : in  std_logic := '1';
      q       : out std_logic_vector (mem_width-1 downto 0)
      );
end bchp_rom;


architecture SYN of bchp_rom is

  signal sub_wire0 : std_logic_vector (mem_width-1 downto 0);



  component altsyncram
    generic (
      init_file             : string;
      lpm_hint              : string;
      lpm_type              : string;
      numwords_a            : natural;
      operation_mode        : string;
      outdata_aclr_a        : string;
      outdata_reg_a         : string;
      widthad_a             : natural;
      width_a               : natural;
      width_byteena_a       : natural
      );
    port (
      address_a : in  std_logic_vector (mem_width-1 downto 0);
      clock0    : in  std_logic;
      q_a       : out std_logic_vector (mem_width-1 downto 0)
      );
  end component;

begin

  q <= sub_wire0(mem_width-1 downto 0);

  altsyncram_component : altsyncram
    generic map (
      init_file              => "bchp_invmem.hex",
      lpm_hint               => "ENABLE_RUNTIME_MOD=NO",
      lpm_type               => "altsyncram",
      numwords_a             => 2**mem_width,
      operation_mode         => "ROM",
      outdata_aclr_a         => "NONE",
      outdata_reg_a          => "CLOCK0",
      widthad_a              => mem_width,
      width_a                => mem_width,
      width_byteena_a        => 1
      )
    port map (
      address_a => address,
      clock0    => clock,
      q_a       => sub_wire0
      );

end SYN;
