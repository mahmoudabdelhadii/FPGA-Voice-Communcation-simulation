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
--***   RSX_SYNDROME_POLY                         ***
--***                                             ***
--***   Function: Calculate a specified Syndrome  ***
--***   in Received Group                         ***
--***                                             ***
--***   02/14/10 ML                               ***
--***                                             ***
--***   (c) 2012 Altera Corporation               ***
--***                                             ***
--***   Change History                            ***
--***                                             ***
--***   08/08/13 - use rsx_poly_dot vector        ***
--***                                             ***
--***                                             ***
--***                                             ***
--***************************************************

-- when n%p = 0
ENTITY rsx_syndrome_poly IS 
GENERIC (startpower : positive := 1);
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      load : IN STD_LOGIC;
      symbols : IN symbol_in_syndromevector;
      modulo : IN STD_LOGIC;
    
      syndrome : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
      synvalid : OUT STD_LOGIC
         );
END rsx_syndrome_poly;

ARCHITECTURE rtl OF rsx_syndrome_poly IS

  -- control process
  signal loadff : STD_LOGIC_VECTOR (5 DOWNTO 1);

  signal moduloff : STD_LOGIC_VECTOR (5 DOWNTO 1);
  signal zero_accumulator : STD_LOGIC;
  
  signal dotproduct : STD_LOGIC_VECTOR (m_bits DOWNTO 1);

  signal accumulateff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal syndromeff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);

  signal mulshiftvalue : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal accumulatenode : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal syndromenode : STD_LOGIC_VECTOR (m_bits DOWNTO 1);

  component rsx_poly_dot 
  GENERIC (startpower : positive := 1);
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        symbols : IN symbol_in_syndromevector;
    
        dotproduct : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
        );
   end component;
   
component rsp_gf_mul 
  GENERIC (
           polynomial : positive := 285;
           m_bits : positive := 8
          );  
  PORT (
        aa, bb : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

        cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
       );
  end component;
  
component rsp_gf_mulx
  GENERIC (
         polynomial : positive := 285;
         m_bits : positive := 8
        );
  PORT (
      aa, bb : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

      cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
         );
end component;

    component rsp_gf_add  
  GENERIC (m_bits : positive := 8);
  PORT (
        aa, bb : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

            cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
           );
  end component;
             
BEGIN
  
  prc_ctl: PROCESS (sysclk,reset)
  BEGIN
    
    IF (reset = '1') THEN

      loadff <= "00000";
      moduloff <= "00000";
      
    ELSIF (rising_edge(sysclk)) THEN
  
      IF (enable = '1') THEN
          
        loadff(1) <= load;
        FOR k IN 2 TO 5 LOOP
          loadff(k) <= loadff(k-1);
        END LOOP;
                
        moduloff(1) <= modulo AND load;
        FOR k IN 2 TO 5 LOOP
          moduloff(k) <= moduloff(k-1);
        END LOOP;
        
      END IF;
      
    END IF;
  
  END PROCESS;


  zero_accumulator <= moduloff(2);

  -- 3 pipeline stages
  comp_ppc: rsx_poly_dot 
  GENERIC MAP (startpower=>startpower)
  PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
            symbols=>symbols,
            dotproduct=>dotproduct); 

  prc_dp: PROCESS (sysclk,reset)
  BEGIN
    
    IF (reset = '1') THEN
    
      accumulateff <= conv_std_logic_vector (0,m_bits);
      syndromeff <= conv_std_logic_vector (0,m_bits);
      
    ELSIF (rising_edge(sysclk)) THEN
  
      IF (enable = '1') THEN
        
        IF (loadff(2) = '1') THEN
          FOR k IN 1 TO m_bits LOOP
            accumulateff(k) <= (accumulatenode(k) AND NOT(zero_accumulator));
          END LOOP;
        END IF;

        IF (moduloff(2) = '1') THEN
          syndromeff <= syndromenode;
        END IF;
        
      END IF;
      
    END IF;
  
  END PROCESS;
  
  comp_plus: rsp_gf_add
  GENERIC MAP (m_bits=>m_bits)
  PORT MAP (aa=>dotproduct,bb=>accumulateff,
            cc=>syndromenode);
                   
  mulshiftvalue <= conv_std_logic_vector (powernum(startpower*parallel_symbols_per_channel mod field_modulo),m_bits);
  
  -- comp_mul: rsp_gf_mul 
  -- GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  -- PORT MAP (aa=>syndromenode,bb=>mulshiftvalue,
            -- cc=>accumulatenode);
            
  comp_mul: rsp_gf_mulx 
  GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  PORT MAP (aa=>syndromenode,bb=>mulshiftvalue,
            cc=>accumulatenode);
            
  -- OUTPUTS
  syndrome <= syndromeff; 
  synvalid <= moduloff(3);          

END rtl;


