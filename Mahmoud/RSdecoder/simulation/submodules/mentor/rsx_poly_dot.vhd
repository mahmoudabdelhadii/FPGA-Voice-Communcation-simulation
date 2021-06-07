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
--***   RSX_POLY_DOT                              ***
--***                                             ***
--***   Function: Galois Field Vector Multiplier  ***
--***   (new 2013 structure)                      ***
--***                                             ***
--***   08/08/13 ML                               ***
--***                                             ***
--***   (c) 2013 Altera Corporation               ***
--***                                             ***
--***   Change History                            ***
--***                                             ***
--***                                             ***
--***                                             ***
--***                                             ***
--***                                             ***
--***************************************************

ENTITY rsx_poly_dot IS 
GENERIC (startpower : positive := 1);
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      symbols : IN symbol_in_syndromevector;
    
      dotproduct : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
         );
END rsx_poly_dot;

ARCHITECTURE rtl OF rsx_poly_dot IS

  type mxmtype IS ARRAY (m_bits DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type consttype IS ARRAY (parallel_symbols_per_channel-1 DOWNTO 1) OF mxmtype;
  type rowtype IS ARRAY (parallel_symbols_per_channel DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  signal polynomial_value : STD_LOGIC_VECTOR (m_bits+1 DOWNTO 1);
  
  signal symbolsff : symbol_in_syndromevector;
  
  signal multvalue : symbol_in_syndromevector;
  
  signal pre_const_value, const_value, pp, column : consttype;
  signal row : rowtype;
  
  signal adder : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal adderff, mulvectorff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
         
BEGIN

  prc_symbol: PROCESS (sysclk,reset)
  BEGIN
  
    IF (reset = '1') THEN
    
      FOR k IN 1 TO parallel_symbols_per_channel LOOP
        symbolsff(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      END LOOP;
        
    ELSIF (rising_edge(sysclk)) THEN
      
      IF (enable = '1') THEN
        FOR k IN 1 TO parallel_symbols_per_channel LOOP
          symbolsff(k)(m_bits DOWNTO 1) <= symbols(k)(m_bits DOWNTO 1);
        END LOOP;
      END IF;
      
    END IF;
    
  END PROCESS;
  
  polynomial_value <= conv_std_logic_vector(polynomial,m_bits+1);

  gen_mul_one: FOR k IN 1 TO parallel_symbols_per_channel-1 GENERATE
    multvalue(k)(m_bits DOWNTO 1) <= conv_std_logic_vector(powernum(startpower*(parallel_symbols_per_channel-k) mod field_modulo),m_bits);
  END GENERATE; 
  multvalue(parallel_symbols_per_channel)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
     
  gen_const_one: FOR j IN 1 TO parallel_symbols_per_channel-1 GENERATE
    const_value(j)(1)(m_bits DOWNTO 1) <= multvalue(j)(m_bits DOWNTO 1);
    gen_const_two: FOR k IN 2 TO m_bits GENERATE
       pre_const_value(j)(k)(m_bits DOWNTO 1) <= const_value(j)(k-1)(m_bits-1 DOWNTO 1) & '0';
       gen_const_thr: FOR m IN 1 TO m_bits GENERATE
          const_value(j)(k)(m) <= pre_const_value(j)(k)(m) XOR (polynomial_value(m) AND const_value(j)(k-1)(m_bits));
       END GENERATE;    
     END GENERATE;
  END GENERATE;
  
  gen_pp_one: FOR j IN 1 TO parallel_symbols_per_channel-1 GENERATE
    gen_pp_two: FOR k IN 1 TO m_bits GENERATE
       gen_pp_thr: FOR m IN 1 TO m_bits GENERATE
          pp(j)(k)(m) <= const_value(j)(k)(m) AND symbolsff(j)(k);
       END GENERATE;    
     END GENERATE;
  END GENERATE;
  
  -- add all columns
  gen_col_one: FOR j IN 1 TO parallel_symbols_per_channel-1 GENERATE
    column(j)(1)(m_bits DOWNTO 1) <= pp(j)(1)(m_bits DOWNTO 1);
    gen_col_two: FOR k IN 2 TO m_bits GENERATE
       gen_col_thr: FOR m IN 1 TO m_bits GENERATE
          column(j)(k)(m) <= column(j)(k-1)(m) XOR pp(j)(k)(m);
       END GENERATE;    
     END GENERATE;
  END GENERATE;
  
  -- add all rows
  row(1)(m_bits DOWNTO 1) <= column(1)(m_bits)(m_bits DOWNTO 1);
  gen_row_one: FOR j IN 2 TO parallel_symbols_per_channel-1 GENERATE
    gen_row_two: FOR k IN 1 TO m_bits GENERATE
       row(j)(k) <= row(j-1)(k) XOR column(j)(m_bits)(k);
     END GENERATE;
  END GENERATE;

  gen_adder: FOR m IN 1 TO m_bits GENERATE
    adder(m) <= row(parallel_symbols_per_channel-1)(m) XOR symbolsff(parallel_symbols_per_channel)(m);
  END GENERATE;
    
  prc_addvec: PROCESS (sysclk,reset)
  BEGIN
  
    IF (reset = '1') THEN
    
      adderff <= conv_std_logic_vector (0,m_bits);
      mulvectorff <= conv_std_logic_vector (0,m_bits);
        
    ELSIF (rising_edge(sysclk)) THEN
      
      IF (enable = '1') THEN
        adderff <= adder;
        mulvectorff <= adderff;
      END IF;
      
    END IF;
    
  END PROCESS;
  
  dotproduct <= adderff;

 END rtl;
 
 