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

--***************************************************
--***                                             ***
--***   ALTERA REED SOLOMON LIBRARY               ***
--***                                             ***
--***   RSP_GF_MUL                                ***
--***                                             ***
--***   Function: Galois Field Multiplier         ***
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

ENTITY rsp_gf_mul IS 
GENERIC (
         polynomial : positive := 285;
         m_bits : positive := 8
        );
PORT (
      aa, bb : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

		  cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
		 );
END rsp_gf_mul;

ARCHITECTURE rtl OF rsp_gf_mul IS
 
  signal expand : STD_LOGIC_VECTOR (2*m_bits-1 DOWNTO 1);
  
  component rsp_gf_pp  
  GENERIC (m_bits : positive := 8);
  PORT (
        aa, bb : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

		    cc : OUT STD_LOGIC_VECTOR (2*m_bits-1 DOWNTO 1)
		   );
	end component;
	
  component rsp_gf_mr 
  GENERIC (
           polynomial : positive := 285;
           m_bits : positive := 8
          );
  PORT (
        aa : IN STD_LOGIC_VECTOR (2*m_bits-1 DOWNTO 1);

		    cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
		   );
	end component;
		 
BEGIN
    
  cpp: rsp_gf_pp
  GENERIC MAP (m_bits=>m_bits)
  PORT MAP (aa=>aa,bb=>bb,
            cc=>expand);
  
  crr: rsp_gf_mr
  GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  PORT MAP (aa=>expand,
            cc=>cc);
  
END rtl;


