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
USE work.bchp_auto_package.all;

--***************************************************
--***                                             ***
--***   ALTERA BCH LIBRARY                        ***
--***                                             ***
--***   BCHP_MB_PEX                               ***
--***                                             ***
--***   Function: Berlekamp-Massey Instantiation  ***
--***                                             ***
--***   27/07/12 ML                               ***
--***                                             ***
--***   (c) 2012 Altera Corporation               ***
--***                                             ***
--***   Change History                            ***
--***                                             ***
--***   17/12/2014 - Add Optimized PE for all     ***
--***   reduced iterations                        ***
--***                                             ***
--***                                             ***
--***************************************************

ENTITY bchp_mb_pex IS
GENERIC (
         speed : positive := 7; 
         startloop : integer := 24;
         endloop : integer := 46
        ); 
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      start : IN STD_LOGIC; 
      syndromesin : IN syndromevector;
      bdsin, bdsprevin : IN errorvector;
      llnumberin : IN STD_LOGIC_VECTOR (8 DOWNTO 1);
      deltain : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

      
		  syndromesout : OUT syndromevector;
      bdsout, bdsprevout : OUT errorvector;
      llnumberout : OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
      deltaout : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
      nextstage : OUT STD_LOGIC 
		 );
END bchp_mb_pex;
  
ARCHITECTURE rtl OF bchp_mb_pex IS
        
    component bchp_mb_pe6
    GENERIC (
             startloop : integer := 2;
             endloop : integer := 6
            ); 
    PORT (
          sysclk, reset, enable : IN STD_LOGIC;
          start : IN STD_LOGIC; 
          syndromesin : IN syndromevector;
          bdsin, bdsprevin : IN errorvector;
          llnumberin : IN STD_LOGIC_VECTOR (8 DOWNTO 1);
          deltain : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

      
		      syndromesout : OUT syndromevector;
          bdsout, bdsprevout : OUT errorvector;
          llnumberout : OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
          deltaout : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
          nextstage : OUT STD_LOGIC 
		    );
    end component;
        
    component bchp_mb_pe7
    GENERIC (
             startloop : integer := 2;
             endloop : integer := 6
            ); 
    PORT (
          sysclk, reset, enable : IN STD_LOGIC;
          start : IN STD_LOGIC; 
          syndromesin : IN syndromevector;
          bdsin, bdsprevin : IN errorvector;
          llnumberin : IN STD_LOGIC_VECTOR (8 DOWNTO 1);
          deltain : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

      
		      syndromesout : OUT syndromevector;
          bdsout, bdsprevout : OUT errorvector;
          llnumberout : OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
          deltaout : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
          nextstage : OUT STD_LOGIC 
		    );
    end component;

    component bchp_mb_pe8
    GENERIC (
             startloop : integer := 2;
             endloop : integer := 6
            ); 
    PORT (
          sysclk, reset, enable : IN STD_LOGIC;
          start : IN STD_LOGIC; 
          syndromesin : IN syndromevector;
          bdsin, bdsprevin : IN errorvector;
          llnumberin : IN STD_LOGIC_VECTOR (8 DOWNTO 1);
          deltain : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

      
		      syndromesout : OUT syndromevector;
          bdsout, bdsprevout : OUT errorvector;
          llnumberout : OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
          deltaout : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
          nextstage : OUT STD_LOGIC 
		    );
    end component;

    component bchp_mbopt_pe6
    GENERIC (
             startloop : integer := 2;
             endloop : integer := 6
            ); 
    PORT (
          sysclk, reset, enable : IN STD_LOGIC;
          start : IN STD_LOGIC; 
          syndromesin : IN syndromevector;
          bdsin, bdsprevin : IN errorvector;
          llnumberin : IN STD_LOGIC_VECTOR (8 DOWNTO 1);
          deltain : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

      
		      syndromesout : OUT syndromevector;
          bdsout, bdsprevout : OUT errorvector;
          llnumberout : OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
          deltaout : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
          nextstage : OUT STD_LOGIC 
		    );
    end component;
        
    component bchp_mbopt_pe7
    GENERIC (
             startloop : integer := 2;
             endloop : integer := 6
            ); 
    PORT (
          sysclk, reset, enable : IN STD_LOGIC;
          start : IN STD_LOGIC; 
          syndromesin : IN syndromevector;
          bdsin, bdsprevin : IN errorvector;
          llnumberin : IN STD_LOGIC_VECTOR (8 DOWNTO 1);
          deltain : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

      
		      syndromesout : OUT syndromevector;
          bdsout, bdsprevout : OUT errorvector;
          llnumberout : OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
          deltaout : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
          nextstage : OUT STD_LOGIC 
		    );
    end component;
 
    component bchp_mbopt_pe8
    GENERIC (
             startloop : integer := 2;
             endloop : integer := 6
            ); 
    PORT (
          sysclk, reset, enable : IN STD_LOGIC;
          start : IN STD_LOGIC; 
          syndromesin : IN syndromevector;
          bdsin, bdsprevin : IN errorvector;
          llnumberin : IN STD_LOGIC_VECTOR (8 DOWNTO 1);
          deltain : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

      
		      syndromesout : OUT syndromevector;
          bdsout, bdsprevout : OUT errorvector;
          llnumberout : OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
          deltaout : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
          nextstage : OUT STD_LOGIC 
		    );
    end component;
         
