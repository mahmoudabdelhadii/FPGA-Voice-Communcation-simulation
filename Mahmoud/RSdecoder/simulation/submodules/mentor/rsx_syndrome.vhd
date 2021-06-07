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
--***   RSX_SYNDROME                              ***
--***                                             ***
--***   Function: Calculate Syndromes (4 clocks)  ***
--***                                             ***
--***   02/14/12 ML                               ***
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

ENTITY rsx_syndrome IS 
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      load : IN STD_LOGIC;
      bm_ready : IN STD_LOGIC;
      symbols : IN parallelvector;
    
      syndromes : OUT syndromevector;
      are_syndromes_not_null : OUT STD_LOGIC_VECTOR (channel DOWNTO 1);
      synvalid : OUT STD_LOGIC
		 );
END rsx_syndrome;

ARCHITECTURE rtl OF rsx_syndrome IS

  constant modulus : integer :=  n_symbols - (n_symbols/parallel_symbols_per_channel)*parallel_symbols_per_channel;

  type counter_type IS ARRAY (check_symbols DOWNTO 1) OF STD_LOGIC_VECTOR (syndcnt_width DOWNTO 1);
  type synvalid_type IS ARRAY (channel DOWNTO 1) OF STD_LOGIC_VECTOR (check_symbols DOWNTO 1);
  attribute noprune: boolean;
  signal loadff : STD_LOGIC_VECTOR (3 DOWNTO 1);
  signal countff : counter_type;
    attribute noprune of countff: signal is true;
  signal last_input_symbol : STD_LOGIC_VECTOR (check_symbols DOWNTO 1);
    attribute noprune of last_input_symbol: signal is true;
  signal synvalidnode : synvalid_type;
  signal syndrome_symbol_input : symbol_in_syndrome;
  signal syndrome_vector_output : syndrome_out_vector;
  signal syndrome_vector_offset : syndrome_out_vector;
  signal syndrome_fifo : syndrome_out_vector;
  signal syndrome_fifo_valid : STD_LOGIC_VECTOR (channel DOWNTO 1);
  signal syndrome_is_notnull : STD_LOGIC_VECTOR (channel DOWNTO 1);
  signal syndrome_is_notnull1 : syndrome_out_vector;
  signal syndrome_is_notnull2 : synvalid_type;
  signal validff1, validff2, validffnode : STD_LOGIC;
  signal bb_offset : syndromevector;
  
  component rsp_gf_mulx IS 
  GENERIC (
           polynomial : positive := 285;
           m_bits : positive := 8
          );
  PORT (
        aa, bb : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);  -- bb is a constant
        cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
        );
  end component;
  component rsx_syndrome_zero
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        load : IN STD_LOGIC;
        modulo : IN STD_LOGIC;
        symbols : IN symbol_in_syndromevector;
    
        syndrome : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
        synvalid : OUT STD_LOGIC
		 );
  end component;
		 
  component rsx_syndrome_poly 
  GENERIC (startpower : positive := 1);
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        load : IN STD_LOGIC;
        modulo : IN STD_LOGIC;
        symbols : IN symbol_in_syndromevector;
    
        syndrome : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
        synvalid : OUT STD_LOGIC
		   );
  end component;
  
BEGIN

  prc_main: PROCESS (sysclk,reset)
  BEGIN
    
    IF (reset = '1') THEN
    
      loadff <= "000";
      FOR k IN 1 TO check_symbols LOOP 
        countff(k) <= conv_std_logic_vector (0,syndcnt_width);
      END LOOP;
      
    ELSIF (rising_edge(sysclk)) THEN
  
      IF (enable = '1' AND load = '1') THEN

        loadff(1) <= load;
        FOR k IN 2 TO 3 LOOP
          loadff(k) <= loadff(k-1);
        END LOOP;
        FOR k IN 1 TO check_symbols LOOP 
          IF (last_input_symbol(k) ='1') THEN
            countff(k) <= conv_std_logic_vector (0,syndcnt_width);
          ELSE
            countff(k) <= countff(k) + 1;
          END IF;
        END LOOP;
      END IF;
      
    END IF;
  
  END PROCESS;
  
  prc_last_symbol: PROCESS (countff,load)
  BEGIN
    FOR k IN 1 TO check_symbols LOOP 
      IF (countff(k) = codeword_clocks-1) THEN
        last_input_symbol(k) <= load;
      ELSE
        last_input_symbol(k) <= '0';
      END IF;
    END LOOP;
  END PROCESS;
  
  
  gen_syndromemodule: FOR i IN 1 TO channel GENERATE
    gen_syninput: FOR k IN 1 TO parallel_symbols_per_channel GENERATE
      syndrome_symbol_input(i)(k) <= symbols(k+(i-1)*parallel_symbols_per_channel);
    END GENERATE;  
      
    comp_synzip: rsx_syndrome_zero
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
                load=>load,
                symbols=>syndrome_symbol_input(i),
                modulo=>last_input_symbol(1),
                synvalid=>synvalidnode(i)(1),
                syndrome=>syndrome_vector_output(i)(1)(m_bits DOWNTO 1));
                   
    gen_synpoly: FOR k IN 2 TO check_symbols GENERATE
      comp_synpoly: rsx_syndrome_poly
      GENERIC MAP (startpower=>k-1)
      PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
                  load=>load,
                  symbols=>syndrome_symbol_input(i),
                  modulo=>last_input_symbol(k),
                  synvalid=>synvalidnode(i)(k),
                  syndrome=>syndrome_vector_output(i)(k)(m_bits DOWNTO 1));
        
    END GENERATE;
  END GENERATE;
  
