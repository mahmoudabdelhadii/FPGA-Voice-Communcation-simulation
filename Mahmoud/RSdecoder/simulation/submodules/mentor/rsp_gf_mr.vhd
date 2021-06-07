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
--***   RSP_GF_MR                                 ***
--***                                             ***
--***   Function: Galois Field Reduction Matrix   ***
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

ENTITY rsp_gf_mr IS 
GENERIC (
         polynomial : positive := 285;
         m_bits : positive := 8
        );
PORT (
      aa : IN STD_LOGIC_VECTOR (2*m_bits-1 DOWNTO 1);

		  cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
		 );
END rsp_gf_mr;

ARCHITECTURE rtl OF rsp_gf_mr IS

  type reducedtype IS ARRAY (m_bits-1 DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type sumtype IS ARRAY (m_bits DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  signal polynomialvec : STD_LOGIC_VECTOR (m_bits+1 DOWNTO 1);
  signal prereduced, reduced, vector : reducedtype;
  signal sum : sumtype;
  
BEGIN

  polynomialvec <= conv_std_logic_vector (polynomial,m_bits+1);
  
  -- for each bit position outside the field, generate an equivalet field value
  -- these should be constants, so not require seperate logic
  prereduced(1)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
  reduced(1)(m_bits DOWNTO 1) <= polynomialvec (m_bits DOWNTO 1);
  gra: FOR k IN 2 TO m_bits-1 GENERATE
    prereduced(k)(m_bits DOWNTO 1) <= reduced(k-1)(m_bits-1 DOWNTO 1) & '0';
    grb: FOR j IN 1 TO m_bits GENERATE
      reduced(k)(j) <= prereduced(k)(j) XOR (polynomialvec(j) AND reduced(k-1)(m_bits));
    END GENERATE;
  END GENERATE;
  
  -- reduce all bits outside of field back into field
  gva: FOR k IN 1 TO m_bits-1 GENERATE
    gvb: FOR j IN 1 TO m_bits GENERATE
      vector(k)(j) <= reduced(k)(j) AND aa(m_bits+k);
    END GENERATE;
  END GENERATE;
  
  -- add up all vectors
  sum(1)(m_bits DOWNTO 1) <= aa(m_bits DOWNTO 1);
  gsa: FOR k IN 1 TO m_bits-1 GENERATE
    gsb: FOR j IN 1 TO m_bits GENERATE
      sum(k+1)(j) <= sum(k)(j) XOR vector(k)(j);
    END GENERATE;
  END GENERATE;

  cc <= sum(m_bits)(m_bits DOWNTO 1);
     
END rtl;


