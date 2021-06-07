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

ENTITY rsx_count_errors IS 
PORT (
          sysclk, reset, enable : IN STD_LOGIC;
          start : IN STD_LOGIC;
          count_these_ones : IN STD_LOGIC_VECTOR (parallel_symbols_per_channel DOWNTO 1);
          nb_errors : OUT STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1)
         );
END rsx_count_errors;

ARCHITECTURE rtl OF rsx_count_errors IS
  
  constant delay : integer := 2;
  
  constant duplication_factor : integer := get_duplication_factor(parallel_symbols_per_channel);
  constant par : integer := parallel_symbols_per_channel/duplication_factor;
  constant par_first : integer := par + (parallel_symbols_per_channel-par*duplication_factor)  ;

  
  
  constant N : integer := get_count_error_base(par);
  constant LOG2N : integer := log2_ceil_one(N);
  constant N2 : integer := N*N;
  constant N_first : integer := get_count_error_base(par_first);
  constant LOG2N_first : integer := log2_ceil_one(N_first);
  constant N2_first : integer := N_first*N_first;
  
  type N2_type       IS ARRAY (duplication_factor-1 DOWNTO 0) OF STD_LOGIC_VECTOR (N2_first DOWNTO 1);
  type errorcnt_type IS ARRAY (duplication_factor-1 DOWNTO 0) OF STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);

  signal count_these_N2_ones : N2_type; 
  signal nb_error_d, nb_error_s : errorcnt_type;  
  signal nb_error, nb_error_acc : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);  
  signal nb_error_sum  : UNSIGNED (errorcnt_width DOWNTO 1);  
  signal start_ff : STD_LOGIC_VECTOR (2 DOWNTO 1);  
  signal start_acc  : STD_LOGIC;

  component how_many_ones_in_these_X2_bits IS 
  GENERIC (
        N  : positive := 6;
        N2  : positive := 36;
        LOG2N : positive := 3;
        delay : integer := 1);
  PORT (
        reset, clock, enable : IN STD_LOGIC;
        aa : IN STD_LOGIC_VECTOR (N2 DOWNTO 1);
        cc : OUT STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1)
        );
  end component;
  
  
BEGIN
    
    
    count_these_N2_ones(0)(par_first DOWNTO 1) <= count_these_ones(par_first DOWNTO 1) ;	
    add_zeros : IF (par_first /= N2_first) GENERATE
      count_these_N2_ones(0)(N2_first DOWNTO par_first+1) <= (others=>'0') ;
    END GENERATE;

    counting_the_ones_last: how_many_ones_in_these_X2_bits
    GENERIC MAP (N=>N_first, N2=>N2_first, LOG2N=>LOG2N_first, delay=>delay-1)
    PORT MAP (
              reset  => reset,
              clock  => sysclk,
              enable => enable,
              aa     => count_these_N2_ones(0),
              cc     => nb_error_d(0));  
              
    nb_error_s(0) <= nb_error_d(0);

    is_duplication : IF duplication_factor > 1 GENERATE
      duplication: FOR k IN 1 TO duplication_factor-1 GENERATE
        count_these_N2_ones(k)(par DOWNTO 1) <= count_these_ones(par*k+par_first DOWNTO 1+par*(k-1)+par_first) ;	
        filling_up : IF (parallel_symbols_per_channel /= N2) GENERATE
          count_these_N2_ones(k)(N2_first DOWNTO par+1) <= (others=>'0') ;
        END GENERATE;


        counting_the_ones: how_many_ones_in_these_X2_bits
        GENERIC MAP (N=>N, N2=>N2, LOG2N=>LOG2N, delay=>delay-1)
        PORT MAP (
              reset  => reset,
              clock  => sysclk,
              enable => enable,
              aa     => count_these_N2_ones(k)(N2 DOWNTO 1),
              cc     => nb_error_d(k));
              
        nb_error_s(k) <= unsigned(nb_error_s(k-1)) + unsigned(nb_error_d(k));

      END GENERATE;  
    END GENERATE;  
    

     nb_error <= nb_error_s(duplication_factor-1);

    

    pipeline_start: PROCESS (sysclk,reset)
    BEGIN
        IF (reset = '1') THEN
          start_ff    <= conv_std_logic_vector(0,2);
        ELSIF (rising_edge(sysclk)) THEN
          IF (enable = '1') THEN
            start_ff(1) <= start;
            start_ff(2) <= start_ff(1);
          END IF;
        END IF;
    END PROCESS;

    delay_is_1 : IF (delay=1) GENERATE
      start_acc <= start;
    END GENERATE;
     delay_is_sup_to_1 : IF (delay/=1) GENERATE
      start_acc <= start_ff(delay-1);
    END GENERATE;   
    
    nb_error_sum <= unsigned(nb_error_acc) + unsigned(nb_error);
    
    prc_accumulation: PROCESS (sysclk,reset)
    BEGIN
        IF (reset = '1') THEN
          nb_error_acc <= conv_std_logic_vector(0,errorcnt_width);
        ELSIF (rising_edge(sysclk)) THEN
          IF (enable = '1') THEN
            IF (start_acc  = '1') THEN
              nb_error_acc <= nb_error;
            ELSE
              nb_error_acc <= std_logic_vector(nb_error_sum);
            END IF;
          END IF;
        END IF;
    END PROCESS;
    
    
    nb_errors <= nb_error_acc;
  
