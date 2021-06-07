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
--***   RSX_OMEGA_PIPE                            ***
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

ENTITY rsx_omega_pipe IS 
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      start : IN STD_LOGIC; -- start this stage
      syndromes : IN errorvector;
      bdsin : IN errorvector;
      errorsin : IN STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);

      bdsout : OUT errorvector;
      omegaout : OUT errorvector;
      errorsout : OUT STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
      done : OUT STD_LOGIC -- start for next level
		);
END rsx_omega_pipe;

ARCHITECTURE rtl OF rsx_omega_pipe IS

  type errorsfftype IS ARRAY (4 DOWNTO 1) OF STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  type omegadelayfftype IS ARRAY (2 DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  signal syndromesff : errorvector;
  signal bdsinff, bdsoneff, bdstwoff, bdsoutff : errorvector;
  signal omegaff : errorvector;
  signal startff : STD_LOGIC_VECTOR (4 DOWNTO 1);
  signal errorsff : errorsfftype;
  signal omegaoneff, omegatwoff : omegadelayfftype;
  
  signal omeganode : errorvector;
  signal multiplytwo : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal omegaonenode, omegatwonode : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
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
  
  component rsp_gf_add
  GENERIC (m_bits : positive := 8);
  PORT (
        aa, bb : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

          cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
          );
  end component;

    component rsx_omega_vecpipe
  GENERIC (vectorsize : positive := 4);
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        syndromes : IN errorvector;
        bds : IN errorvector;

        omeganode : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
            );
    end component;
             
BEGIN

psma: PROCESS (sysclk,reset)
BEGIN

  IF (reset = '1') THEN    
  
    FOR k IN 1 TO error_symbols LOOP
      FOR j IN 1 TO m_bits LOOP
        syndromesff(k)(j) <= '0';
        bdsinff(k)(j) <= '0';
        bdsoneff(k)(j) <= '0';
        bdstwoff(k)(j) <= '0';
        bdsoutff(k)(j) <= '0';
        omegaff(k)(j) <= '0';
      END LOOP;
    END LOOP;
    FOR k IN 1 TO 2 LOOP
      omegaoneff(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      omegatwoff(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
    END LOOP;
    FOR k IN 1 TO 4 LOOP
      errorsff(k)(errorcnt_width DOWNTO 1) <= conv_std_logic_vector (0,errorcnt_width);
    END LOOP;
    startff <= "0000";
    
  ELSIF (rising_edge(sysclk)) THEN
    
    IF (enable = '1') THEN

      FOR k IN 1 TO error_symbols LOOP
        syndromesff(k)(m_bits DOWNTO 1) <= syndromes(k)(m_bits DOWNTO 1);
        bdsinff(k)(m_bits DOWNTO 1) <= bdsin(k)(m_bits DOWNTO 1);
      END LOOP;
      
      FOR k IN 1 TO error_symbols LOOP
        bdsoneff(k)(m_bits DOWNTO 1) <= bdsinff(k)(m_bits DOWNTO 1);
        bdstwoff(k)(m_bits DOWNTO 1) <= bdsoneff(k)(m_bits DOWNTO 1);
      END LOOP;
      
      omegaoneff(1)(m_bits DOWNTO 1) <= omegaonenode;
      omegaoneff(2)(m_bits DOWNTO 1) <= omegaoneff(1)(m_bits DOWNTO 1);
      omegatwoff(1)(m_bits DOWNTO 1) <= omegatwonode;
      omegatwoff(2)(m_bits DOWNTO 1) <= omegatwoff(1)(m_bits DOWNTO 1);
      
      errorsff(1)(errorcnt_width DOWNTO 1) <= errorsin;
      errorsff(2)(errorcnt_width DOWNTO 1) <= errorsff(1)(errorcnt_width DOWNTO 1);
      errorsff(3)(errorcnt_width DOWNTO 1) <= errorsff(2)(errorcnt_width DOWNTO 1);
      
      IF (startff(3) = '1') THEN
        FOR k IN 1 TO error_symbols LOOP
          bdsoutff(k)(m_bits DOWNTO 1) <= bdstwoff(k)(m_bits DOWNTO 1);
          omegaff(k)(m_bits DOWNTO 1) <= omeganode(k)(m_bits DOWNTO 1);
          errorsff(4)(errorcnt_width DOWNTO 1) <= errorsff(3)(errorcnt_width DOWNTO 1);
        END LOOP;
      END IF;
      
      startff(1) <= start;
      startff(2) <= startff(1);
      startff(3) <= startff(2);
      startff(4) <= startff(3);
      
    END IF;
  
  END IF;
    
END PROCESS;

  omegaonenode <= syndromesff(1)(m_bits DOWNTO 1);
  omeganode(1)(m_bits DOWNTO 1) <= omegaoneff(2)(m_bits DOWNTO 1);
  
  c_mul_two: rsp_gf_mul
  GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  PORT MAP (aa=>bdsinff(1)(m_bits DOWNTO 1),bb=>syndromesff(1)(m_bits DOWNTO 1),cc=>multiplytwo(m_bits DOWNTO 1));
  gen_omega_one: FOR k IN 1 TO m_bits GENERATE
    omegatwonode(k) <= multiplytwo(k) XOR syndromesff(2)(k);
  END GENERATE;
  
  omeganode(2)(m_bits DOWNTO 1) <= omegatwoff(2)(m_bits DOWNTO 1);
  
  gen_omega_vec: FOR k IN 3 TO error_symbols GENERATE
    c_omega_vec: rsx_omega_vecpipe
    GENERIC MAP (vectorsize=>k)
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
              syndromes=>syndromesff,bds=>bdsinff,
              omeganode=>omeganode(k)(m_bits DOWNTO 1));
  END GENERATE;
  
--***************
--*** OUTPUTS ***
--***************

goa: FOR k IN 1 TO error_symbols GENERATE
  bdsout(k)(m_bits DOWNTO 1) <= bdsoutff(k)(m_bits DOWNTO 1); 
  omegaout(k)(m_bits DOWNTO 1) <= omegaff(k)(m_bits DOWNTO 1);
END GENERATE;
errorsout <= errorsff(4)(errorcnt_width DOWNTO 1);
done <= startff(4);

END rtl;
  
 