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
--***   RSX_SEARCHESLAST                          ***
--***                                             ***
--***   Function: A group of Chien Searches and   ***
--***   Error Calculations                        ***
--***                                             ***
--***   Second and following searches in group    ***
--***   based on frequency shift                  ***
--***                                             ***
--***   Like RSX_SEARCHES but used for last group ***
--***   (last_searchsymbols size array)           ***
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

ENTITY rsx_searcheslast IS 
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
          valid : OUT STD_LOGIC;
          first_check : OUT STD_LOGIC;
          last_check : OUT STD_LOGIC;
          chien_ready : OUT STD_LOGIC;
          
          value_of_inv : IN lastsearchvector;
          get_inv_of_valid : OUT STD_LOGIC_VECTOR (last_searchsymbols DOWNTO 1);
          get_inv_of : OUT lastsearchvector
         );
END rsx_searcheslast;

ARCHITECTURE rtl OF rsx_searcheslast IS
  
  constant genstart : integer := 0;
  
  type omega_adderfftype IS ARRAY (3 DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);

  signal do_searchff : STD_LOGIC_VECTOR (7 DOWNTO 1);
  signal start_searchff : STD_LOGIC_VECTOR (7 DOWNTO 1);
  signal searchcountff : STD_LOGIC_VECTOR (m_bits DOWNTO 1); -- ideally clog2(n/par)
  signal stop_searchff : STD_LOGIC;
  
  signal bb_shift : errorvector;
  signal shift_bdnode : errorvector;
  signal shift_omeganode : errorvector;
  signal bb_search : errorvector;
  signal search_bdnode : errorvector;
  signal search_omeganode : errorvector;
  
  signal shift_bdff : errorvector;
  signal shift_omegaff : errorvector;
  signal search_bdff : errorvector;
  signal search_omegaff : errorvector; 
  signal odd_adderff : STD_LOGIC_VECTOR (m_bits DOWNTO 1); 
  signal odd_adderdelff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal errorinverse : STD_LOGIC_VECTOR (m_bits DOWNTO 1); 
  signal omega_adderff : omega_adderfftype;
  signal correctionff, correctiondelff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal errorfoundff : STD_LOGIC_VECTOR (5 DOWNTO 1);
  
  signal odd_adder : oddvector;
  signal even_adder : evenvector;
  signal adder, adderzero : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal omega_adder : errorvector;
  signal errorfound : STD_LOGIC;
  signal zero_error_found : STD_LOGIC;
  signal errorinversenode : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal correctionnode : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
            
  signal last_symbolff : STD_LOGIC_VECTOR (7 DOWNTO 1);
  signal start_requestedff : STD_LOGIC;
  signal ready_to_input : STD_LOGIC;
   
  signal count_these_ones_node : STD_LOGIC_VECTOR (last_searchsymbols-1 DOWNTO 1);   
            
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
  component rsp_gf_mulx IS 
  GENERIC (
           polynomial : positive := 285;
           m_bits : positive := 8
          );
  PORT (
        aa, bb : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1); -- bb is a constant
        cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
        );
  end component;
    
  component rsx_error_dot 
  GENERIC (shiftindex : integer := 1);
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        zero_error_found : IN STD_LOGIC;
        bd_base : IN errorvector; -- error locator polynomial, shifted for first index
        omega_base : IN errorvector; -- error evaluator polynomial, shifted for first index
        count_this_one : OUT STD_LOGIC;
        error_found : OUT STD_LOGIC;
        get_inv_of : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
        get_inv_of_valid : OUT STD_LOGIC;
        value_of_inv : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);
        error_correct : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
        );
    END component;
  
BEGIN