END rtl;

----------------------------------------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all; 

USE work.rsx_parameters.all;
USE work.rsx_package.all;
USE work.rsx_roots.all;

ENTITY how_many_ones_in_these_X2_bits IS 
GENERIC (
      N  : positive := 6;
      N2  : positive := 36;
      LOG2N : positive := 3;
      delay : integer := 1
);
PORT (
      reset, clock, enable : IN STD_LOGIC;
      aa : IN STD_LOGIC_VECTOR (N2 DOWNTO 1);
      cc : OUT STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1)
      );
END how_many_ones_in_these_X2_bits;

ARCHITECTURE rtl OF how_many_ones_in_these_X2_bits IS
  
  type nb_ones_in_N2 IS ARRAY (N DOWNTO 1) OF STD_LOGIC_VECTOR (LOG2N DOWNTO 1);
  type typeofweight IS ARRAY (LOG2N DOWNTO 1) OF STD_LOGIC_VECTOR (N DOWNTO 1);
  type typeofweight_sum IS ARRAY (LOG2N DOWNTO 1) OF STD_LOGIC_VECTOR (LOG2N DOWNTO 1);
  
  signal there_are_x_ones, there_are_x_ones_ff : nb_ones_in_N2;   
  signal there_are_x_ones_weight : typeofweight;   
  signal there_are_x_weight, there_are_x_weight_ff : typeofweight_sum;   
  signal nb_error_node, nb_error_ff : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  signal weight_sum : STD_LOGIC_VECTOR (LOG2N+3 DOWNTO 1);
  
  component how_many_ones_in_these_X_bits IS 
  GENERIC (
      X  : positive := 6;
      LOG2X : positive := 3
  );
  PORT (
      aa : IN STD_LOGIC_VECTOR (X DOWNTO 1);
      cc : OUT STD_LOGIC_VECTOR (LOG2X DOWNTO 1)
      );
  end component;


BEGIN

    first_stage_count: FOR k IN 1 TO N GENERATE                
      count_nb: how_many_ones_in_these_X_bits
      GENERIC MAP (X=>N, LOG2X=>LOG2N)
      PORT MAP (aa=>aa(N*(k-1)+N DOWNTO N*(k-1)+1),
                cc=>there_are_x_ones(k));
    END GENERATE;
    
    -- count the bit weight of the sum
    second_stage_count: FOR k IN 1 TO LOG2N GENERATE
      second_stage_map: FOR j IN 1 TO N GENERATE
        delay_cnt1 : IF (delay<=1) GENERATE
          there_are_x_ones_weight(k)(j) <= there_are_x_ones(j)(k);
        END GENERATE;
        delay_cnt2 : IF (delay>1) GENERATE
          there_are_x_ones_weight(k)(j) <= there_are_x_ones_ff(j)(k);
        END GENERATE;
      END GENERATE;

      second_stage_count_weight: how_many_ones_in_these_X_bits
      GENERIC MAP (X=>N, LOG2X=>LOG2N)
      PORT MAP (aa=>there_are_x_ones_weight(k),
                cc=>there_are_x_weight(k));
    END GENERATE;

    prc_index: PROCESS (clock,reset)
    BEGIN
        IF (reset = '1') THEN
          FOR k IN 1 TO N LOOP
            there_are_x_ones_ff(k) <= conv_std_logic_vector(0,LOG2N);
          END LOOP;
          FOR k IN 1 TO LOG2N LOOP
            there_are_x_weight_ff(k) <= conv_std_logic_vector(0,LOG2N);
          END LOOP;
          nb_error_ff <= conv_std_logic_vector(0,errorcnt_width);
        ELSIF (rising_edge(clock)) THEN
          IF (enable = '1') THEN
            FOR k IN 1 TO N LOOP
              there_are_x_ones_ff(k) <= there_are_x_ones(k);
            END LOOP;
            FOR k IN 1 TO LOG2N LOOP
              there_are_x_weight_ff(k) <= there_are_x_weight(k);
            END LOOP;
            nb_error_ff <= nb_error_node;
          END IF;
        END IF;
    END PROCESS;

    weight_sum <= ('0' & there_are_x_weight(3) & "00") + ("00" & there_are_x_weight(2) & '0') + ( "000" & there_are_x_weight(1));
    nb_error_node <= weight_sum(errorcnt_width downto 1);    
    
    delay_cnt3 : IF (delay=2) GENERATE
      cc <= nb_error_ff;
    END GENERATE;
    delay_cnt4 : IF (delay=1) GENERATE
      cc <= nb_error_ff;
    END GENERATE;
    delay_cnt5 : IF (delay=0) GENERATE
      cc <= nb_error_node;
    END GENERATE;
    
