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
--***   RSX_OMEGA_VECPIPE                         ***
--***                                             ***
--***   Function: Calculate a single element of   ***
--***   the Error Evaluator Polynomial            ***
--***                                             ***
--***   01/12/10 ML                               ***
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

--*** TODO: Replace PP,MR with optimized vector   ***

ENTITY rsx_omega_vecpipe IS 
GENERIC (vectorsize : positive := 4);
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      syndromes : IN errorvector;
      bds : IN errorvector;

      omeganode : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
		);
END rsx_omega_vecpipe;

ARCHITECTURE rtl OF rsx_omega_vecpipe IS
  
  type pptype IS ARRAY (vectorsize-1 DOWNTO 1) OF STD_LOGIC_VECTOR (2*m_bits-1 DOWNTO 1);
  type addtype IS ARRAY (vectorsize DOWNTO 1) OF STD_LOGIC_VECTOR (2*m_bits-1 DOWNTO 1);
  
  signal ppnode : pptype;
  signal ppff : pptype;
  signal syndromeff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  signal addvector : addtype;
  signal addff : STD_LOGIC_VECTOR (2*m_bits-1 DOWNTO 1);
  
  component rsp_gf_pp  
  GENERIC (m_bits : positive := 8);
  PORT (
        aa, bb : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

		    cc : OUT STD_LOGIC_VECTOR (2*m_bits-1 DOWNTO 1)
		   );
  end component;
  
  component rsp_gf_mr
  GENERIC (
           polynomial : positive := 285;
           m_bits : positive := 8
          );
  PORT (
        aa : IN STD_LOGIC_VECTOR (2*m_bits-1 DOWNTO 1);

		    cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
		   );
	end component;
	
BEGIN

  psma: PROCESS (sysclk,reset)
  BEGIN

    IF (reset = '1') THEN    
  
      FOR k IN 1 TO vectorsize-1 LOOP
        FOR j IN 1 TO 2*m_bits-1 LOOP
          ppff(k)(j) <= '0';
        END LOOP;
      END LOOP;
      syndromeff <= conv_std_logic_vector (0,m_bits);
      addff <= conv_std_logic_vector (0,2*m_bits-1);
    
    ELSIF (rising_edge(sysclk)) THEN
    
      IF (enable = '1') THEN

        FOR k IN 1 TO vectorsize-1 LOOP
          ppff(k)(2*m_bits-1 DOWNTO 1) <= ppnode(k)(2*m_bits-1 DOWNTO 1);
        END LOOP;
        syndromeff <= syndromes(vectorsize)(m_bits DOWNTO 1);
        addff <= addvector(vectorsize)(2*m_bits-1 DOWNTO 1);
      
      END IF;
  
    END IF;
    
  END PROCESS;
  
  gen_mul_one: FOR k IN 1 TO vectorsize-1 GENERATE
    c_mva: rsp_gf_pp
    GENERIC MAP (m_bits=>m_bits)
    PORT MAP (aa=>bds(k)(m_bits DOWNTO 1),bb=>syndromes(vectorsize-k)(m_bits DOWNTO 1),
              cc=>ppnode(k)(2*m_bits-1 DOWNTO 1));
  END GENERATE;
  
  addvector(1)(2*m_bits-1 DOWNTO 1) <= conv_std_logic_vector(0,m_bits-1) & syndromeff;
  gen_add_one: FOR j IN 1 TO vectorsize-1 GENERATE
    gen_add_two: FOR k IN 1 TO 2*m_bits-1 GENERATE
      addvector(j+1)(k) <= addvector(j)(k) XOR ppff(j)(k);
    END GENERATE;
  END GENERATE;
  
  comp_reduce: rsp_gf_mr
  GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  PORT MAP (aa=>addff,cc=>omeganode);
  
END rtl;
  
 