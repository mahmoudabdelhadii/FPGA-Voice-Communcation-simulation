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
USE work.rsx_package.all;
USE work.rsx_roots.all;

--***************************************************
--***                                             ***
--***   ALTERA REED SOLOMON LIBRARY               ***
--***                                             ***
--***   RSX_GF_INV                                ***
--***                                             ***
--***   Function: Galois Field Inverses Table     ***
--***                                             ***
--***   01/03/10 ML                               ***
--***                                             ***
--***   (c) 2010 Altera Corporation               ***
--***                                             ***
--***   Change History                            ***
--***                                             ***
--***                                             ***
--***                                             ***
--***                                             ***
--***                                             ***
--***************************************************

ENTITY rsx_gf_inv IS  
PORT (
      aa : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

		  cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
		 );
END rsx_gf_inv;

ARCHITECTURE rtl OF rsx_gf_inv IS

BEGIN
    
  cc <= conv_std_logic_vector(inverses(conv_integer(aa)),m_bits);
  
END rtl;