END rtl;
  
  
----------------------------------------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all; 

USE work.rsx_parameters.all;
USE work.rsx_package.all;
USE work.rsx_roots.all;


ENTITY how_many_ones_in_these_X_bits IS 
    GENERIC (
        X  : positive := 6;
        LOG2X : positive := 3
    );
    PORT (
        aa : IN STD_LOGIC_VECTOR (X DOWNTO 1);
        -- cc : OUT STD_LOGIC_VECTOR (LOG2X DOWNTO 1)
        cc : OUT STD_LOGIC_VECTOR (log2_ceil_one(X) DOWNTO 1)
         );
END how_many_ones_in_these_X_bits;

ARCHITECTURE rtl OF how_many_ones_in_these_X_bits IS

constant X2  : integer  := X*X;

type numarray6 IS ARRAY (0 TO 63) OF integer;
type numarray7 IS ARRAY (0 TO 127) OF integer;
type numarray8 IS ARRAY (0 TO 255) OF integer;
type numarray9 IS ARRAY (0 TO 511) OF integer;
type numarray10 IS ARRAY (0 TO 1023) OF integer;
type numarray11 IS ARRAY (0 TO 2047) OF integer;

constant T6 : numarray6 := (0,1,1,2,1,2,2,3,1, 
2,2,3,2,3,3,4,1,
2,2,3,2,3,3,4,2,
3,3,4,3,4,4,5,1,
2,2,3,2,3,3,4,2,
3,3,4,3,4,4,5,2,
3,3,4,3,4,4,5,3,
4,4,5,4,5,5,6); 

constant T7 : numarray7 := (
0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,4,1,2,2,3,
2,3,3,4,2,3,3,4,3,4,4,5,1,2,2,3,2,3,3,4,
2,3,3,4,3,4,4,5,2,3,3,4,3,4,4,5,3,4,4,5,
4,5,5,6,1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,
2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,2,3,3,4,
3,4,4,5,3,4,4,5,4,5,5,6,3,4,4,5,4,5,5,6,
4,5,5,6,5,6,6,7); 

constant T8 : numarray8 := (
0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,4,1,2,2,3,
2,3,3,4,2,3,3,4,3,4,4,5,1,2,2,3,2,3,3,4,
2,3,3,4,3,4,4,5,2,3,3,4,3,4,4,5,3,4,4,5,
4,5,5,6,1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,
2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,2,3,3,4,
3,4,4,5,3,4,4,5,4,5,5,6,3,4,4,5,4,5,5,6,
4,5,5,6,5,6,6,7,1,2,2,3,2,3,3,4,2,3,3,4,
3,4,4,5,2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,3,4,4,5,
4,5,5,6,4,5,5,6,5,6,6,7,2,3,3,4,3,4,4,5,
3,4,4,5,4,5,5,6,3,4,4,5,4,5,5,6,4,5,5,6,
5,6,6,7,3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
4,5,5,6,5,6,6,7,5,6,6,7,6,7,7,8);

BEGIN
  x_eq_6 : if X = 6 generate
      cc <= conv_std_logic_vector(T6(conv_integer(aa)),LOG2X);
  end generate;
  x_eq_7 : if X = 7 generate
      cc <= conv_std_logic_vector(T7(conv_integer(aa)),LOG2X);
  end generate;
  x_eq_8 : if X = 8 generate
      cc <= conv_std_logic_vector(T8(conv_integer(aa)),LOG2X);
  end generate;
END rtl;
