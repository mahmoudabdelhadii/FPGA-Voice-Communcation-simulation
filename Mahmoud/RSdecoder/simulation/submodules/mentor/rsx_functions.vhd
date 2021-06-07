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
--***   ALTERA REED SOLOMON LIBRARY               ***
--***                                             ***
--***   RSP_FUNCTIONS                             ***
--***                                             ***
--***   Function: Calculations for the package of ***
--***   the Parallel RS Decoder                   ***
--***                                             ***
--***   06/07/10 ML                               ***
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

PACKAGE rsx_functions IS
  function is_a_strict_sup_b  (constant  a : integer; constant  b : integer) return integer;
  function max(constant  a : positive;constant  b : positive) return positive;
  function howmanyclocks (constant  n : positive;constant parallel : positive) return positive;
  function howmanycores  (constant  clocks : positive; constant  speed : positive) return positive;
  function is_riBm_used  (constant bm_speed : positive) return integer;
  function clog2 (constant  a : positive) return positive;
END rsx_functions;

PACKAGE BODY rsx_functions IS

  FUNCTION max (constant a : positive; constant b : positive) 
  return positive IS
  BEGIN
      IF (a > b) THEN
        return a;
      ELSE
        return b;
      END IF;
  END max;
  FUNCTION is_a_strict_sup_b (constant a : integer; constant b : integer) 
  return integer IS
  BEGIN
      IF (a > b) THEN
        return 1;
      ELSE
        return 0;
      END IF;
  END is_a_strict_sup_b;
  FUNCTION howmanyclocks (constant n : positive; constant parallel : positive) 
  return positive IS
    variable modulus : integer;
  BEGIN
    modulus := n - (n/parallel)*parallel;
    IF (modulus = 0) THEN
      return (n/parallel);
    ELSE
      return ((n/parallel)+1);
    END IF;
  END howmanyclocks;

  FUNCTION howmanycores (constant clocks : positive; constant speed : positive) 
  return positive IS
    variable modulus : integer;
  BEGIN
    modulus := clocks - (clocks/speed)*speed;
    IF (modulus = 0) THEN
      return (clocks/speed);
    ELSE
      return ((clocks/speed)+1);
    END IF;
  END howmanycores;
    
  FUNCTION is_riBm_used (constant bm_speed : positive) 
  return integer IS
  BEGIN
    IF (bm_speed < 4 ) THEN
      return 1;
    ELSE
      return 0;
    END IF;
  END is_riBm_used;  
    
  FUNCTION clog2 (constant a : positive) 
  return positive IS
  BEGIN
      IF (a = 1) THEN
        return 1;
      END IF;
      
      FOR i IN 1 TO 30 LOOP
        IF (2**i >= a) THEN
          return i;
        END IF;
      END LOOP;
      return 30;
  END clog2;
    
    
END rsx_functions;

