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

USE work.bchp_parameters.all;
USE work.bchp_functions.all;

--***************************************************
--***                                             ***
--***   ALTERA BCH LIBRARY                        ***
--***                                             ***
--***   BCHP_PACKAGE                              ***
--***                                             ***
--***   Function: Package                         ***
--***                                             ***
--***   27/07/12 ML                               ***
--***                                             ***
--***   (c) 2012 Altera Corporation               ***
--***                                             ***
--***   Change History                            ***
--***                                             ***
--***                                             ***
--***                                             ***
--***                                             ***
--***                                             ***
--***************************************************

PACKAGE bchp_package IS

  constant check_symbols : positive := t_symbols * 2;
  constant field_size : positive := 2**m_bits;
  constant field_index : positive := field_size - 1; -- m_bits = 8, index= 0 to 255
  constant search_offset : integer := field_index - n_symbols;
  constant codeword_clocks : positive := howmany_clocks (n_symbols,parallel_bits);
  constant adder_elements : positive := howmany_adder_elements(t_symbols);
  constant last_adder_elements : integer := howmany_last_adder_elements(t_symbols);
  constant last_parallel_bits : integer := codeword_clocks*parallel_bits - n_symbols;
  constant modulo_parallel_bits : integer := parallel_bits - last_parallel_bits;
  
  type syndromevector IS ARRAY (check_symbols DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type errorvector IS ARRAY (t_symbols DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type parallelvector IS ARRAY (parallel_bits DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);

  component bchp_mb_pex
  GENERIC (
           speed : positive := 8; -- 6,7,8
           startloop : integer := 2;
           endloop : integer := 6
          ); -- mloop: 0 to check_symbols-1
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        start : IN STD_LOGIC; -- start this stage
        syndromesin : IN syndromevector;
        bdsin, bdsprevin : IN errorvector;
        llnumberin : IN STD_LOGIC_VECTOR (8 DOWNTO 1);
        deltain : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

      
		    syndromesout : OUT syndromevector;
        bdsout, bdsprevout : OUT errorvector;
        llnumberout : OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
        deltaout : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
        nextstage : OUT STD_LOGIC -- start for next level
		  );
  end component;
  
END bchp_package;
