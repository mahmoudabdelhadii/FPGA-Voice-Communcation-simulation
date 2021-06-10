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
--***   BCHP_SHIFT_SEARCHES                       ***
--***                                             ***
--***   Function: Top Level of a Group of Chien   ***
--***   Searches                                  ***
--***  (optional power savings for gapped data)   ***
--***                                             ***
--***   17/12/14 ML                               ***
--***                                             ***
--***   (c) 2014 Altera Corporation               ***
--***                                             ***
--***   Change History                            ***
--***                                             ***
--***                                             ***
--***                                             ***
--***                                             ***
--***                                             ***
--***************************************************

ENTITY bchp_shift_searches IS 
GENERIC (
         stopnumber : integer := 127;
         index : integer := 1;  
         parallel_searchbits : positive := 10
        );
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      start_search : IN STD_LOGIC;
      errorlocator : IN errorvector;
      
		  error_found : OUT STD_LOGIC_VECTOR (parallel_searchbits DOWNTO 1);
		  done : OUT STD_LOGIC
		 );
END bchp_shift_searches;

ARCHITECTURE rtl OF bchp_shift_searches IS
  
  constant genstart : integer := 0;

  type addertype IS ARRAY (adder_elements DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type lastaddertype IS ARRAY (last_adder_elements DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  signal do_searchff : STD_LOGIC;
  signal start_searchff : STD_LOGIC;
  signal searchcountff : STD_LOGIC_VECTOR (16 DOWNTO 1);
  signal stop_search : STD_LOGIC;
  signal stop_searchff : STD_LOGIC_VECTOR (4 DOWNTO 1);
  
  signal bb_shift : errorvector;
  signal bb_search : errorvector;
  signal shift_multiplynode : errorvector;
  signal shift_multiplyff : errorvector;
  signal search_multiplynode : errorvector;
  signal search_multiplyff : errorvector;
  signal search_multiplymux : errorvector;
 
  signal adder_one, adder_two, adder_thr, adder_for, adder_fiv : addertype;
  signal adder_six : lastaddertype;
  signal adder_oneff, adder_twoff, adder_thrff : STD_LOGIC_VECTOR (m_bits DOWNTO 1); 
  signal adder_forff, adder_fivff, adder_sixff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal adder : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal adderff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal adderzero : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal errorfound : STD_LOGIC;
  signal errorfoundff : STD_LOGIC_VECTOR (3 DOWNTO 1);
    
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
  
  component bchp_shift_search 
  GENERIC (shiftindex : integer := 1);
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        error_base : IN errorvector; 
      
		    error_found : OUT STD_LOGIC
		   );
	END component;
  
BEGIN

  prc_main: PROCESS (sysclk)
  BEGIN
    
    
      
    IF (rising_edge(sysclk)) THEN

      IF (reset = '1') THEN
      
      do_searchff <= '0';
      searchcountff <= conv_std_logic_vector(0,16);
      start_searchff <= '0';
      stop_searchff <= "0000";

      ELSE
     
      IF (enable = '1') THEN
       
        start_searchff <= start_search;
      
        IF (start_search = '1') THEN
          do_searchff <= '1';
        ELSIF (stop_search = '1') THEN
          do_searchff <= '0';  
        END IF;
      
        IF (start_search = '1') THEN
          searchcountff <= conv_std_logic_vector(0,16);
        ELSIF (do_searchff = '1' AND stop_search = '0') THEN
          searchcountff <= searchcountff + 1;
        END IF;
    
        stop_searchff(1) <= stop_search;
        stop_searchff(2) <= stop_searchff(1);
        stop_searchff(3) <= stop_searchff(2);
        stop_searchff(4) <= stop_searchff(3);
      
      END IF;

      END IF;
      
    END IF;
    
  END PROCESS;
  
  prc_count_check: PROCESS (searchcountff)
  BEGIN
    
    IF (searchcountff = stopnumber) THEN
      stop_search <= '1';
    ELSE
      stop_search <= '0';
    END IF;
    
  END PROCESS;

  gen_noshiftbd_one: IF (index = 0) GENERATE
    gen_noshiftbd_two: FOR k IN 1 TO t_symbols GENERATE 
      bb_shift(k)(m_bits DOWNTO 1) <= conv_std_logic_vector(0,m_bits); 
      shift_multiplynode(k)(m_bits DOWNTO 1) <= errorlocator(k)(m_bits DOWNTO 1); 
    END GENERATE;
  END GENERATE;
  
  gen_shiftbd_one: IF (index > 0) GENERATE
    gen_shiftbd_two: FOR k IN 1 TO t_symbols GENERATE
      bb_shift(k)(m_bits DOWNTO 1) <= conv_std_logic_vector(powernum(k*index mod field_index),m_bits);
      csma: rsp_gf_mul
      GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
      PORT MAP (aa=>errorlocator(k)(m_bits DOWNTO 1),
                bb=>bb_shift(k)(m_bits DOWNTO 1),
                cc=>shift_multiplynode(k)(m_bits DOWNTO 1));
    END GENERATE;
  END GENERATE;

  gen_searchbd_mul: FOR k IN 1 TO t_symbols GENERATE
    bb_search(k)(m_bits DOWNTO 1) <= conv_std_logic_vector(powernum(k*parallel_bits mod field_index),m_bits);
    csma: rsp_gf_mul
    GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
    PORT MAP (aa=>search_multiplyff(k)(m_bits DOWNTO 1),
              bb=>bb_search(k)(m_bits DOWNTO 1),
              cc=>search_multiplynode(k)(m_bits DOWNTO 1));
  END GENERATE;
        
  prc_mult: PROCESS (sysclk)
  BEGIN
            
    IF (rising_edge(sysclk)) THEN

      IF (reset = '1') THEN
      
      FOR k IN 1 TO t_symbols LOOP
        FOR j IN 1 TO m_bits LOOP
          shift_multiplyff(k)(j) <= '0';
          search_multiplyff(k)(j) <= '0';
        END LOOP;
      END LOOP;  
      adder_oneff <= conv_std_logic_vector (0,m_bits);
      adder_twoff <= conv_std_logic_vector (0,m_bits);
      adder_thrff <= conv_std_logic_vector (0,m_bits);
      adder_forff <= conv_std_logic_vector (0,m_bits);
      adder_fivff <= conv_std_logic_vector (0,m_bits);
      adder_sixff <= conv_std_logic_vector (0,m_bits);
      adderff <= conv_std_logic_vector (0,m_bits);
      errorfoundff <= "000";
      

      ELSIF (enable = '1') THEN

        FOR k IN 1 TO t_symbols LOOP
          shift_multiplyff(k)(m_bits DOWNTO 1) <= shift_multiplynode(k)(m_bits DOWNTO 1);
        END LOOP;
        
        FOR j IN 1 TO t_symbols LOOP
          FOR k IN 1 TO m_bits LOOP
            search_multiplyff(j)(k) <= search_multiplymux(j)(k);
          END LOOP;
        END LOOP;
        
        adder_oneff <= adder_one(adder_elements)(m_bits DOWNTO 1);
        adder_twoff <= adder_two(adder_elements)(m_bits DOWNTO 1);
        adder_thrff <= adder_thr(adder_elements)(m_bits DOWNTO 1);
        adder_forff <= adder_for(adder_elements)(m_bits DOWNTO 1);
        adder_fivff <= adder_fiv(adder_elements)(m_bits DOWNTO 1);
        adder_sixff <= adder_six(last_adder_elements)(m_bits DOWNTO 1);
        adderff <= adder;
        
        errorfoundff(1) <= errorfound AND NOT(stop_searchff(3));
        errorfoundff(2) <= errorfoundff(1);
        errorfoundff(3) <= errorfoundff(2);
        
      END IF; 
              
    END IF;
    
  END PROCESS;
  
  gen_power_one: IF (power_save = 0) GENERATE
    gen_power_two: FOR j IN 1 TO t_symbols GENERATE
      gen_power_thr: FOR k IN 1 TO m_bits GENERATE
            search_multiplymux(j)(k) <= (shift_multiplyff(j)(k) AND start_searchff) OR
                                        (search_multiplynode(j)(k) AND NOT(start_searchff));
          END GENERATE;
        END GENERATE;
  END GENERATE;
  gen_powersave_one: IF (power_save = 1) GENERATE
    gen_powersave_two: FOR j IN 1 TO t_symbols GENERATE
      gen_powersave_thr: FOR k IN 1 TO m_bits GENERATE
            search_multiplymux(j)(k) <= (shift_multiplyff(j)(k) AND start_searchff) OR
                                        (search_multiplynode(j)(k) AND NOT(start_searchff) AND NOT(stop_searchff(1)));
          END GENERATE;
        END GENERATE;
  END GENERATE;      
  
  gen_addone_one: FOR k IN 1 TO m_bits GENERATE
    adder_one(1)(k) <= search_multiplyff(1)(k);
    gen_addone_two_gate: IF adder_elements > 1 GENERATE
    gen_addone_two: FOR j IN 2 TO adder_elements GENERATE
      adder_one(j)(k) <= adder_one(j-1)(k) XOR search_multiplyff(j)(k);
    END GENERATE;
    END GENERATE;
  END GENERATE;
  
  gen_addtwo_one: FOR m IN 1 TO m_bits GENERATE
    adder_two(1)(m) <= search_multiplyff(adder_elements+1)(m);
    gen_addtwo_two_gate: IF adder_elements > 1 GENERATE
    gen_addtwo_two: FOR k IN 2 TO adder_elements GENERATE
      adder_two(k)(m) <= adder_two(k-1)(m) XOR search_multiplyff(adder_elements+k)(m);
    END GENERATE;
    END GENERATE;
  END GENERATE;
  
  gen_addthr_one: FOR m IN 1 TO m_bits GENERATE
    adder_thr(1)(m) <= search_multiplyff(2*adder_elements+1)(m);
    gen_addthr_two_gate: IF adder_elements > 1 GENERATE
    gen_addthr_two: FOR k IN 2 TO adder_elements GENERATE
      adder_thr(k)(m) <= adder_thr(k-1)(m) XOR search_multiplyff(2*adder_elements+k)(m);
    END GENERATE;
    END GENERATE;
  END GENERATE;  
  
  gen_addfor_one: FOR m IN 1 TO m_bits GENERATE
    adder_for(1)(m) <= search_multiplyff(3*adder_elements+1)(m);
    gen_addfor_two_gate: IF adder_elements > 1 GENERATE
    gen_addfor_two: FOR k IN 2 TO adder_elements GENERATE
      adder_for(k)(m) <= adder_for(k-1)(m) XOR search_multiplyff(3*adder_elements+k)(m);
    END GENERATE;
    END GENERATE;
  END GENERATE;   
  
  gen_addfiv_one: FOR m IN 1 TO m_bits GENERATE
    adder_fiv(1)(m) <= search_multiplyff(4*adder_elements+1)(m);
    gen_addfiv_two_gate: IF adder_elements > 1 GENERATE
    gen_addfiv_two: FOR k IN 2 TO adder_elements GENERATE
      adder_fiv(k)(m) <= adder_fiv(k-1)(m) XOR search_multiplyff(4*adder_elements+k)(m);
    END GENERATE;
    END GENERATE;
  END GENERATE;   
    
  gen_addsix_one: FOR m IN 1 TO m_bits GENERATE
    adder_six(1)(m) <= search_multiplyff(5*adder_elements+1)(m);
    gen_addsix_two_gate: IF last_adder_elements > 1 GENERATE
    gen_addsix_two: FOR k IN 2 TO last_adder_elements GENERATE
      adder_six(k)(m) <= adder_six(k-1)(m) XOR search_multiplyff(5*adder_elements+k)(m);
    END GENERATE;
    END GENERATE;
  END GENERATE;     

  gen_addsum: FOR m IN 1 TO m_bits GENERATE
    adder(m) <= adder_oneff(m) XOR adder_twoff(m) XOR adder_thrff(m) XOR 
                adder_forff(m) XOR adder_fivff(m) XOR adder_sixff(m);
  END GENERATE;  
          
  adderzero(1) <= NOT(adderff(1));
  gen_adder_zero: FOR k IN 2 TO m_bits GENERATE
    adderzero(k) <= adderzero(k-1) OR adderff(k);
  END GENERATE;
  errorfound <= NOT(adderzero(m_bits));
  
  gen_shift_search: FOR k IN 2 TO parallel_searchbits GENERATE
    comp_ss: bchp_shift_search
    GENERIC MAP (shiftindex=>k-1) 
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
              error_base=>search_multiplyff,
              error_found=>error_found(k));
	END GENERATE;
	
  error_found(1) <= errorfoundff(3);
  done <= stop_searchff(4);
                  
END rtl;

