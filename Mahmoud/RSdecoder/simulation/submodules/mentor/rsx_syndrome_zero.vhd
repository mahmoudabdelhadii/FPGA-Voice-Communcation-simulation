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

--***************************************************
--***                                             ***
--***   ALTERA REED SOLOMON LIBRARY               ***
--***                                             ***
--***   RSX_SYNDROME_ZERO                         ***
--***                                             ***
--***   Function: Calculate First Syndrome in     ***
--***   Received Group                            ***
--***                                             ***
--***   02/14/10 ML                               ***
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

ENTITY rsx_syndrome_zero IS 
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      load : IN STD_LOGIC;
      symbols : IN symbol_in_syndromevector;
      modulo : IN STD_LOGIC;
    
      syndrome : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
      synvalid : OUT STD_LOGIC
         );
END rsx_syndrome_zero;

ARCHITECTURE rtl OF rsx_syndrome_zero IS

  signal pp: symbol_in_syndromevector;
  signal addvector : symbol_in_syndromevector;
  
  signal symbolsff : symbol_in_syndromevector;
  signal loadff : STD_LOGIC_VECTOR (2 DOWNTO 1);
  signal multiplyvector : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal multiplyvectorff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal accumulatenode : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal accumulateff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal syndromenode : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal syndromeff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal sumvector : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  signal moduloff : STD_LOGIC_VECTOR (5 DOWNTO 1);

    component rsp_gf_add
  GENERIC (m_bits : positive := 8);
  PORT (
        aa, bb : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

             cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
            );
  end component;
             
BEGIN

  prc_main: PROCESS (sysclk,reset)
  BEGIN
    
    IF (reset = '1') THEN
    
      loadff <= "00";
      FOR k IN 1 TO parallel_symbols_per_channel LOOP
        FOR j IN 1 TO m_bits LOOP
          symbolsff(k)(j) <= '0';
        END LOOP;
      END LOOP;
      FOR k IN 1 TO m_bits LOOP
        multiplyvectorff(k) <= '0';
        accumulateff(k) <= '0';
        syndromeff(k) <= '0';
      END LOOP;
      
    ELSIF (rising_edge(sysclk)) THEN
  
      IF (enable = '1') THEN
      
        loadff(1) <= load;
        loadff(2) <= loadff(1);
        
        FOR k IN 1 TO parallel_symbols_per_channel LOOP
          symbolsff(k)(m_bits DOWNTO 1) <= symbols(k)(m_bits DOWNTO 1);
        END LOOP;
        
        IF (loadff(1) = '1') THEN
          multiplyvectorff <= multiplyvector;
        END IF;
        
        IF (loadff(2) = '1') THEN
          FOR k IN 1 TO m_bits LOOP
            accumulateff(k) <= (accumulatenode(k) AND NOT(moduloff(2)));
          END LOOP;
        END IF;
        
        IF (moduloff(2) = '1') THEN
          syndromeff(m_bits DOWNTO 1) <= syndromenode;
        END IF;
      
      END IF;
      
    END IF;
  
  END PROCESS;

  prc_ctl: PROCESS (sysclk,reset)
  BEGIN
    
    IF (reset = '1') THEN

      moduloff <= "00000";
      
    ELSIF (rising_edge(sysclk)) THEN
  
      IF (enable = '1') THEN
        
        moduloff(1) <= modulo AND load;
        moduloff(2) <= moduloff(1);
        moduloff(3) <= moduloff(2);
        moduloff(4) <= moduloff(3);
        moduloff(5) <= moduloff(4);
        
      END IF;
      
    END IF;
  
  END PROCESS;
     
  gen_mul_one: FOR k IN 1 TO parallel_symbols_per_channel GENERATE
    pp(k)(m_bits DOWNTO 1) <= symbolsff(k)(m_bits DOWNTO 1);
  END GENERATE;
  
  addvector(1)(m_bits DOWNTO 1) <= pp(1)(m_bits DOWNTO 1);
  gen_add_one: FOR k IN 2 TO parallel_symbols_per_channel GENERATE
    gen_add_two: FOR j IN 1 TO m_bits GENERATE
      addvector(k)(j) <= addvector(k-1)(j) XOR pp(k)(j);
    END GENERATE;
  END GENERATE;

  multiplyvector <= addvector(parallel_symbols_per_channel)(m_bits DOWNTO 1);

  comp_plus: rsp_gf_add
  GENERIC MAP (m_bits=>m_bits)
  PORT MAP (aa=>multiplyvectorff,bb=>accumulateff,
            cc=>sumvector);
    
  accumulatenode <= sumvector;     

  syndromenode <= sumvector;
      
  -- OUTPUTS
  
  syndrome <= syndromeff(m_bits DOWNTO 1); 
  synvalid <= moduloff(3);          

END rtl;