-- search from first rx'd symbol down to zero
-- index is from maximum length, example (255,239) = {238,237,236...0,check symbols}
-- 238 (index 254 in range 254 to 0), shift is powernum(0)

  prc_main: PROCESS (sysclk,reset)
  BEGIN
    
    IF (reset = '1') THEN
      
      searchcountff <= conv_std_logic_vector(0,m_bits);
      start_searchff <= "0000000";
      stop_searchff  <= '0';
      do_searchff <= "0000000";
      start_requestedff <= '0';
      last_symbolff <= "0000000";
      
    ELSIF (rising_edge(sysclk)) THEN
     
      IF (enable = '1') THEN
       
        start_searchff(1)  <= (ready_to_input AND (start OR start_requestedff) );
      
        IF (ready_to_input = '1' AND (start = '1' OR start_requestedff ='1') ) THEN
          do_searchff(1) <= '1';
        ELSIF (last_symbolff(1) = '1') THEN
          do_searchff(1) <= '0';  
        END IF;
        IF (ready_to_input = '1' AND (start = '1' OR start_requestedff ='1') ) THEN
          searchcountff <= conv_std_logic_vector(0,m_bits);
        ELSIF (do_searchff(1) = '1') THEN
          searchcountff <= searchcountff + 1;
        END IF;
        IF (searchcountff = stopnumber-2) THEN
          last_symbolff(1) <= '1';
        ELSE
          last_symbolff(1) <= '0';
        END IF;
        IF (start = '1' AND ready_to_input = '0') THEN
          start_requestedff <= '1';
        ELSIF (ready_to_input = '1') THEN
          start_requestedff <= '0';
        END IF;
        
        stop_searchff <= NOT(do_searchff(1));
        
        FOR j IN 2 TO 7 LOOP
          do_searchff(j) <= do_searchff(j-1);
          last_symbolff(j) <= last_symbolff(j-1);
          start_searchff(j) <= start_searchff(j-1);
        END LOOP;
      END IF;
      
    END IF;
    
  END PROCESS;
  
  ready_to_input <= last_symbolff(1) OR NOT(do_searchff(1));
  chien_ready <= ready_to_input;

    riBM_shift_bdnode : IF (riBm = 1) GENERATE
      shift_bdnode(1)(m_bits DOWNTO 1) <= bd(1)(m_bits DOWNTO 1);
    END GENERATE;
    gen_shiftbd_two: FOR k IN 1 TO error_symbols GENERATE
      bb_shift(k)(m_bits DOWNTO 1) <= conv_std_logic_vector(powernum(k*index mod field_modulo),m_bits);
      comp_bd_sft: rsp_gf_mulx
      GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
      PORT MAP (aa=>bd(k+riBm)(m_bits DOWNTO 1),
                bb=>bb_shift(k)(m_bits DOWNTO 1),
                cc=>shift_bdnode(k+riBm)(m_bits DOWNTO 1));
    END GENERATE;
    shift_omeganode(1)(m_bits DOWNTO 1) <= omega(1)(m_bits DOWNTO 1);
    gen_shiftomega: FOR k IN 1 TO error_symbols-1 GENERATE
      comp_om_sft: rsp_gf_mulx
      GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
      PORT MAP (aa=>omega(k+1)(m_bits DOWNTO 1),
                bb=>bb_shift(k)(m_bits DOWNTO 1),
                cc=>shift_omeganode(k+1)(m_bits DOWNTO 1));    
    END GENERATE;

  gen_searchbd_mul: FOR k IN 1 TO error_symbols GENERATE
    bb_search(k)(m_bits DOWNTO 1) <= conv_std_logic_vector(powernum(k*parallel_symbols_per_channel mod field_modulo),m_bits);
    comp_bd_look: rsp_gf_mulx
    GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
    PORT MAP (aa=>search_bdff(k+riBm)(m_bits DOWNTO 1),
              bb=>bb_search(k)(m_bits DOWNTO 1),
              cc=>search_bdnode(k+riBm)(m_bits DOWNTO 1));
  END GENERATE;


  search_omeganode(1)(m_bits DOWNTO 1) <= search_omegaff(1)(m_bits DOWNTO 1);--shift_omegaff(1)(m_bits DOWNTO 1);
  gen_searchom_mul: FOR k IN 1 TO error_symbols-1 GENERATE
    comp_om_look: rsp_gf_mulx
    GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
    PORT MAP (aa=>search_omegaff(k+1)(m_bits DOWNTO 1),
              bb=>bb_search(k)(m_bits DOWNTO 1),
              cc=>search_omeganode(k+1)(m_bits DOWNTO 1));
  END GENERATE;
          
  prc_mult: PROCESS (sysclk,reset)
  BEGIN
    
    IF (reset = '1') THEN
      
      FOR k IN 1 TO bm_symbols LOOP
        FOR j IN 1 TO m_bits LOOP
          shift_bdff(k)(j) <= '0';
          search_bdff(k)(j) <= '0';
          shift_omegaff(k)(j) <= '0';
          search_omegaff(k)(j) <= '0';
        END LOOP;
      END LOOP;  
      odd_adderff <= conv_std_logic_vector (0,m_bits);
      
      omega_adderff(1)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      omega_adderff(2)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      omega_adderff(3)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      correctionff <= conv_std_logic_vector (0,m_bits);
      correctiondelff <= conv_std_logic_vector (0,m_bits);
      errorfoundff <= "00000";
            
    ELSIF (rising_edge(sysclk)) THEN
      
      IF (enable = '1') THEN

        FOR k IN 1 TO bm_symbols LOOP
          shift_bdff(k)(m_bits DOWNTO 1) <= shift_bdnode(k)(m_bits DOWNTO 1);
        END LOOP;
        
        IF (riBm = 1) THEN
          FOR k IN 1 TO m_bits LOOP
            search_bdff(1)(k) <= (shift_bdff(1)(k) AND start_searchff(1)) OR
                                 (search_bdff(1)(k) AND NOT(start_searchff(1)));
          END LOOP;
        END IF;
        FOR j IN 1 TO error_symbols LOOP
          FOR k IN 1 TO m_bits LOOP
            search_bdff(j+riBm)(k) <= (shift_bdff(j+riBm)(k) AND start_searchff(1)) OR
                                 (search_bdnode(j+riBm)(k) AND NOT(start_searchff(1)));
          END LOOP;
        END LOOP;

        FOR k IN 1 TO error_symbols LOOP
          shift_omegaff(k)(m_bits DOWNTO 1) <= shift_omeganode(k)(m_bits DOWNTO 1);
        END LOOP;
        
        FOR j IN 1 TO error_symbols LOOP
          FOR k IN 1 TO m_bits LOOP
            search_omegaff(j)(k) <= (shift_omegaff(j)(k) AND start_searchff(1)) OR
                                    (search_omeganode(j)(k) AND NOT(start_searchff(1)));
          END LOOP;
        END LOOP;
        
        odd_adderff <= odd_adder(derivative_terms)(m_bits DOWNTO 1);
        
        omega_adderff(1)(m_bits DOWNTO 1) <= omega_adder(error_symbols)(m_bits DOWNTO 1);
        omega_adderff(2)(m_bits DOWNTO 1) <= omega_adderff(1)(m_bits DOWNTO 1);
        omega_adderff(3)(m_bits DOWNTO 1) <= omega_adderff(2)(m_bits DOWNTO 1);
        
        correctionff <= correctionnode;
        correctiondelff <= correctionff;
                
        -- stop search only happens on lanes past the modulo point
        errorfoundff(1) <= errorfound AND NOT(stop_searchff);
        errorfoundff(2) <= errorfoundff(1);
        errorfoundff(3) <= errorfoundff(2);
        errorfoundff(4) <= errorfoundff(3);
        errorfoundff(5) <= errorfoundff(4);
        
      END IF; 
              
    END IF;
    
  END PROCESS;
 
   gen_add_oddone: FOR m IN 1 TO m_bits GENERATE
    odd_adder(1)(m) <= search_bdff(1+riBm)(m);
    gen_add_oddtwo: FOR k IN 2 TO derivative_terms GENERATE
      odd_adder(k)(m) <= odd_adder(k-1)(m) XOR search_bdff(2*k-1+riBm)(m);
    END GENERATE;
  END GENERATE;

   gen_add_evenone: FOR m IN 1 TO m_bits GENERATE
    even_adder(1)(m) <= search_bdff(2+riBm)(m);
    gen_add_eventwo: FOR k IN 2 TO even_terms GENERATE
      even_adder(k)(m) <= even_adder(k-1)(m) XOR search_bdff(2*k+riBm)(m);
    END GENERATE;
  END GENERATE;
     
  gen_add: FOR m IN 1 TO m_bits GENERATE
    adder(m) <= odd_adder(derivative_terms)(m) XOR even_adder(even_terms)(m);
  END GENERATE;
        
  -- = adder + 1
  no_riBM_adder: IF (riBm = 0) GENERATE
    adderzero(1) <= NOT(adder(1));
    gen_adder_zero: FOR m IN 2 TO m_bits GENERATE
      adderzero(m) <= adderzero(m-1) OR adder(m);
    END GENERATE;
  END GENERATE;
  -- = adder + sigma_0
  riBM_adder: IF (riBm = 1) GENERATE
    adderzero(1) <= adder(1) XOR search_bdff(1)(1);
    gen_adder_zero: FOR m IN 2 TO m_bits GENERATE
      adderzero(m) <= adderzero(m-1) OR (adder(m) XOR search_bdff(1)(m));
    END GENERATE;
  END GENERATE;  
  errorfound <= NOT(adderzero(m_bits));
  
  gen_add_omegaone: FOR m IN 1 TO m_bits GENERATE
    omega_adder(1)(m) <= search_omegaff(1)(m);
    gen_add_omegatwo: FOR k IN 2 TO error_symbols GENERATE
      omega_adder(k)(m) <= omega_adder(k-1)(m) XOR search_omegaff(k)(m);
    END GENERATE;
  END GENERATE;
  
  gen_shift_search: FOR k IN 2 TO last_searchsymbols GENERATE
     comp_shift: rsx_error_dot
     GENERIC MAP (shiftindex=>k-1) 
     PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
               bd_base=>search_bdff,omega_base=>search_omegaff,
               zero_error_found=>zero_error_found,
               error_found=>error_found(k),
               count_this_one=>count_these_ones_node(k-1),
               get_inv_of=>get_inv_of(k),
               get_inv_of_valid=>get_inv_of_valid(k),
               value_of_inv=>value_of_inv(k),
               error_correct=>error_correct(k)(m_bits DOWNTO 1));

  END GENERATE;

  gen_bypass : IF (use_bypass =1) GENERATE
    zero_error_found <= NOT(do_searchff(6));
  END GENERATE;
  gen_no_bypass : IF (use_bypass =0) GENERATE
    zero_error_found <= '0';
  END GENERATE;
  
  
  
  get_inv_of(1) <= odd_adderff;
  get_inv_of_valid(1) <= errorfoundff(1);
  errorinverse <= value_of_inv(1);
  

  cmul: rsp_gf_mul
  GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  PORT MAP (aa=>omega_adderff(3)(m_bits DOWNTO 1),bb=>errorinverse,
            cc=>correctionnode);
            
  --*** OUTPUTS ***
  count_these_ones(last_searchsymbols DOWNTO 1) <= count_these_ones_node & errorfoundff(5-2); -- early version of error found
  start_count_these_ones <= start_searchff(5);
  
  error_found(1) <= errorfoundff(5);
  error_correct(1)(m_bits DOWNTO 1) <= correctiondelff;  
  valid <= do_searchff(7); 
  last_check <= last_symbolff(7);
  first_check <= start_searchff(7);
  can_read_fifo <= do_searchff(7-fifo_delay-1);
END rtl;

