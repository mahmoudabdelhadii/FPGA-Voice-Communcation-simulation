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
--***   RSX_SEARCH                                ***
--***                                             ***
--***   Function: Top Level Chien Search and      ***
--***   Error Calculation                         ***
--***                                             ***
--***   Single or Multiple Groups                 ***
--***                                             ***
--***   08/08/13 ML                               ***
--***                                             ***
--***   (c) 20103 Altera Corporation              ***
--***                                             ***
--***   Change History                            ***
--***                                             ***
--***                                             ***
--***                                             ***
--***                                             ***
--***                                             ***
--***************************************************

--*** TODO: If "number_cores = 1" (single group)  ***
--*** xtype will have negative array size         ***

ENTITY rsx_search IS 
GENERIC (
         stopnumber : integer := 127;
         index : integer := 1  -- index is 1,2,3,4,5 
        );
PORT (
          sysclk, reset, enable : IN STD_LOGIC;
          start : IN STD_LOGIC;
          bd      : IN chien_in_vector;
          omega   : IN chien_in_vector;
      
          error_found : OUT STD_LOGIC_VECTOR (parallel_symbols DOWNTO 1);
          number_errors : OUT nb_errors_type;
          error_correct : OUT parallelvector;
          can_read_fifo : OUT STD_LOGIC;
          last_check : OUT STD_LOGIC;
          first_check : OUT STD_LOGIC;
          valid : OUT STD_LOGIC
         );
END rsx_search;

ARCHITECTURE rtl OF rsx_search IS

  type lastsearchvectorch IS ARRAY (number_cores DOWNTO 1) OF lastsearchvector;
  type xtype IS ARRAY (number_cores_per_channel-1 DOWNTO 1) OF searchvector;
  type xtypech IS ARRAY (number_cores DOWNTO 1) OF xtype;

  type invvalidtype_thr IS ARRAY (number_cores DOWNTO 1) OF STD_LOGIC_VECTOR (last_searchsymbols DOWNTO 1);
  type invvalidtype_two0 IS ARRAY (number_cores_per_channel-1 DOWNTO 1) OF STD_LOGIC_VECTOR (parallel_searchsymbols DOWNTO 1);
  type invvalidtype_two IS ARRAY (number_cores DOWNTO 1) OF invvalidtype_two0;

  type count_ones_type IS ARRAY (number_cores DOWNTO 1) OF STD_LOGIC_VECTOR (parallel_symbols_per_channel DOWNTO 1);
  type ecctype IS ARRAY (number_cores DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type logicchttype IS ARRAY (number_cores DOWNTO 1) OF STD_LOGIC_VECTOR (number_cores_per_channel DOWNTO 1);
  
  signal nodetwo : xtypech;
  signal nodethr : lastsearchvectorch;
  signal value_of_inv : inv_alpha_type;  
  signal value_of_inv_two : xtypech;  
  signal value_of_inv_thr : lastsearchvectorch;  
  signal get_inv_of : inv_alpha_type;  
  signal get_inv_of_two : xtypech;  
  signal get_inv_of_thr : lastsearchvectorch;
  signal get_inv_of_valid : STD_LOGIC_VECTOR (nbinvmax DOWNTO 1);
  signal get_inv_of_valid_two : invvalidtype_two; 
  signal get_inv_of_valid_thr : invvalidtype_thr;
  
  signal count_these_ones :  count_ones_type;
  signal start_count_these_ones :  logicchttype;
  signal first_check0 :  logicchttype;
  signal last_check0 :  logicchttype;
  signal chien_ready :  logicchttype;
  signal can_read_fifo0 :  STD_LOGIC_VECTOR (number_cores DOWNTO 1);
  signal valid0 :  STD_LOGIC_VECTOR (number_cores DOWNTO 1);
  
  signal  bdff, bdin      : chien_in_vector;
  signal  omegaff,omegain   : chien_in_vector;
  
  
  component rsx_count_errors IS 
  PORT (
          sysclk, reset, enable : IN STD_LOGIC;
          start : IN STD_LOGIC;
          count_these_ones : IN STD_LOGIC_VECTOR (parallel_symbols_per_channel DOWNTO 1);
          nb_errors : OUT STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1)
        );
  end component;
  component rsx_searches 
  GENERIC (
           stopnumber : integer := 127;
           index : integer := 1  -- index is 1,2,3,4,5 
          );
  PORT (
            sysclk, reset, enable : IN STD_LOGIC;
            start : IN STD_LOGIC;
            bd : IN errorvector;
            omega : IN errorvector;
            error_found : OUT STD_LOGIC_VECTOR (parallel_searchsymbols DOWNTO 1);
            count_these_ones : OUT STD_LOGIC_VECTOR (parallel_searchsymbols DOWNTO 1);
            start_count_these_ones : OUT STD_LOGIC;
            error_correct : OUT searchvector;
            can_read_fifo : OUT STD_LOGIC;
            last_check : OUT STD_LOGIC;
            first_check : OUT STD_LOGIC;
            valid : OUT STD_LOGIC;
            chien_ready : OUT STD_LOGIC;
            value_of_inv : IN searchvector;
            get_inv_of_valid : OUT STD_LOGIC_VECTOR (parallel_searchsymbols DOWNTO 1);
            get_inv_of : OUT searchvector
           );
  end component;
  
  component rsx_searcheslast 
  GENERIC (
           stopnumber : integer := 127;
           index : integer := 1  -- index is 1,2,3,4,5 
          );
  PORT (
            sysclk, reset, enable : IN STD_LOGIC;
            start : IN STD_LOGIC;
            bd : IN errorvector;
            omega : IN errorvector;
            
            error_found : OUT STD_LOGIC_VECTOR (last_searchsymbols DOWNTO 1);
            count_these_ones : OUT STD_LOGIC_VECTOR (last_searchsymbols DOWNTO 1);
            start_count_these_ones : OUT STD_LOGIC;
            error_correct : OUT lastsearchvector;
            can_read_fifo : OUT STD_LOGIC;
            last_check : OUT STD_LOGIC;
            first_check : OUT STD_LOGIC;
            valid : OUT STD_LOGIC;
            chien_ready : OUT STD_LOGIC;
            value_of_inv : IN lastsearchvector;
            get_inv_of_valid : OUT STD_LOGIC_VECTOR (last_searchsymbols DOWNTO 1);
            get_inv_of : OUT lastsearchvector
           );
  end component;
  
  component rsx_inverse_ROM
  GENERIC (
         nb_input : integer := 10
        );
  PORT (
         sysclk: IN STD_LOGIC;
         reset : IN STD_LOGIC;
         enable : IN STD_LOGIC;
         alpha : IN inv_alpha_type;
         read_enable : IN STD_LOGIC_VECTOR (nbinvmax DOWNTO 1);
         inverse_of_alpha : OUT inv_alpha_type
        );
  end component;
  
  
