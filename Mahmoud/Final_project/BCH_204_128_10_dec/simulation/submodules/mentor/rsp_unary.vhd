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
--***   RSP_UNARY                                 ***
--***                                             ***
--***   Function: Parallel Reed Solomon Decoder   ***
--***   Binary to Unary Converter                 ***
--***                                             ***
--***   01/03/10 ML                               ***
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

ENTITY rsp_unary IS 
GENERIC (
         inwidth : positive := 8;
         outwidth : positive := 8
        );
PORT (
      inbus : IN STD_LOGIC_VECTOR (inwidth DOWNTO 1);

		outbus : OUT STD_LOGIC_VECTOR (outwidth DOWNTO 1)
		);
END rsp_unary;

ARCHITECTURE rtl OF rsp_unary IS

  type unarytype IS ARRAY (outwidth+1 DOWNTO 1) OF STD_LOGIC_VECTOR (outwidth DOWNTO 1);
  type numtype IS ARRAY (outwidth+1 DOWNTO 1) OF STD_LOGIC_VECTOR (inwidth DOWNTO 1);
  
  signal unarys : unarytype;
  signal selnum : numtype;
  signal chknode : numtype;
  signal muxnode : unarytype;
  
BEGIN
    
  unarys(1)(outwidth DOWNTO 1) <= conv_std_logic_vector (0,outwidth);
  gna: FOR k IN 2 TO outwidth GENERATE
    gnb: FOR j IN 1 TO k-1 GENERATE
      unarys(k)(j) <= '1';
    END GENERATE;
    gnc: FOR j IN k TO outwidth GENERATE
      unarys(k)(j) <= '0';
    END GENERATE;
  END GENERATE;
  
  gnd: FOR k IN 1 TO outwidth GENERATE
    unarys(outwidth+1)(k) <= '1';
  END GENERATE;
  
  gsna: FOR k IN 1 TO outwidth+1 GENERATE
      selnum(k)(inwidth DOWNTO 1) <= conv_std_logic_vector(k-1,inwidth);
  END GENERATE;
  
  gca: FOR k IN 1 TO outwidth+1 GENERATE
    chknode(k)(1) <= selnum(k)(1) XOR inbus(1);
    gcb: FOR j IN 2 TO inwidth GENERATE
      chknode(k)(j) <= chknode(k)(j-1) OR (selnum(k)(j) XOR inbus(j));
    END GENERATE;
  END GENERATE;
  
  gma: FOR k IN 1 TO outwidth GENERATE
    muxnode(1)(k) <= unarys(1)(k) AND NOT(chknode(1)(inwidth)); 
  END GENERATE;
  gmb: FOR k IN 2 TO outwidth+1 GENERATE
    gmc: FOR j IN 1 TO outwidth GENERATE
      muxnode(k)(j) <= muxnode(k-1)(j) OR (unarys(k)(j) AND NOT(chknode(k)(inwidth)));
    END GENERATE;
  END GENERATE;
  
  outbus <= muxnode(outwidth+1)(outwidth DOWNTO 1);
  
END rtl;

 