BEGIN
  
  gen_six: IF (speed = 6 AND poly_optimize = 0) GENERATE
    comp_six: bchp_mb_pe6
    GENERIC MAP (startloop=>startloop,endloop=>endloop)
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
              start=>start,
              syndromesin=>syndromesin,
              bdsin=>bdsin,bdsprevin=>bdsprevin,
              llnumberin=>llnumberin,
              deltain=>deltain,
              
              syndromesout=>syndromesout,
              bdsout=>bdsout,bdsprevout=>bdsprevout,
              llnumberout=>llnumberout,
              deltaout=>deltaout,
              nextstage=>nextstage);
  END GENERATE;

  gen_seven: IF (speed = 7 AND poly_optimize = 0) GENERATE
    comp_seven: bchp_mb_pe7
    GENERIC MAP (startloop=>startloop,endloop=>endloop)
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
              start=>start,
              syndromesin=>syndromesin,
              bdsin=>bdsin,bdsprevin=>bdsprevin,
              llnumberin=>llnumberin,
              deltain=>deltain,
              
              syndromesout=>syndromesout,
              bdsout=>bdsout,bdsprevout=>bdsprevout,
              llnumberout=>llnumberout,
              deltaout=>deltaout,
              nextstage=>nextstage);
  END GENERATE;

  gen_eight: IF (speed = 8 AND poly_optimize = 0) GENERATE
    comp_eight: bchp_mb_pe8
    GENERIC MAP (startloop=>startloop,endloop=>endloop)
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
              start=>start,
              syndromesin=>syndromesin,
              bdsin=>bdsin,bdsprevin=>bdsprevin,
              llnumberin=>llnumberin,
              deltain=>deltain,
              
              syndromesout=>syndromesout,
              bdsout=>bdsout,bdsprevout=>bdsprevout,
              llnumberout=>llnumberout,
              deltaout=>deltaout,
              nextstage=>nextstage);
  END GENERATE;
  
gen_six_opt: IF (speed = 6 AND poly_optimize = 1) GENERATE
    comp_six: bchp_mbopt_pe6
    GENERIC MAP (startloop=>startloop,endloop=>endloop)
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
              start=>start,
              syndromesin=>syndromesin,
              bdsin=>bdsin,bdsprevin=>bdsprevin,
              llnumberin=>llnumberin,
              deltain=>deltain,
              
              syndromesout=>syndromesout,
              bdsout=>bdsout,bdsprevout=>bdsprevout,
              llnumberout=>llnumberout,
              deltaout=>deltaout,
              nextstage=>nextstage);
  END GENERATE;
 
  gen_sev_opt: IF (speed = 7 AND poly_optimize = 1) GENERATE
    comp_seven: bchp_mbopt_pe7
    GENERIC MAP (startloop=>startloop,endloop=>endloop)
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
              start=>start,
              syndromesin=>syndromesin,
              bdsin=>bdsin,bdsprevin=>bdsprevin,
              llnumberin=>llnumberin,
              deltain=>deltain,
              
              syndromesout=>syndromesout,
              bdsout=>bdsout,bdsprevout=>bdsprevout,
              llnumberout=>llnumberout,
              deltaout=>deltaout,
              nextstage=>nextstage);
  END GENERATE;

  gen_egt_opt: IF (speed = 8 AND poly_optimize = 1) GENERATE
    comp_eight: bchp_mbopt_pe8
    GENERIC MAP (startloop=>startloop,endloop=>endloop)
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
              start=>start,
              syndromesin=>syndromesin,
              bdsin=>bdsin,bdsprevin=>bdsprevin,
              llnumberin=>llnumberin,
              deltain=>deltain,
              
              syndromesout=>syndromesout,
              bdsout=>bdsout,bdsprevout=>bdsprevout,
              llnumberout=>llnumberout,
              deltaout=>deltaout,
              nextstage=>nextstage);
  END GENERATE;
         
END rtl;
  
  