BEGIN
 
  in_nodech0 : IF (channel> 1) GENERATE
  
    prc_fifoin: PROCESS (sysclk,reset)
    BEGIN 
      IF (reset = '1') THEN
        FOR i IN 1 TO channel LOOP
          FOR k IN 1 TO bm_symbols LOOP
            FOR j IN 1 TO m_bits LOOP
              bdff(i)(k)(j) <= '0';
              omegaff(i)(k)(j) <= '0';
            END LOOP;
          END LOOP;  
        END LOOP;           
      ELSIF (rising_edge(sysclk)) THEN
        IF (start = '1') THEN
          FOR i IN 1 TO channel LOOP
            FOR k IN 1 TO bm_symbols LOOP
              bdff(i)(k) <= bd(i)(k);
              omegaff(i)(k) <= omega(i)(k);
            END LOOP;  
          END LOOP; 
        END IF;
      END IF;
    END PROCESS;
  
    prc_fifoinnode: PROCESS (start,bd,omega)
    BEGIN
      IF (start = '1') THEN
        FOR i IN 1 TO channel LOOP
          FOR k IN 1 TO bm_symbols LOOP
            bdin(i)(k) <= bd(i)(k);
            omegain(i)(k) <= omega(i)(k);
          END LOOP;  
        END LOOP; 
      ELSE
        FOR i IN 1 TO channel LOOP
          FOR k IN 1 TO bm_symbols LOOP
            bdin(i)(k) <= bdff(i)(k);
            omegain(i)(k) <= omegaff(i)(k);
          END LOOP;  
        END LOOP; 
      END IF;
    END PROCESS;
  END GENERATE;
  
  in_nodech1 : IF (channel = 1) GENERATE
    loopi: FOR i IN 1 TO channel GENERATE
      loopk: FOR k IN 1 TO bm_symbols GENERATE
        bdin(i)(k) <= bd(i)(k);
        omegain(i)(k) <= omega(i)(k);
      END GENERATE;  
    END GENERATE; 
  END GENERATE;
  
  
  gen_loop: FOR i IN 1 TO number_cores GENERATE
  
    gen_loop: FOR k IN 1 TO (number_cores_per_channel-1) GENERATE
      comp_core_loop: rsx_searches
      GENERIC MAP (stopnumber=>stopnumber,index=>index+(k-1)*parallel_searchsymbols)
      PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
                start=>start,bd=>bdin(i),omega=>omegain(i),
                error_found=>error_found(parallel_symbols_per_channel*(i-1)+parallel_searchsymbols*k DOWNTO parallel_symbols_per_channel*(i-1)+parallel_searchsymbols*(k-1)+1),
                count_these_ones=>count_these_ones(i)(parallel_searchsymbols*k DOWNTO parallel_searchsymbols*(k-1)+1),
                start_count_these_ones=>start_count_these_ones(i)(k),
                first_check=>first_check0(i)(k),
                chien_ready=>chien_ready(i)(k),
                error_correct=>nodetwo(i)(k),
                get_inv_of=>get_inv_of_two(i)(k),
                get_inv_of_valid=>get_inv_of_valid_two(i)(k),  
                value_of_inv=>value_of_inv_two(i)(k),
                last_check=>last_check0(i)(k));
    END GENERATE;
    
    comp_core_last: rsx_searcheslast
    GENERIC MAP (stopnumber=>stopnumber,index=>index+(number_cores_per_channel-1)*parallel_searchsymbols)
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
              start=>start,bd=>bdin(i),omega=>omegain(i),
              error_found=>error_found(parallel_symbols_per_channel*(i-1)+parallel_symbols_per_channel DOWNTO parallel_symbols_per_channel*(i-1)+parallel_symbols_per_channel-last_searchsymbols+1),
              count_these_ones=>count_these_ones(i)(parallel_symbols_per_channel DOWNTO parallel_symbols_per_channel-last_searchsymbols+1),
              can_read_fifo=>can_read_fifo0(i),
              valid => valid0(i),
              start_count_these_ones=>start_count_these_ones(i)(number_cores_per_channel),
              first_check=>first_check0(i)(number_cores_per_channel),
              last_check=>last_check0(i)(number_cores_per_channel),
              chien_ready=>chien_ready(i)(number_cores_per_channel),
              get_inv_of=>get_inv_of_thr(i),
              get_inv_of_valid=>get_inv_of_valid_thr(i),
              value_of_inv=>value_of_inv_thr(i),
              error_correct=>nodethr(i));    


    gen_out_for: FOR i IN 1 TO number_cores GENERATE
      gen_out_for: FOR k IN 1 TO number_cores_per_channel-1 GENERATE
        gen_out_fiv: FOR j IN 1 TO parallel_searchsymbols GENERATE 
          error_correct((i-1)*parallel_symbols_per_channel+(k-1)*parallel_searchsymbols+j)(m_bits DOWNTO 1) <= nodetwo(i)(k)(j)(m_bits DOWNTO 1);
          get_inv_of((i-1)*parallel_symbols_per_channel+(k-1)*parallel_searchsymbols+j) <= get_inv_of_two(i)(k)(j);
          get_inv_of_valid((i-1)*parallel_symbols_per_channel+(k-1)*parallel_searchsymbols+j) <= get_inv_of_valid_two(i)(k)(j);
          
          value_of_inv_two(i)(k)(j) <= value_of_inv((i-1)*parallel_symbols_per_channel+(k-1)*parallel_searchsymbols+j) ;
        END GENERATE;
      END GENERATE;
      gen_out_fiv: FOR j IN 1 TO last_searchsymbols GENERATE 
        error_correct((i-1)*parallel_symbols_per_channel+(number_cores_per_channel-1)*parallel_searchsymbols+j)(m_bits DOWNTO 1) <= nodethr(i)(j)(m_bits DOWNTO 1);
        get_inv_of((i-1)*parallel_symbols_per_channel+(number_cores_per_channel-1)*parallel_searchsymbols+j) <= get_inv_of_thr(i)(j);
        get_inv_of_valid((i-1)*parallel_symbols_per_channel+(number_cores_per_channel-1)*parallel_searchsymbols+j) <= get_inv_of_valid_thr(i)(j);
        
        value_of_inv_thr(i)(j) <= value_of_inv((i-1)*parallel_symbols_per_channel+(number_cores_per_channel-1)*parallel_searchsymbols+j) ;
      END GENERATE;
    END GENERATE;

-- COUNTING ERRORS (up to 192 correctable errors) 
    count_errors_up_to_192: rsx_count_errors
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
        start=>start_count_these_ones(1)(1),
        count_these_ones=>count_these_ones(i),
        nb_errors=>number_errors(i)(errorcnt_width DOWNTO 1)); 
    
    
  END GENERATE;
    
-- GENERATE THE INVERSES 
  generate_inverses: rsx_inverse_ROM
  GENERIC MAP (nb_input=>parallel_symbols)
  PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
      read_enable=>get_inv_of_valid,
      alpha=>get_inv_of,
      inverse_of_alpha=>value_of_inv); 


    first_check <= first_check0(1)(1);
    last_check <= last_check0(1)(1);
    can_read_fifo <= can_read_fifo0(1);
    valid <= valid0(1);
END rtl;

