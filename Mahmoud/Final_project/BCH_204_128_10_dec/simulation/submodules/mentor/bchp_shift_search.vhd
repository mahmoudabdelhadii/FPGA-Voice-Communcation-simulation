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

USE work.bchp_parameters.all;
USE work.bchp_package.all;
USE work.bchp_roots.all;

--***************************************************
--***                                             ***
--***   ALTERA BCH LIBRARY                        ***
--***                                             ***
--***   BCHP_SHIFT_SEARCH                         ***
--***                                             ***
--***   Function: One Chien Search - shift from   ***
--***   base level polynomial values              ***
--***                                             ***
--***   26/06/13 ML                               ***
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

ENTITY bchp_shift_search IS 
GENERIC (shiftindex : integer := 27);
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      error_base : IN errorvector; -- error locator polynomial, shifted for first index
      
      error_found : OUT STD_LOGIC
		 );
END bchp_shift_search;

ARCHITECTURE rtl OF bchp_shift_search IS

  type addertype IS ARRAY (adder_elements DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type lastaddertype IS ARRAY (last_adder_elements DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  type mxmtype IS ARRAY (m_bits DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type consttype IS ARRAY (t_symbols DOWNTO 1) OF mxmtype;

  signal polynomial_value : STD_LOGIC_VECTOR (m_bits+1 DOWNTO 1);
  
  signal error_baseff : errorvector;
  signal sumff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal errorfoundff : STD_LOGIC_VECTOR (2 DOWNTO 1);
  
  signal bb_shiftsearch : errorvector;

  signal pre_const_value, const_value, pp, column : consttype;
  signal rowone, rowtwo, rowthr, rowfor, rowfiv : addertype;
  signal rowsix : lastaddertype;
  signal rowoneff, rowtwoff, rowthrff, rowforff, rowfivff, rowsixff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal sumzero : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal errorfound : STD_LOGIC;

BEGIN
  
-- 01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24  -- search base+1 for t=24 powers
-- 02,04,06,08,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46,48  -- search base+2 for t=24 powers
-- 03,06,09,12,15,18,21,24,27,30,33,36,39,42,45,48,51,54,57,60,63,66,69,72  -- search base+3 for t=24 powers
-- 04,08,12,16,20,24,28,32,36,40,44,48,52,56,60,64,68,72,76,80,84,88,92,96  -- search base+4 for t=24 powers

  polynomial_value <= conv_std_logic_vector(polynomial,m_bits+1);
  
  gen_coeff: FOR k IN 1 TO t_symbols GENERATE
    
    bb_shiftsearch(k)(m_bits DOWNTO 1) <= conv_std_logic_vector(powernum(k*shiftindex mod field_index),m_bits);

  END GENERATE;
  
  gen_const_one: FOR j IN 1 TO t_symbols GENERATE
    const_value(j)(1)(m_bits DOWNTO 1) <= bb_shiftsearch(j)(m_bits DOWNTO 1);
    gen_const_two: FOR k IN 2 TO m_bits GENERATE
	   pre_const_value(j)(k)(m_bits DOWNTO 1) <= const_value(j)(k-1)(m_bits-1 DOWNTO 1) & '0';
	   gen_const_thr: FOR m IN 1 TO m_bits GENERATE
		  const_value(j)(k)(m) <= pre_const_value(j)(k)(m) XOR (polynomial_value(m) AND const_value(j)(k-1)(m_bits));
	   END GENERATE;	
	 END GENERATE;
  END GENERATE;
  
  gen_pp_one: FOR j IN 1 TO t_symbols GENERATE
    gen_pp_two: FOR k IN 1 TO m_bits GENERATE
	   gen_pp_thr: FOR m IN 1 TO m_bits GENERATE
		  pp(j)(k)(m) <= const_value(j)(k)(m) AND error_baseff(j)(k);
	   END GENERATE;	
	 END GENERATE;
  END GENERATE;
  
  -- add all columns
  gen_col_one: FOR j IN 1 TO t_symbols GENERATE
    column(j)(1)(m_bits DOWNTO 1) <= pp(j)(1)(m_bits DOWNTO 1);
    gen_col_two: FOR k IN 2 TO m_bits GENERATE
	   gen_col_thr: FOR m IN 1 TO m_bits GENERATE
		  column(j)(k)(m) <= column(j)(k-1)(m) XOR pp(j)(k)(m);
	   END GENERATE;	
	 END GENERATE;
  END GENERATE;
  
  -- add all rows
  rowone(1)(m_bits DOWNTO 1) <= column(1)(m_bits)(m_bits DOWNTO 1);
  gen_row_one_one_gate: IF adder_elements > 1 GENERATE
  gen_row_one_one: FOR j IN 2 TO adder_elements GENERATE
    gen_col_one_two: FOR k IN 1 TO m_bits GENERATE
	   rowone(j)(k) <= rowone(j-1)(k) XOR column(j)(m_bits)(k);
	 END GENERATE;
  END GENERATE;
  END GENERATE;
  
  rowtwo(1)(m_bits DOWNTO 1) <= column(adder_elements+1)(m_bits)(m_bits DOWNTO 1);
  gen_row_two_one_gate: IF adder_elements > 1 GENERATE
  gen_row_two_one: FOR j IN 2 TO adder_elements GENERATE
    gen_col_two_two: FOR k IN 1 TO m_bits GENERATE
	   rowtwo(j)(k) <= rowtwo(j-1)(k) XOR column(adder_elements+j)(m_bits)(k);
	 END GENERATE;
  END GENERATE;
  END GENERATE;
  
  rowthr(1)(m_bits DOWNTO 1) <= column(2*adder_elements+1)(m_bits)(m_bits DOWNTO 1);
  gen_row_thr_one_gate: IF adder_elements > 1 GENERATE
  gen_row_thr_one: FOR j IN 2 TO adder_elements GENERATE
    gen_col_thr_two: FOR k IN 1 TO m_bits GENERATE
	   rowthr(j)(k) <= rowthr(j-1)(k) XOR column(2*adder_elements+j)(m_bits)(k);
	 END GENERATE;
  END GENERATE;
  END GENERATE;
  
  rowfor(1)(m_bits DOWNTO 1) <= column(3*adder_elements+1)(m_bits)(m_bits DOWNTO 1);
  gen_row_for_one_gate: IF adder_elements > 1 GENERATE
  gen_row_for_one: FOR j IN 2 TO adder_elements GENERATE
    gen_col_for_two: FOR k IN 1 TO m_bits GENERATE
	   rowfor(j)(k) <= rowfor(j-1)(k) XOR column(3*adder_elements+j)(m_bits)(k);
	 END GENERATE;
  END GENERATE;
  END GENERATE;
  
  rowfiv(1)(m_bits DOWNTO 1) <= column(4*adder_elements+1)(m_bits)(m_bits DOWNTO 1);
  gen_row_fiv_one_gate: IF adder_elements > 1 GENERATE
  gen_row_fiv_one: FOR j IN 2 TO adder_elements GENERATE
    gen_col_fiv_two: FOR k IN 1 TO m_bits GENERATE
	   rowfiv(j)(k) <= rowfiv(j-1)(k) XOR column(4*adder_elements+j)(m_bits)(k);
	 END GENERATE;
  END GENERATE;
  END GENERATE;
  
  rowsix(1)(m_bits DOWNTO 1) <= column(5*adder_elements+1)(m_bits)(m_bits DOWNTO 1);
  gen_row_six_one_gate: IF last_adder_elements > 1 GENERATE
  gen_row_six_one: FOR j IN 2 TO last_adder_elements GENERATE
    gen_col_six_two: FOR k IN 1 TO m_bits GENERATE
	   rowsix(j)(k) <= rowsix(j-1)(k) XOR column(5*adder_elements+j)(m_bits)(k);
	 END GENERATE;
  END GENERATE;
  END GENERATE;
  
  prc_main: PROCESS (sysclk)
  BEGIN
    
    
		
    IF (rising_edge(sysclk)) THEN

      IF (reset = '1') THEN

      FOR j IN 1 TO t_symbols LOOP
        FOR k IN 1 TO m_bits LOOP
          error_baseff(j)(k) <= '0';
        END LOOP;
      END LOOP;
      rowoneff <= conv_std_logic_vector (0,m_bits);
      rowtwoff <= conv_std_logic_vector (0,m_bits);
      rowthrff <= conv_std_logic_vector (0,m_bits);
      rowforff <= conv_std_logic_vector (0,m_bits);
      rowfivff <= conv_std_logic_vector (0,m_bits);
      rowsixff <= conv_std_logic_vector (0,m_bits);
      sumff <= conv_std_logic_vector (0,m_bits);
      errorfoundff <= "00";
     
      ELSIF (enable = '1') THEN
       
		  FOR j IN 1 TO t_symbols LOOP
          FOR k IN 1 TO m_bits LOOP
            error_baseff(j)(k) <= error_base(j)(k);
          END LOOP;
        END LOOP;
		    
		  rowoneff <= rowone(adder_elements)(m_bits DOWNTO 1);
		  rowtwoff <= rowtwo(adder_elements)(m_bits DOWNTO 1);
		  rowthrff <= rowthr(adder_elements)(m_bits DOWNTO 1);
		  rowforff <= rowfor(adder_elements)(m_bits DOWNTO 1);
		  rowfivff <= rowfiv(adder_elements)(m_bits DOWNTO 1);
		  rowsixff <= rowsix(last_adder_elements)(m_bits DOWNTO 1);
		  
		  FOR m IN 1 TO m_bits LOOP 
		    sumff(m) <= rowoneff(m) XOR rowtwoff(m) XOR rowthrff(m) XOR 
		                rowforff(m) XOR rowfivff(m) XOR rowsixff(m);
		  END LOOP;
        
        errorfoundff(1) <= errorfound;
        errorfoundff(2) <= errorfoundff(1);
        
      END IF;
      
    END IF;
    
  END PROCESS;
  
    -- = adder + 1
  sumzero(1) <= NOT(sumff(1));
  gen_sum_zero: FOR k IN 2 TO m_bits GENERATE
    sumzero(k) <= sumzero(k-1) OR sumff(k);
  END GENERATE;
  errorfound <= NOT(sumzero(m_bits));
  
  error_found <= errorfoundff(2);
  
END rtl;

