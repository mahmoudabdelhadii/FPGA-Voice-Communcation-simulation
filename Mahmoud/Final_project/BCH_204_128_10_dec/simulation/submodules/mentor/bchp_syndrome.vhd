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

USE work.bchp_parameters.all;
USE work.bchp_package.all;
USE work.bchp_roots.all;

--***************************************************
--***                                             ***
--***   ALTERA BCH LIBRARY                        ***
--***                                             ***
--***   BCHP_SYNDROME                             ***
--***                                             ***
--***   Function: Calculate One Syndrome          ***
--***                                             ***
--***   27/07/12 ML                               ***
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

ENTITY bchp_syndrome IS 
GENERIC (startpower : positive := 1);
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      load : IN STD_LOGIC;
      bits : IN STD_LOGIC_VECTOR (parallel_bits DOWNTO 1);
    
      syndrome : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
      synvalid : OUT STD_LOGIC
		 );
END bchp_syndrome;

ARCHITECTURE rtl OF bchp_syndrome IS

  type addvectortype IS ARRAY (parallel_bits DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type multipliertype IS ARRAY (parallel_bits-1 DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);

  signal pp : addvectortype;
  signal addvector : addvectortype;
  
  signal bitsff : STD_LOGIC_VECTOR (parallel_bits DOWNTO 1);
  signal loadff : STD_LOGIC_VECTOR (3 DOWNTO 1);
  signal syndrome_multiply, syndrome_multiplyff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal syndrome_accumulate, syndrome_accumulateff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal syndrome_sum, syndrome_sumff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal syndrome_divide, syndrome_divideff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);

  signal countff : STD_LOGIC_VECTOR (16 DOWNTO 1);
  signal moduloload : STD_LOGIC;
  signal moduloloadff : STD_LOGIC_VECTOR (4 DOWNTO 1);
  
  signal bitsnode : multipliertype;
  signal bb_multiplier : multipliertype;
  signal bb_shift, bb_divide : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
	
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
  		   
BEGIN
 
  prc_main: PROCESS (sysclk)
  BEGIN
      
    IF (rising_edge(sysclk)) THEN

      IF (reset = '1') THEN
    
        loadff <= "000";
        FOR k IN 1 TO parallel_bits LOOP
          bitsff(k) <= '0';
        END LOOP;
        FOR k IN 1 TO m_bits LOOP
          syndrome_multiplyff(k) <= '0';
          syndrome_accumulateff(k) <= '0';
          syndrome_sumff(k) <= '0';
          syndrome_divideff(k) <= '0';
        END LOOP;
  
      ELSIF (enable = '1') THEN
      
        loadff(1) <= load;
        loadff(2) <= loadff(1);
        loadff(3) <= loadff(2);
        
        FOR k IN 1 TO parallel_bits LOOP
          bitsff(k) <= bits(k);
        END LOOP;
        
        IF (loadff(1) = '1') THEN
          syndrome_multiplyff <= syndrome_multiply;
        END IF;
        
        IF (loadff(2) = '1') THEN
          FOR k IN 1 TO m_bits LOOP
            syndrome_accumulateff(k) <= (syndrome_accumulate(k) AND NOT(moduloloadff(2)));
          END LOOP;
        END IF;
        
        IF (loadff(2) = '1') THEN
          syndrome_sumff <= syndrome_sum;
        END IF;
        
        IF (loadff(3) = '1') THEN
          syndrome_divideff <= syndrome_divide;
        END IF;
        
      END IF;
      
    END IF;
  
  END PROCESS;

  prc_ctl: PROCESS (sysclk)
  BEGIN
    
    IF (rising_edge(sysclk)) THEN

      IF (reset = '1') THEN

        countff <= conv_std_logic_vector (0,16);
        moduloloadff <= "0000";
  
      ELSIF (enable = '1') THEN
      
        IF (moduloload = '1') THEN
          countff <= conv_std_logic_vector (0,16);
        ELSIF (load = '1') THEN
          countff <= countff + 1;
        END IF;
        
        moduloloadff(1) <= moduloload;
        moduloloadff(2) <= moduloloadff(1);
        moduloloadff(3) <= moduloloadff(2);
        moduloloadff(4) <= moduloloadff(3);
        
      END IF;
      
    END IF;
  
  END PROCESS;
 
  prc_count_check: PROCESS (countff)
  BEGIN
    
    IF (countff = (codeword_clocks-1)) THEN
      moduloload <= '1';
    ELSE
      moduloload <= '0';
    END IF;
  
  END PROCESS;
    
  gen_multiplier: FOR k IN 1 TO parallel_bits-1 GENERATE
    
    bb_multiplier(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (powernum(startpower*(parallel_bits-k) mod field_index),m_bits); -- doing (a^i)^k
    gen_mul_pp: FOR m IN 1 TO m_bits GENERATE
      pp(k)(m) <= bb_multiplier(k)(m) AND bitsff(k); -- doing r(k)*(a^i)^k
    END GENERATE;
    
  END GENERATE;
  pp(parallel_bits)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits-1) & bitsff(parallel_bits); -- doing the r0 bit
        
  addvector(1)(m_bits DOWNTO 1) <= pp(1)(m_bits DOWNTO 1);
  gen_add_one: FOR k IN 2 TO parallel_bits GENERATE
    gen_add_two: FOR j IN 1 TO m_bits GENERATE
      addvector(k)(j) <= addvector(k-1)(j) XOR pp(k)(j); -- then add together
    END GENERATE;
  END GENERATE;
  
  syndrome_multiply <= addvector(parallel_bits)(m_bits DOWNTO 1);

  comp_plus: rsp_gf_add -- this is to add the computed fraction of syndrome with existing accumulated syndrome
  GENERIC MAP (m_bits=>m_bits)
  PORT MAP (aa=>syndrome_multiplyff,bb=>syndrome_accumulateff,
            cc=>syndrome_sum);
         
  bb_shift <= conv_std_logic_vector (powernum((startpower*parallel_bits) mod field_index),m_bits); 
  
  comp_mulshift: rsp_gf_mul -- this part is to shift the whole accumulated syndrome by startpower*parallel_bits, to allow new bits coming in
  GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  PORT MAP (aa=>syndrome_sum,bb=>bb_shift,
            cc=>syndrome_accumulate);

  --if n%p=0,negenum = 1            
  bb_divide <= conv_std_logic_vector (negenum(startpower*(last_parallel_bits) mod field_index),m_bits); -- if the last parallel input consists of some invalid data then discard these data by shifting back
  comp_reverse: rsp_gf_mul
  GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  PORT MAP (aa=>syndrome_sumff,bb=>bb_divide,
            cc=>syndrome_divide);
            
  -- OUTPUTS
  syndrome <= syndrome_divideff; 
  synvalid <= moduloloadff(4);          

END rtl;