offset_syndrome : IF (modulus> 0) GENERATE
  loop_bboffset : FOR k IN 1 TO check_symbols GENERATE
      bb_offset(k) <= conv_std_logic_vector(powernum((k-1)*(field_modulo- parallel_symbols_per_channel+modulus) mod field_modulo),m_bits);
    END GENERATE;
  loop_channel:FOR i IN 1 TO channel GENERATE
    syndrome_vector_offset(i)(1) <= syndrome_vector_output(i)(1);
    loop_check : FOR k IN 2 TO check_symbols GENERATE
      comp_om_sft: rsp_gf_mulx
      GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
      PORT MAP (aa=> syndrome_vector_output(i)(k),
                bb=> bb_offset(k),
                cc=> syndrome_vector_offset(i)(k)); 
    END GENERATE;
  END GENERATE;
END GENERATE;
no_offset_syndrome : IF (modulus= 0) GENERATE
  loop_channel:FOR i IN 1 TO channel GENERATE
    loop_check : FOR k IN 1 TO check_symbols GENERATE
      syndrome_vector_offset(i)(k) <= syndrome_vector_output(i)(k);
    END GENERATE;
  END GENERATE;
END GENERATE;  
  
  
  is_syndrome_null:FOR i IN 1 TO channel GENERATE
    
    loop_check : FOR k IN 1 TO check_symbols GENERATE
      syndrome_is_notnull1(i)(k)(1) <= syndrome_vector_output(i)(k)(1);
      loop_bit : FOR m IN 2 TO m_bits GENERATE
        syndrome_is_notnull1(i)(k)(m) <= syndrome_is_notnull1(i)(k)(m-1) OR syndrome_vector_output(i)(k)(m-1);
      END GENERATE;
    END GENERATE;
    
    syndrome_is_notnull2(i)(1) <= syndrome_is_notnull1(i)(1)(m_bits);  
    loop_check2 : FOR k IN 2 TO check_symbols GENERATE
        syndrome_is_notnull2(i)(k) <= syndrome_is_notnull2(i)(k-1) OR syndrome_is_notnull1(i)(k)(m_bits);
    END GENERATE;
    
    syndrome_is_notnull(i) <= syndrome_is_notnull2(i)(check_symbols);
  END GENERATE;
  
  gen_synd_fifo_1channel : IF (channel=1) GENERATE
    syndrome_fifo_valid(1) <= validffnode;
    syndrome_fifo(1) <= syndrome_vector_offset(1);
    prc_syndfifo: PROCESS (sysclk,reset)
    BEGIN
      IF (reset = '1') THEN
        validff1 <= '0'; 
        validff2 <= '0'; 
        are_syndromes_not_null <= conv_std_logic_vector(0,channel);
      ELSIF (rising_edge(sysclk)) THEN
        IF (enable = '1') THEN
          FOR i IN 1 TO channel LOOP 
            are_syndromes_not_null(i) <= syndrome_is_notnull(i) AND validff1;
          END LOOP;
          validff1 <= synvalidnode(1)(2);
          validff2 <= validff1;
        END IF;
      END IF;
    END PROCESS;
    
     gen_valid_withbypass : IF (use_bypass = 1) GENERATE
      validffnode <= validff2;
    END GENERATE;
    gen_valid_nobypass : IF (use_bypass = 0) GENERATE
      validffnode <= synvalidnode(1)(2);
    END GENERATE;    
    
  END GENERATE;
  
  gen_synd_fifo_xchannel : IF (channel>1) GENERATE
    prc_syndfifo: PROCESS (sysclk,reset)
    BEGIN
    
      IF (reset = '1') THEN
    
        syndrome_fifo_valid <= conv_std_logic_vector(0,channel);
        validff1 <= '0'; 
        FOR i IN 1 TO channel LOOP 
          FOR k IN 1 TO check_symbols LOOP            
            syndrome_fifo(i)(k) <= conv_std_logic_vector(0,m_bits);
          END LOOP;
        END LOOP;
        are_syndromes_not_null <= conv_std_logic_vector(0,channel);
          
      ELSIF (rising_edge(sysclk)) THEN
  
        IF (enable = '1') THEN

          IF (validffnode = '1') THEN
            FOR i IN 1 TO channel LOOP 
              FOR k IN 1 TO check_symbols LOOP  
                syndrome_fifo(i)(k) <= syndrome_vector_offset(i)(k);
              END LOOP;
              syndrome_fifo_valid(i) <= '1';
            END LOOP;
          ELSE
            IF (bm_ready = '1') THEN
              FOR k IN 1 TO check_symbols LOOP
                syndrome_fifo(channel)(k) <= conv_std_logic_vector(0,m_bits);
                FOR i IN 1 TO channel-1 LOOP 
                  syndrome_fifo(i)(k) <= syndrome_fifo(i+1)(k);
                END LOOP;
              END LOOP;
              syndrome_fifo_valid(channel) <= '0';
              FOR i IN 1 TO channel-1 LOOP 
                syndrome_fifo_valid(i) <= syndrome_fifo_valid(i+1);
              END LOOP;
            END IF;
          END IF;
        
          FOR i IN 1 TO channel LOOP 
            are_syndromes_not_null(i) <= syndrome_is_notnull(i) AND validffnode;
          END LOOP;
        validff1 <= synvalidnode(1)(2);
        
        END IF;
      
      END IF;
  
    END PROCESS;
    
     gen_valid_withbypass : IF (use_bypass = 1) GENERATE
      validffnode <= validff1;
    END GENERATE;
    gen_valid_nobypass : IF (use_bypass = 0) GENERATE
      validffnode <= synvalidnode(1)(2);
    END GENERATE;     
    
  END GENERATE;
  
  -- OUTPUTS
  syndromes <= syndrome_fifo(1);  
  synvalid <= syndrome_fifo_valid(1);      

END rtl;


