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
USE work.bchp_functions.all;

--***************************************************
--***                                             ***
--***   ALTERA BCH LIBRARY                        ***
--***                                             ***
--***   BCHP_SEARCH                               ***
--***                                             ***
--***   Function: Chien Search - Use Multiple     ***
--***   Shift Searches                            ***
--***                                             ***
--***   Set number of shift searches here, not    ***
--***   meant to be common user parameter         ***
--***                                             ***
--***   20/05/2013 ML                             ***
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

ENTITY bchp_search IS 
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      start_search : IN STD_LOGIC;
      errorlocator : IN errorvector; -- error locator polynomial, shifted for first index
      
		  error_found : OUT STD_LOGIC_VECTOR (parallel_bits DOWNTO 1)
		 );
END bchp_search;

ARCHITECTURE rtl OF bchp_search IS

  --*** updated on 29.Jan.2015  automatically determine number of cores by parallel_bits ***
  constant number_cores : positive := howmany_cores(parallel_bits);
  
  constant parallel_searchbits : positive := parallel_bits / number_cores;
  constant last_searchbits : positive := parallel_bits - parallel_searchbits * (number_cores-1);          
   
  component bchp_shift_searches 
  GENERIC (
           stopnumber : integer := 127;
           index : integer := 1;  -- index is 1,2,3,4,5 
           parallel_searchbits : positive := 10
          );
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        start_search : IN STD_LOGIC;
        errorlocator : IN errorvector;
      
		    error_found : OUT STD_LOGIC_VECTOR (parallel_searchbits DOWNTO 1);
		    done : OUT STD_LOGIC
		   );
  end component;
                                            
BEGIN
  
  gen_one: IF (number_cores = 1) GENERATE
    comp_core_one: bchp_shift_searches
    GENERIC MAP (stopnumber=>codeword_clocks,index=>search_offset+1,
                 parallel_searchbits=>parallel_bits)
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
              start_search=>start_search,
              errorlocator=>errorlocator,
              error_found=>error_found);
  END GENERATE;
  
  gen_many: IF (number_cores > 1) GENERATE
    gen_loop: FOR k IN 1 TO (number_cores-1) GENERATE
      comp_core_loop: bchp_shift_searches  
      GENERIC MAP (stopnumber=>codeword_clocks,index=>search_offset+1+parallel_searchbits*(k-1),
                   parallel_searchbits=>parallel_searchbits)
      PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
                start_search=>start_search,
                errorlocator=>errorlocator,
                error_found=>error_found(parallel_searchbits*k DOWNTO parallel_searchbits*(k-1)+1));
    END GENERATE;
    comp_core_last: bchp_shift_searches  
    GENERIC MAP (stopnumber=>codeword_clocks,index=>search_offset+1+parallel_searchbits*(number_cores-1),
                parallel_searchbits=>last_searchbits)
      PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
                start_search=>start_search,
                errorlocator=>errorlocator,
                error_found=>error_found(parallel_bits DOWNTO parallel_bits-last_searchbits+1));
  END GENERATE;
                  
END rtl;

