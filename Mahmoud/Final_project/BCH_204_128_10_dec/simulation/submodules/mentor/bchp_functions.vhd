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

--***************************************************
--***                                             ***
--***   ALTERA BCH LIBRARY                        ***
--***                                             ***
--***   BCHP_FUNCTION                             ***
--***                                             ***
--***   Function: Parameter Calculations          ***
--***                                             ***
--***   27/07/12 ML                               ***
--***                                             ***
--***   (c) 2012 Altera Corporation               ***
--***                                             ***
--***   Change History                            ***
--***                                             ***
--***   May 7, 2014 : Add systolic_width function ***
--***                                             ***
--***                                             ***
--***                                             ***
--***************************************************

PACKAGE bchp_functions IS

  FUNCTION howmany_clocks (constant n_value : positive;constant p_value : positive) return positive;
  FUNCTION howmany_adder_elements (constant t_value : positive) return positive;
  FUNCTION howmany_last_adder_elements (constant t_value : positive) return positive;
  FUNCTION howmany_squares (constant base : positive;constant check_value : positive) return integer;
  FUNCTION deepest_syndrome (constant t_value : positive) return positive;
  FUNCTION systolic_width (constant end_value : positive;constant t_value : positive) return positive;
  FUNCTION howmany_cores (constant parallel_bits: positive) return positive;
  FUNCTION howmany_fifo_words (constant codeword_clocks : positive;constant poly_delay : positive) return positive;
  FUNCTION log2_function (constant in_data : positive) return natural;
  
END bchp_functions;

PACKAGE BODY bchp_functions IS
  
  FUNCTION howmany_clocks (constant n_value : positive; constant p_value : positive) 
  return positive IS
    variable modulus : integer;
  BEGIN
    modulus := n_value - (n_value/p_value)*p_value;
    IF (modulus = 0) THEN
      return (n_value/p_value);
    ELSE
      return (n_value/p_value + 1);
    END IF;
  END howmany_clocks;
  
  FUNCTION howmany_adder_elements (constant t_value : positive) 
  return positive IS
    variable modulus : integer;
    variable nextmodulus : integer;
  BEGIN
    modulus := t_value - (t_value/6)*6;
    IF (modulus = 0) THEN
      return (t_value/6);
    END IF;
    IF (t_value > 40) THEN
      return ((t_value/6)+1);
    ELSE
      return (t_value/6);
    END IF;
  END howmany_adder_elements;

  FUNCTION howmany_last_adder_elements (constant t_value : positive) 
  return positive IS
    variable modulus : integer;
    variable nextmodulus : integer;
  BEGIN
    modulus := t_value - (t_value/6)*6;
    IF (modulus = 0) THEN
      return (t_value/6);
    END IF;
    IF (t_value > 40) THEN
      return (t_value-((t_value/6)+1)*5);
    ELSE
      return (t_value-(t_value/6)*5);
    END IF;
  END howmany_last_adder_elements;

FUNCTION howmany_squares 
(constant base : positive;
 constant check_value : positive) 
  return integer IS
    variable check : integer;
  BEGIN
    check := (check_value + (base/2))/base;
    IF (check >= 0) THEN
      return check;
    ELSE
      return 0;
    END IF;
  END howmany_squares;

  FUNCTION deepest_syndrome (constant t_value : positive) 
  return positive IS
    variable depth : integer;
  BEGIN
    -- covers range 1 to 127
    IF (t_value >= 1) THEN
      depth := 2;
    END IF; 
    IF (t_value >= 2) THEN
      depth := 4;
    END IF;
    IF (t_value >= 4) THEN
      depth := 8;
    END IF;
    IF (t_value >= 8) THEN
      depth := 16;
    END IF;
    IF (t_value >= 16) THEN
      depth := 32;
    END IF;
    IF (t_value >= 32) THEN 
      depth := 64;
    END IF;
    IF (t_value >= 64) THEN
      depth := 128;
    END IF;
    return depth;
  END deepest_syndrome;
  
  -- updated to have minimum value 4
  FUNCTION systolic_width 
  (constant end_value : positive;
   constant t_value : positive) 
  return positive IS
    variable width : integer;
  BEGIN
    IF (end_value >= t_value) THEN
      return t_value;
    ELSIF end_value >= 4 THEN
      return end_value;
    ELSE
      return 4;
    END IF;
  END systolic_width;

  FUNCTION howmany_cores
  (constant parallel_bits : positive) 
  return positive IS
    variable number_cores : positive;
  BEGIN
    -- number of cores for chien search module
    -- it does not bring major impact to the chien search module, mainly to reduce fan-out
    IF (parallel_bits > 40) THEN
      return 8;
    ELSIF (parallel_bits > 16) THEN
      return 4;
    ELSE
      return 1;
    END IF;
  END howmany_cores;

  -- depth of the FIFO: input latency + 25 cc for syndromes (more than enough) + poly delay + chien search delay
  FUNCTION howmany_fifo_words
  (constant codeword_clocks : positive;
   constant poly_delay : positive) 
  return positive IS
    variable lpm_numwords : positive;
  BEGIN
    lpm_numwords := (codeword_clocks+1) + 25 + (poly_delay+2) + 6;
    IF (lpm_numwords - lpm_numwords/2 > 0) THEN
      lpm_numwords := lpm_numwords + 1;
    END IF;
    RETURN lpm_numwords;
  END howmany_fifo_words;

  -- log2 function 
  FUNCTION log2_function
  (constant in_data : positive)
  return natural IS
    variable temp    : integer := in_data;
    variable ret_val : integer := 0; 
  begin		
			
    while temp > 1 loop
      ret_val := ret_val + 1;
      temp    := temp / 2;     
    end loop;

    if ret_val = 0 then
      ret_val := 1;
    end if;
  	
    return ret_val;
  END log2_function;
      
END bchp_functions;

