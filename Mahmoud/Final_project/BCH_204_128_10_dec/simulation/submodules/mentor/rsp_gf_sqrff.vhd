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

--***************************************************
--***                                             ***
--***   ALTERA REED SOLOMON LIBRARY               ***
--***                                             ***
--***   RSP_GF_SQRFF                              ***
--***                                             ***
--***   Function: Galois Field Squarer            ***
--***             (Pipelined In and Out)          ***
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

ENTITY rsp_gf_sqrff IS 
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
END rsp_gf_sqrff;

ARCHITECTURE rtl OF rsp_gf_sqrff IS
 
  signal aaff, ccff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
 
  signal expand : STD_LOGIC_VECTOR (2*m_bits-1 DOWNTO 1);
  signal ccnode : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  signal validff : STD_LOGIC_VECTOR (2 DOWNTO 1);
  
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
  
    prc_pipe: PROCESS (sysclk)
    BEGIN
      
    IF (rising_edge(sysclk)) THEN

      IF (reset = '1') THEN
      
        aaff <= conv_std_logic_vector (0,m_bits);
        ccff <= conv_std_logic_vector (0,m_bits);
        validff <= "00";
      
      ELSIF (enable = '1') THEN
      
        aaff <= aa;
        ccff <= ccnode;
        
        validff(1) <= validin;
        validff(2) <= validff(1);
        
      END IF;
      
    END IF;
    
  END PROCESS;
    
  cpp: rsp_gf_pp
  GENERIC MAP (m_bits=>m_bits)
  PORT MAP (aa=>aaff,bb=>aaff,
            cc=>expand);
  
  crr: rsp_gf_mr
  GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  PORT MAP (aa=>expand,
            cc=>ccnode);
  
  cc <= ccff;
  validout <= validff(2);
  
END rtl;


