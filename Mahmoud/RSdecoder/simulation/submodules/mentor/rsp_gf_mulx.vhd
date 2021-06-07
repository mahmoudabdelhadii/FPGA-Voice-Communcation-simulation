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

ENTITY rsp_gf_mulx IS 
GENERIC (
         polynomial : positive := 285;
         m_bits : positive := 8
        );
PORT (
      aa, bb : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

      cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
		 );
END rsp_gf_mulx;

ARCHITECTURE rtl OF rsp_gf_mulx IS

  type matrixtype IS ARRAY (m_bits DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
 
  signal polynomial_value : STD_LOGIC_VECTOR (m_bits+1 DOWNTO 1);
  signal pre_const_value, const_value : matrixtype;
  signal pp, column : matrixtype;
  
BEGIN
    
  polynomial_value <= conv_std_logic_vector (polynomial,m_bits+1);

  const_value(1)(m_bits DOWNTO 1) <= bb(m_bits DOWNTO 1);
  gen_const_one: FOR k IN 2 TO m_bits GENERATE
  pre_const_value(k)(m_bits DOWNTO 1) <= const_value(k-1)(m_bits-1 DOWNTO 1) & '0';
    gen_const_two: FOR m IN 1 TO m_bits GENERATE
      const_value(k)(m) <= pre_const_value(k)(m) XOR (polynomial_value(m) AND const_value(k-1)(m_bits));
    END GENERATE;	
  END GENERATE;
  
  gen_pp_one: FOR k IN 1 TO m_bits GENERATE
    gen_pp_two: FOR m IN 1 TO m_bits GENERATE
      pp(k)(m) <= const_value(k)(m) AND aa(k);
    END GENERATE;
  END GENERATE;
  
  column(1)(m_bits DOWNTO 1) <= pp(1)(m_bits DOWNTO 1);
  gen_col_one: FOR k IN 2 TO m_bits GENERATE
    gen_col_two: FOR m IN 1 TO m_bits GENERATE
      column(k)(m) <= column(k-1)(m) XOR pp(k)(m);
    END GENERATE;
  END GENERATE;
  
  gen_out: FOR m IN 1 TO m_bits GENERATE
    cc(m) <= column(m_bits)(m);
  END GENERATE;

END rtl;


