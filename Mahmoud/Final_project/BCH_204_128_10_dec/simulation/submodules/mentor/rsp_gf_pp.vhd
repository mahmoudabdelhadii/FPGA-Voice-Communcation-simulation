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
--***   RSP_GF_PP                                 ***
--***                                             ***
--***   Function: Galois Field Partial Product    ***
--***   Generator                                 ***
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

ENTITY rsp_gf_pp IS 
GENERIC (m_bits : positive := 8);
PORT (
      aa, bb : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

		  cc : OUT STD_LOGIC_VECTOR (2*m_bits-1 DOWNTO 1)
		 );
END rsp_gf_pp;

ARCHITECTURE rtl OF rsp_gf_pp IS

  type vectype IS ARRAY (m_bits DOWNTO 1) OF STD_LOGIC_VECTOR (2*m_bits-1 DOWNTO 1);

  signal vec, sum : vectype;
  
BEGIN
 
  gaa: FOR k IN 1 TO m_bits GENERATE
    vec(1)(k) <= aa(k) AND bb(1);
  END GENERATE;
  gab: FOR k IN m_bits+1 TO 2*m_bits-1 GENERATE
    vec(1)(k) <= '0';
  END GENERATE;
 
  gba: FOR k IN 2 TO m_bits-1 GENERATE
    gbb: FOR j IN 1 TO k-1 GENERATE
      vec(k)(j) <= '0';
    END GENERATE;
    gbc: FOR j IN 1 TO m_bits GENERATE
      vec(k)(j+k-1) <= aa(j) AND bb(k);
    END GENERATE;
    gbd: FOR j IN m_bits+k TO 2*m_bits-1 GENERATE
      vec(k)(j) <= '0';
    END GENERATE;
  END GENERATE;

  gca: FOR k IN 1 TO m_bits-1 GENERATE
    vec(m_bits)(k) <= '0';
  END GENERATE;
  gcb: FOR k IN m_bits TO 2*m_bits-1 GENERATE
    vec(m_bits)(k) <= aa(k-m_bits+1) AND bb(m_bits);
  END GENERATE;
  
  sum(1)(2*m_bits-1 DOWNTO 1) <= vec(1)(2*m_bits-1 DOWNTO 1);
  gxa: FOR k IN 2 TO m_bits GENERATE
    gxb: FOR j IN 1 TO 2*m_bits-1 GENERATE
      sum(k)(j) <= sum(k-1)(j) XOR vec(k)(j);
    END GENERATE;
  END GENERATE;  

  cc <= sum(m_bits)(2*m_bits-1 DOWNTO 1);
      
END rtl;



