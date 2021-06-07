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
--***   rsx_bm_offset                            ***
--***                                             ***
--***   Function: Calculate Error Evaluator       ***
--***   Polynomial                                ***
--***                                             ***
--***   06/12/10 ML                               ***
--***                                             ***
--***   (c) 2010 Altera Corporation               ***
--***                                             ***
--***   Change History                            ***
--***                                             ***
--***                                             ***
--***                                             ***
--***                                             ***
--***                                             ***
--***************************************************

ENTITY rsx_bm_fifo IS 
PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        start : IN STD_LOGIC; -- start this stage
        omegain : IN errorvector;
        bdsin : IN errorvector;
        errorsin : IN STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
        
        bdsout : OUT chien_in_vector;
        omegaout : OUT chien_in_vector;
        errorsout : OUT nb_errors_type;
        done : OUT STD_LOGIC
		);
END rsx_bm_fifo;

ARCHITECTURE rtl OF rsx_bm_fifo IS

  signal bdsff : chien_in_vector;
  signal omegaff : chien_in_vector;
  signal errorsff : nb_errors_type;

  signal load_data : STD_LOGIC;
  signal finish : STD_LOGIC;
  signal validff : STD_LOGIC_VECTOR (channel DOWNTO 1);
  

BEGIN
--*******************
--***    FIFO     ***
--*******************
psma: PROCESS (sysclk,reset)
BEGIN

  IF (reset = '1') THEN    
  
    FOR k IN 1 TO channel LOOP
      FOR j IN 1 TO error_symbols LOOP
        bdsff(k)(j) <=  conv_std_logic_vector (0,m_bits);
        omegaff(k)(j) <=  conv_std_logic_vector (0,m_bits);
      END LOOP;
      errorsff(k)(errorcnt_width DOWNTO 1) <= conv_std_logic_vector (0,errorcnt_width); 
      validff(k) <= '0';      
    END LOOP;
    load_data <= '0';

    
    
  ELSIF (rising_edge(sysclk)) THEN
    
    IF (enable = '1') THEN

      IF (start = '1') THEN
        load_data <= '1';
      ELSIF (finish = '1') THEN
        load_data <= '0';
      END IF;
      
      IF (start = '1') THEN  
        IF (load_data = '0' OR finish ='1') THEN
          validff <= '1' & conv_std_logic_vector (0,channel-1);
        ELSE
          validff(channel) <= '1';
          FOR k IN 1 TO channel-1 LOOP
            validff(k) <= validff(k+1);
          END LOOP;
        END IF;
      ELSIF (finish ='1') THEN
        validff <= conv_std_logic_vector (0,channel);
      END IF;
      
      
      IF (start = '1') THEN   
        errorsff(channel)(errorcnt_width DOWNTO 1) <= errorsin(errorcnt_width DOWNTO 1);
        FOR k IN 1 TO channel-1 LOOP
          errorsff(k)(errorcnt_width DOWNTO 1) <= errorsff(k+1)(errorcnt_width DOWNTO 1);
        END LOOP;
      END IF;
      
      FOR k IN 1 TO bm_symbols LOOP
        IF (start = '1') THEN
          bdsff(channel)(k)(m_bits DOWNTO 1) <= bdsin(k)(m_bits DOWNTO 1);
          omegaff(channel)(k)(m_bits DOWNTO 1) <= omegain(k)(m_bits DOWNTO 1);     
          FOR i IN 1 TO channel-1 LOOP
            bdsff(i)(k)(m_bits DOWNTO 1) <= bdsff(i+1)(k)(m_bits DOWNTO 1);
            omegaff(i)(k)(m_bits DOWNTO 1) <= omegaff(i+1)(k)(m_bits DOWNTO 1);
          END LOOP;
        END IF;
      END LOOP;
      
    END IF;
  
  END IF;
    
END PROCESS;
finish <= validff(1);

  
--***************
--*** OUTPUTS ***
--***************

 bdsout<= bdsff; 
 omegaout <= omegaff;
 errorsout <= errorsff;
 done <= finish;

END rtl;
  
 
