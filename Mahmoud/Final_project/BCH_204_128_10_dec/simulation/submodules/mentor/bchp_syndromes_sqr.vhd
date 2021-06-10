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
USE work.bchp_functions.all;

--***************************************************
--***                                             ***
--***   ALTERA BCH LIBRARY                        ***
--***                                             ***
--***   BCHP_SYNDROME_SQR                         ***
--***                                             ***
--***   Function: Calculate BCH Syndromes using   ***
--***   squaring where possible                   ***
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

ENTITY bchp_syndromes_sqr IS 
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      load : IN STD_LOGIC;
      bits : IN STD_LOGIC_VECTOR (parallel_bits DOWNTO 1);
    
      syndromes : OUT syndromevector;
      synvalid : OUT STD_LOGIC
		 );
END bchp_syndromes_sqr;

ARCHITECTURE rtl OF bchp_syndromes_sqr IS

  constant thr_squares : integer := howmany_squares (8,check_symbols);
  constant for_squares : integer := howmany_squares (16,check_symbols);
  constant fiv_squares : integer := howmany_squares (32,check_symbols);
  constant six_squares : integer := howmany_squares (64,check_symbols);
  constant sev_squares : integer := howmany_squares (128,check_symbols);
  constant eig_squares : integer := howmany_squares (256,check_symbols);
  constant deepest : positive := deepest_syndrome(t_symbols);

  type syntype IS ARRAY (check_symbols DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);

  signal syndromenode : syndromevector;
  signal syndromeff : syndromevector;
  signal validnode : STD_LOGIC_VECTOR (check_symbols DOWNTO 1);
  signal validff : STD_LOGIC;
  
  component bchp_syndrome  
  GENERIC (startpower : positive := 1);
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        load : IN STD_LOGIC;
        bits : IN STD_LOGIC_VECTOR (parallel_bits DOWNTO 1);
    
        syndrome : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
        synvalid : OUT STD_LOGIC
		   );
	end component;
		 
  component rsp_gf_sqrff 
  GENERIC (
           polynomial : positive := 285;
           m_bits : positive := 8
          );
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        validin : IN STD_LOGIC;
        aa : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

		    cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
		    validout : OUT STD_LOGIC
		   );
  end component;
  
 
BEGIN
  
  -- support t upto 128 now
  
  -- 1,3,5,...79...
  gen_one: FOR k IN 1 TO t_symbols GENERATE
    comp_one: bchp_syndrome 
    GENERIC MAP (startpower=>2*k-1)
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
              load=>load,
              bits=>bits,
              syndrome=>syndromenode(2*k-1)(m_bits DOWNTO 1),
              synvalid=>validnode(2*k-1));
  END GENERATE;
  
  -- comp_one^2 : 2,6,10...78...
  gen_two: FOR k IN 1 TO (t_symbols+1)/2 GENERATE -- changed the range from t_symbols/2 to (t_symbols+1)/2
    comp_two: rsp_gf_sqrff
    GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
              validin=>validnode(2*k-1),
              aa=>syndromenode(2*k-1)(m_bits DOWNTO 1),
              cc=>syndromenode(4*k-2)(m_bits DOWNTO 1),
              validout=>validnode(4*k-2));
  END GENERATE;
  
  -- comp_two^2 : 4,12,20...76...
  gen_thr_if : IF (thr_squares > 0) GENERATE
    gen_thr_loop: FOR k IN 1 TO thr_squares GENERATE
      comp_thr: rsp_gf_sqrff 
      GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
      PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
                validin=>validnode(4*k-2),
                aa=>syndromenode(4*k-2)(m_bits DOWNTO 1),
                cc=>syndromenode(8*k-4)(m_bits DOWNTO 1),
                validout=>validnode(8*k-4));
    END GENERATE;
  END GENERATE;
  
  -- comp_thr^2 : 8,24,40...
  gen_for_if : IF (for_squares > 0) GENERATE
    gen_for_loop: FOR k IN 1 TO for_squares GENERATE
      comp_for: rsp_gf_sqrff
      GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
      PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
                validin=>validnode(8*k-4),
                aa=>syndromenode(8*k-4)(m_bits DOWNTO 1),
                cc=>syndromenode(16*k-8)(m_bits DOWNTO 1),
                validout=>validnode(16*k-8));
    END GENERATE;
  END GENERATE;
  
  -- comp_for^2 : 16,48...
  gen_fiv_if : IF (fiv_squares > 0) GENERATE
    gen_fiv_loop: FOR k IN 1 TO fiv_squares GENERATE
      comp_fiv: rsp_gf_sqrff 
      GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
      PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
                validin=>validnode(16*k-8),
                aa=>syndromenode(16*k-8)(m_bits DOWNTO 1),
                cc=>syndromenode(32*k-16)(m_bits DOWNTO 1),
                validout=>validnode(32*k-16));
    END GENERATE;
  END GENERATE;
  
  -- comp_fiv^2 : 32...
  gen_six_if : IF (six_squares > 0) GENERATE
    gen_six_loop: FOR k IN 1 TO six_squares GENERATE
      comp_six: rsp_gf_sqrff
      GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
      PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
                validin=>validnode(32*k-16),
                aa=>syndromenode(32*k-16)(m_bits DOWNTO 1),
                cc=>syndromenode(64*k-32)(m_bits DOWNTO 1),
                validout=>validnode(64*k-32));
    END GENERATE;
  END GENERATE;
  
  -- comp_six^2 : 64...
  gen_sev_if : IF (sev_squares > 0) GENERATE
    gen_sev_loop: FOR k IN 1 TO sev_squares GENERATE
      comp_sev: rsp_gf_sqrff
      GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
      PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
                validin=>validnode(64*k-32),
                aa=>syndromenode(64*k-32)(m_bits DOWNTO 1),
                cc=>syndromenode(128*k-64)(m_bits DOWNTO 1),
                validout=>validnode(128*k-64));
    END GENERATE;
  END GENERATE;

  -- comp_sev^2 : 128...
  gen_eig_if : IF (eig_squares > 0) GENERATE
    gen_eig_loop: FOR k IN 1 TO eig_squares GENERATE
      comp_eig: rsp_gf_sqrff
      GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
      PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
                validin=>validnode(128*k-64),
                aa=>syndromenode(128*k-64)(m_bits DOWNTO 1),
                cc=>syndromenode(256*k-128)(m_bits DOWNTO 1),
                validout=>validnode(256*k-128));
    END GENERATE;
  END GENERATE;
  
  prc: PROCESS (sysclk)
  BEGIN
    
    IF (rising_edge(sysclk)) THEN

      IF (reset = '1') THEN
      
        FOR k IN 1 TO check_symbols LOOP
          syndromeff(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
        END LOOP;
        validff <= '0';


      ELSIF enable = '1' THEN
      
        FOR k IN 1 TO check_symbols LOOP
          IF (validnode(k) = '1') THEN
            syndromeff(k)(m_bits DOWNTO 1) <= syndromenode(k)(m_bits DOWNTO 1);
          END IF;
        END LOOP;

        validff <= validnode(deepest); -- deepest syndrome here indicates the critical path of computing syndrome, as this RTL make use of squaring technique
    
      ELSE

        validff <= '0';

      END IF;

    END IF;
      
  END PROCESS;
  
  --*** OUTPUTS ***
  
  syndromes <= syndromeff;
  synvalid <= validff;
  
END rtl;

