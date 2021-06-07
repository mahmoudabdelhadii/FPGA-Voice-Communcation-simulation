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
--***   Function: Shift Error Locator Polynomials ***
--***   and Evaluator Polynomials and perform     ***
--***   Forney Algorithm                          ***
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

ENTITY rsx_error_dot IS 
GENERIC (shiftindex : integer := 1);
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      zero_error_found : IN STD_LOGIC;
      bd_base : IN errorvector; -- error locator polynomial, shifted for first index
      omega_base : IN errorvector; -- error evaluator polynomial, shifted for first index

      error_found : OUT STD_LOGIC;
      count_this_one : OUT STD_LOGIC;
      get_inv_of : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
      get_inv_of_valid : OUT STD_LOGIC;
      value_of_inv : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);
      error_correct : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
      );
END rsx_error_dot;

ARCHITECTURE rtl OF rsx_error_dot IS

  type mxmtype IS ARRAY (m_bits DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type consttype IS ARRAY (error_symbols DOWNTO 1) OF mxmtype;
  type ppomegatype IS ARRAY (error_symbols-1 DOWNTO 1) OF mxmtype;
  type bdoddtype IS ARRAY (derivative_terms DOWNTO 1) OF mxmtype;
  type bdeventype IS ARRAY (even_terms DOWNTO 1) OF mxmtype;
  type oddrowtype IS ARRAY (derivative_terms DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type evenrowtype IS ARRAY (even_terms DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type omegarowtype IS ARRAY (error_symbols-1 DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type adderomegatype IS ARRAY (3 DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  signal polynomial_value : STD_LOGIC_VECTOR (m_bits+1 DOWNTO 1);
  
  signal bd_baseff, omega_baseff : errorvector;
  signal bd0ff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal adder_bdoddff, adder_bdodddelff, adder_bdevenff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal adder_omegaff : adderomegatype;
  signal errorinverse, correctionff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal errorfoundff : STD_LOGIC_VECTOR (3 DOWNTO 1);
  
  signal bb_shift : errorvector;

  signal pre_const_value, const_value : consttype;
  
  signal ppbd : consttype;
  signal column_bdodd : bdoddtype;
  signal column_bdeven : bdeventype;
  signal row_bdodd : oddrowtype;
  signal row_bdeven : evenrowtype;
  signal check : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal errorfoundnode : STD_LOGIC;
  
  signal ppomega : ppomegatype;
  signal column_omega : ppomegatype;
  signal row_omega : omegarowtype;
  signal adder_omega : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
      
  signal errorinversenode, correctionnode : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
            
  component rsp_gf_mul IS 
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

  polynomial_value <= conv_std_logic_vector(polynomial,m_bits+1);
  
  prc_symbol: PROCESS (sysclk,reset)
  BEGIN
  
    IF (reset = '1') THEN
    
      FOR k IN 1 TO bm_symbols LOOP
        bd_baseff(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
        omega_baseff(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      END LOOP;
      bd0ff <= conv_std_logic_vector (0,m_bits);
      
      adder_bdoddff <= conv_std_logic_vector (0,m_bits);
      adder_bdevenff <= conv_std_logic_vector (0,m_bits);
      
      adder_omegaff(1)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      adder_omegaff(2)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      adder_omegaff(3)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      correctionff <= conv_std_logic_vector (0,m_bits);
      errorfoundff <= "000";
        
    ELSIF (rising_edge(sysclk)) THEN
      
      IF (enable = '1') THEN
        FOR k IN 1 TO bm_symbols LOOP
          bd_baseff(k)(m_bits DOWNTO 1) <= bd_base(k)(m_bits DOWNTO 1);
          omega_baseff(k)(m_bits DOWNTO 1) <= omega_base(k)(m_bits DOWNTO 1);
        END LOOP;
        bd0ff <= bd_baseff(1);
        
        adder_bdoddff <= row_bdodd(derivative_terms)(m_bits DOWNTO 1);
        adder_bdevenff <= row_bdeven(even_terms)(m_bits DOWNTO 1);
        
        adder_omegaff(1)(m_bits DOWNTO 1) <= adder_omega(m_bits DOWNTO 1);
        adder_omegaff(2)(m_bits DOWNTO 1) <= adder_omegaff(1)(m_bits DOWNTO 1);
        adder_omegaff(3)(m_bits DOWNTO 1) <= adder_omegaff(2)(m_bits DOWNTO 1);
        
        correctionff <= correctionnode;
        errorfoundff(1) <= errorfoundnode;
        errorfoundff(2) <= errorfoundff(1);
        errorfoundff(3) <= errorfoundff(2) AND NOT(zero_error_found);
      
      END IF;
      
    END IF;
    
  END PROCESS;
  
  gen_shiftbd_two: FOR k IN 1 TO error_symbols GENERATE
    bb_shift(k)(m_bits DOWNTO 1) <= conv_std_logic_vector(powernum(k*shiftindex mod field_modulo),m_bits);
  END GENERATE;
  
  gen_const_one: FOR j IN 1 TO error_symbols GENERATE
    const_value(j)(1)(m_bits DOWNTO 1) <= bb_shift(j)(m_bits DOWNTO 1);
    gen_const_two: FOR k IN 2 TO m_bits GENERATE
       pre_const_value(j)(k)(m_bits DOWNTO 1) <= const_value(j)(k-1)(m_bits-1 DOWNTO 1) & '0';
       gen_const_thr: FOR m IN 1 TO m_bits GENERATE
          const_value(j)(k)(m) <= pre_const_value(j)(k)(m) XOR (polynomial_value(m) AND const_value(j)(k-1)(m_bits));
       END GENERATE;    
     END GENERATE;
  END GENERATE;
  
  --*** BD ***
  
  gen_ppbd_one: FOR j IN 1 TO error_symbols GENERATE
    gen_ppbd_two: FOR k IN 1 TO m_bits GENERATE
       gen_ppbd_thr: FOR m IN 1 TO m_bits GENERATE
          ppbd(j)(k)(m) <= const_value(j)(k)(m) AND bd_baseff(j+riBm)(k);
       END GENERATE;    
     END GENERATE;
  END GENERATE;
  
  -- add all bd odd columns
  gen_colbd_one: FOR j IN 1 TO derivative_terms GENERATE
    column_bdodd(j)(1)(m_bits DOWNTO 1) <= ppbd(2*j-1)(1)(m_bits DOWNTO 1);
    gen_colbd_two: FOR k IN 2 TO m_bits GENERATE
       gen_colbd_thr: FOR m IN 1 TO m_bits GENERATE
          column_bdodd(j)(k)(m) <= column_bdodd(j)(k-1)(m) XOR ppbd(2*j-1)(k)(m);
       END GENERATE;    
     END GENERATE;
  END GENERATE;
  
  -- add all bd even columns
  gen_col_for: FOR j IN 1 TO even_terms GENERATE
    column_bdeven(j)(1)(m_bits DOWNTO 1) <= ppbd(2*j)(1)(m_bits DOWNTO 1);
    gen_col_fiv: FOR k IN 2 TO m_bits GENERATE
       gen_col_six: FOR m IN 1 TO m_bits GENERATE
          column_bdeven(j)(k)(m) <= column_bdeven(j)(k-1)(m) XOR ppbd(2*j)(k)(m);
       END GENERATE;    
     END GENERATE;
  END GENERATE;
  
  -- add all bd odd rows
  row_bdodd(1)(m_bits DOWNTO 1) <= column_bdodd(1)(m_bits)(m_bits DOWNTO 1);
  gen_rowbd_one: FOR j IN 2 TO derivative_terms GENERATE
    gen_rowbd_two: FOR k IN 1 TO m_bits GENERATE
       row_bdodd(j)(k) <= row_bdodd(j-1)(k) XOR column_bdodd(j)(m_bits)(k);
     END GENERATE;
  END GENERATE;
  
  -- add all bd even rows
  row_bdeven(1)(m_bits DOWNTO 1) <= column_bdeven(1)(m_bits)(m_bits DOWNTO 1);
  gen_rowbd_thr: FOR j IN 2 TO even_terms GENERATE
    gen_rowbd_for: FOR k IN 1 TO m_bits GENERATE
       row_bdeven(j)(k) <= row_bdeven(j-1)(k) XOR column_bdeven(j)(m_bits)(k);
     END GENERATE;
  END GENERATE;  
  
  -- = adder + 1
  no_riBm_check : IF (riBm = 0) GENERATE
    check(1) <= adder_bdoddff(1) XOR adder_bdevenff(1) XOR '1';
    gen_check: FOR k IN 2 TO m_bits GENERATE
      check(k) <= check(k-1) OR (adder_bdoddff(k) XOR adder_bdevenff(k));
    END GENERATE; 
  END GENERATE; 
  riBm_check : IF (riBm = 1) GENERATE
    check(1) <= adder_bdoddff(1) XOR adder_bdevenff(1) XOR bd0ff(1);
    gen_check: FOR k IN 2 TO m_bits GENERATE
      check(k) <= check(k-1) OR (adder_bdoddff(k) XOR adder_bdevenff(k) XOR (bd0ff(k)));
    END GENERATE; 
  END GENERATE;
  errorfoundnode <= NOT(check(m_bits));
  
  --*** OMEGA ***
  
  gen_ppomega_one: FOR j IN 1 TO error_symbols-1 GENERATE
    gen_ppomega_two: FOR k IN 1 TO m_bits GENERATE
       gen_ppomega_thr: FOR m IN 1 TO m_bits GENERATE
          ppomega(j)(k)(m) <= const_value(j)(k)(m) AND omega_baseff(j+1)(k);
       END GENERATE;    
     END GENERATE;
  END GENERATE;
  
  gen_colomega_one: FOR j IN 1 TO error_symbols-1 GENERATE
    column_omega(j)(1)(m_bits DOWNTO 1) <= ppomega(j)(1)(m_bits DOWNTO 1);
    gen_colomega_two: FOR k IN 2 TO m_bits GENERATE
       gen_colomega_thr: FOR m IN 1 TO m_bits GENERATE
          column_omega(j)(k)(m) <= column_omega(j)(k-1)(m) XOR ppomega(j)(k)(m);
       END GENERATE;    
     END GENERATE;
  END GENERATE;  
  
  row_omega(1)(m_bits DOWNTO 1) <= column_omega(1)(m_bits)(m_bits DOWNTO 1);
  gen_rowomega_one: FOR j IN 2 TO error_symbols-1 GENERATE
    gen_rowomega_two: FOR k IN 1 TO m_bits GENERATE
       row_omega(j)(k) <= row_omega(j-1)(k) XOR column_omega(j)(m_bits)(k);
     END GENERATE;
  END GENERATE;
  
  gen_omega_add: FOR m IN 1 TO m_bits GENERATE
    adder_omega(m) <= row_omega(error_symbols-1)(m) XOR omega_baseff(1)(m);
  END GENERATE;

  
  get_inv_of <= adder_bdoddff;
  get_inv_of_valid <= errorfoundnode;
  errorinverse <= value_of_inv;
  
  comp_mul: rsp_gf_mul
  GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  PORT MAP (aa=>adder_omegaff(3)(m_bits DOWNTO 1),bb=>errorinverse,--
            cc=>correctionnode);
            
  --*** OUTPUTS ***
  count_this_one <= errorfoundff(1);
  error_found <= errorfoundff(3);
  error_correct(m_bits DOWNTO 1) <= correctionff;  

 END rtl;
 
 