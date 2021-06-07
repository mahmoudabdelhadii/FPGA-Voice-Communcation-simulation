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



LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all; 

USE work.rsx_parameters.all;

ENTITY rsx_fit_counter IS 
GENERIC (
         minus_one : integer := 142 -- alpha**-1
        );
PORT (
      sysclk, reset : IN STD_LOGIC;
      address, data : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
		 );
END rsx_fit_counter;

ARCHITECTURE rtl OF rsx_fit_counter IS
 
  signal addressff, dataff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal next_address, next_data : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal one, negone : STD_LOGIC_VECTOR (m_bits DOWNTO 1);

component rsp_gf_mulx
GENERIC (
         polynomial : positive := 285;
         m_bits : positive := 8
        );
PORT (
      aa, bb : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

      cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
		 );
end component;
  
BEGIN
    
prc_cnt: PROCESS (sysclk,reset)
BEGIN
  IF (reset = '1') THEN
    addressff <= one;
    dataff <= negone;
  ELSIF (rising_edge(sysclk)) THEN
    addressff <= next_address;
    dataff <= next_data;
  END IF;
END PROCESS;

  --one <= conv_std_logic_vector (2,m_bits);
  --negone <= conv_std_logic_vector (minus_one,m_bits);

  comp_gfm_one: rsp_gf_mulx
  GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  PORT MAP (aa=>addressff,bb=>conv_std_logic_vector (2,m_bits),--one,
            cc=>next_address);

  comp_gfm_two: rsp_gf_mulx
  GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  PORT MAP (aa=>dataff,bb=>conv_std_logic_vector (minus_one,m_bits),--negone
            cc=>next_data);

address <= addressff;
data <= dataff;

END rtl;


