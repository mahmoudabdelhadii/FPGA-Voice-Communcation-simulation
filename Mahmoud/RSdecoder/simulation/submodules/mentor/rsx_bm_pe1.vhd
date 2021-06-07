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
USE work.rsx_functions.all;

--***************************************************
--***                                             ***
--***   ALTERA REED SOLOMON LIBRARY               ***
--***                                             ***
--***   RSX_BM_PE1                                ***
--***                                             ***
--***   Function: Parallel Reed Solomon Decoder   ***
--***   Berlekamp-Massey Error Locator Solver     ***
--***                                             ***
--***   4 Clocks per Round Systolic PE            ***
--***                                             ***
--***   08/08/13 ML                               ***
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

ENTITY rsx_bm_pe1 IS 
GENERIC (
         startloop : integer := 2;
         endloop : integer := 6
        ); -- mloop: 0 to check_symbols-1
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      start : IN STD_LOGIC; -- start this stage
      deltaXin : IN syndromevector;
      deltaXprevin : IN syndromevector;
      bdsin, bdsprevin : IN errorvector;
      llnumberin : IN STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
      chktlmin : IN STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1) := conv_std_logic_vector(0,checkcnt_width);
      thetain : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
      bdsout, bdsprevout : OUT errorvector;
      deltaXout : OUT syndromevector;
      deltaXprevout : OUT syndromevector;
      chktlmout : OUT STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
      thetaout : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
      llnumberout : OUT STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
      nextstage : OUT STD_LOGIC; -- start for next level
      bm_ready : OUT STD_LOGIC);
END rsx_bm_pe1;

ARCHITECTURE rtl OF rsx_bm_pe1 IS

  constant is_error_sup : integer := is_a_strict_sup_b(error_symbols,endloop+1);
  constant systolic_symbols : integer := (1-is_error_sup)*error_symbols + is_error_sup*(endloop+1) +  riBm;
  type systolictype IS ARRAY (systolic_symbols DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  
  -- state machine section
  signal stateff         : STD_LOGIC_VECTOR (1 DOWNTO 1);
  signal roundffnode     : STD_LOGIC_VECTOR (check_symbols DOWNTO 1);
  signal roundff         : STD_LOGIC_VECTOR (endloop-startloop+1 DOWNTO 1);
  signal statefornode    : STD_LOGIC;

  -- sigma section
  signal bdff                       : systolictype;
  signal bdprevff                   : systolictype;
  signal bdsoutnode                 : errorvector;
  signal bdsprevoutnode             : errorvector;
  signal bdprevff_shift             : errorvector;
  signal mulout_bd                  : systolictype;
  signal mulout_bdprev              : systolictype;
  
  -- delta section
  signal deltaXff                          : syndromevector;
  signal new_deltaXff                      : syndromevector;
  signal deltaXprevff                      : syndromevector; 
  signal deltaX_node                       : syndromevector;  
  signal deltaXprev_shift                  : syndromevector; 
  signal thetaff                           : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal thetaoutnode                      : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal delta_current                     : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal deltaXprev_node                   : syndromevector;
  signal deltazero                         : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal mulout_deltaX, mulout_deltaXprev  : syndromevector;
  
  

  signal llnumberff                     : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  signal mloopff                        : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal startloopnumber, endloopnumber : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal mloopplusone                   : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal chktlm                         : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal chktlm_r                       : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal chktlmnode_r                   : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal chktlmplus                     : STD_LOGIC_VECTOR (checkcnt_width+1 DOWNTO 1);
  signal chktlmplus_diff                : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal chktlmminusone                 : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal tlm                            : STD_LOGIC;
  signal tlm_r                          : STD_LOGIC;
  signal lastloop                       : STD_LOGIC;
  signal lastloop_node                  : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal llnextnumber                   : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  signal lloutnode                      : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  
  signal is_bm_ready                    : STD_LOGIC;
  signal start_bm                       : STD_LOGIC;
  
  
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

BEGIN



startloopnumber <= conv_std_logic_vector (startloop,checkcnt_width);
endloopnumber <= conv_std_logic_vector (endloop,checkcnt_width);

--************************
--*** Backpressure ***
--************************

gen_bkp :  IF (startloop = 0 AND channel>1) GENERATE
  prc_bkp: PROCESS (sysclk,reset)
  BEGIN

    IF (reset = '1') THEN
      is_bm_ready <= '1';
    ELSIF (rising_edge(sysclk)) THEN
      IF (enable = '1') THEN
        IF (start_bm = '1') THEN
          is_bm_ready <= '0';
        ELSIF(roundff(endloop+1 -1) = '1') THEN
          is_bm_ready <= '1';
        END IF;
      END IF;
    END IF;
  END PROCESS;
  start_bm <= start AND is_bm_ready;
  
END GENERATE;
gen_no_bkp :  IF (startloop > 0 OR channel=1) GENERATE
  is_bm_ready <= '1';
  start_bm <= start;
END GENERATE;

--*****************************
--*** STATE MACHINE SECTION ***
--*****************************

prc_ctl: PROCESS (sysclk,reset)
BEGIN

  IF (reset = '1') THEN    
  
    stateff(1) <= '0';
    roundff <= conv_std_logic_vector(0,endloop-startloop+1);
    
  ELSIF (rising_edge(sysclk)) THEN
    
    IF (enable = '1') THEN

      stateff(1) <= start_bm OR (stateff(1) AND NOT(lastloop));
      
      IF (start_bm = '1') THEN
        roundff(1) <= '1';
        roundff(endloop-startloop+1 downto 2) <= conv_std_logic_vector(0,endloop-startloop);
      ELSIF(stateff(1) = '1' AND endloop/=startloop) THEN
        roundff(1) <=  '0';
        roundff(endloop-startloop+1 downto 2) <= roundff(endloop-startloop downto 1);
      END IF;
      
    END IF;
  
  END IF;
    
END PROCESS;

statenode0 : IF (startloop>0) GENERATE
  roundffnode(startloop downto 1) <= conv_std_logic_vector(0,startloop);
END GENERATE;
roundffnode(endloop+1 downto startloop+1) <= roundff;
statenode1 : IF (endloop+1<check_symbols) GENERATE
  roundffnode(check_symbols downto endloop+2) <= conv_std_logic_vector(0,check_symbols-endloop-1);
END GENERATE;

statefornode <= deltazero(m_bits) AND tlm; --tlm_r


--************************
--*** Delta SECTION ***
--************************

  prc_syn: PROCESS (sysclk,reset)
  BEGIN
  
    IF (reset = '1') THEN
    
      deltaXff <= (others => (others => '0'));
      deltaXprevff <= (others => (others => '0'));
    
    ELSIF (rising_edge(sysclk)) THEN
    
      IF (enable = '1') THEN

        IF (start_bm = '1' OR stateff(1) = '1') THEN
          FOR k IN 1 TO check_symbols-1 LOOP
            FOR m IN 1 TO m_bits LOOP
              deltaXff(k)(m) <= (deltaXin(k+1)(m) AND start_bm) OR
                                 (new_deltaXff(k+1)(m) AND NOT(start_bm));
              deltaXprevff(k)(m) <= (deltaXprevin(k+1)(m) AND start_bm) OR
                                 (deltaXprev_node(k+1)(m) AND NOT(start_bm));
            END LOOP;
          END LOOP;
          FOR m IN 1 TO m_bits LOOP
            deltaXff(check_symbols)(m) <= (deltaXin(1)(m) AND start_bm) OR
                                           (new_deltaXff(1)(m) AND NOT(start_bm));
            deltaXprevff(check_symbols)(m) <= (deltaXprevin(1)(m) AND start_bm) OR
                                           (deltaXprev_node(1)(m) AND NOT(start_bm));
          END LOOP; 
        END IF;
        
      END IF;
      
    END IF;
 
  END PROCESS;
  

  delta_current <= deltaXff(1);
  deltazero(1) <= deltaXff(1)(1);
  gen_delta_zipr: FOR k IN 2 TO m_bits GENERATE
    deltazero(k) <= deltaXff(1)(k) OR deltazero(k-1);
  END GENERATE;
  

  -- before the input of stage 0, rotate syndromes the other way externally  
  shift_deltaX: FOR i IN 1 TO m_bits GENERATE
    shift_deltaX_k: FOR k IN 1 TO check_symbols-1 GENERATE
      deltaXprev_shift(k+1)(i) <= deltaXprevff(k)(i) AND NOT(roundffnode(check_symbols-k+1));
    END GENERATE;
    deltaXprev_shift(1)(i) <= deltaXprevff(check_symbols)(i) AND NOT(roundffnode(1));
  END GENERATE;
  

  gen_stage_deltaprev: FOR k IN 1 TO check_symbols GENERATE
    gen_stage_two: FOR m IN 1 TO m_bits GENERATE
      deltaXprev_node(k)(m) <= (deltaXff(k)(m) AND statefornode) OR
                             (deltaXprev_shift(k)(m) AND NOT(statefornode));
    END GENERATE;
  END GENERATE;
  
  
  
  --***************************
  --   update Delta Polynomials
  --***************************
  gen_mul_deltaX: FOR k IN 1 TO check_symbols GENERATE
    gfma1: rsp_gf_mul 
    GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
    PORT MAP (aa=>deltaXff(k)(m_bits DOWNTO 1),bb=>thetaff(m_bits DOWNTO 1),
              cc=>mulout_deltaX(k)(m_bits DOWNTO 1));
    gfma2: rsp_gf_mul 
    GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
    PORT MAP (aa=>deltaXprev_shift(k)(m_bits DOWNTO 1),bb=>delta_current(m_bits DOWNTO 1),
              cc=>mulout_deltaXprev(k)(m_bits DOWNTO 1));
              
    new_deltaXff(k) <=  mulout_deltaX(k) XOR  mulout_deltaXprev(k);
              
  END GENERATE;
  
  
  
--******************
--*** Sigma SECTION ***
--******************

  prc_bd: PROCESS (sysclk,reset)
  BEGIN
      
    IF (reset = '1') THEN

      bdff       <= (others=>(others=>'0'));
      bdprevff   <= (others=>(others=>'0'));

    ELSIF (rising_edge(sysclk)) THEN
    
      IF (enable = '1') THEN
        
        IF (start_bm = '1' OR stateff(1) = '1') THEN
          FOR k IN 1 TO systolic_symbols LOOP
            FOR m IN 1 TO m_bits LOOP
              bdff(k)(m) <= (bdsin(k)(m) AND start_bm) OR
                            (bdsoutnode(k)(m) AND NOT(start_bm));
              bdprevff(k)(m) <= (bdsprevin(k)(m) AND start_bm) OR
                                (bdsprevoutnode(k)(m) AND NOT(start_bm));
            END LOOP;
          END LOOP;
        END IF;

      END IF;
      
    END IF;
    
  END PROCESS;
  
  bdprevff_shift(1) <= conv_std_logic_vector(0,m_bits);
  gen_bdprevshift: FOR k IN 2 TO systolic_symbols GENERATE
    bdprevff_shift(k) <= bdprevff(k-1);
  END GENERATE;

  
  --***************************
  --   update Sigma Polynomials
  --***************************
  gen_mul_bd: FOR k IN 1 TO systolic_symbols GENERATE
    gfma1: rsp_gf_mul 
    GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
    PORT MAP (aa=>bdff(k)(m_bits DOWNTO 1),bb=>thetaff(m_bits DOWNTO 1),
              cc=>mulout_bd(k)(m_bits DOWNTO 1));
    gfma2: rsp_gf_mul 
    GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
    PORT MAP (aa=>bdprevff(k)(m_bits DOWNTO 1),bb=>delta_current(m_bits DOWNTO 1),
              cc=>mulout_bdprev(k)(m_bits DOWNTO 1));
  END GENERATE;  
  
  bdsoutnode(1) <= mulout_bd(1);
  gen_sum_bd: FOR k IN 2 TO systolic_symbols GENERATE
    bdsoutnode(k) <=  mulout_bd(k) XOR  mulout_bdprev(k-1);   
  END GENERATE; 
  
  gen_stage_bdprev: FOR k IN 1 TO systolic_symbols GENERATE
    gen_stage_two: FOR m IN 1 TO m_bits GENERATE
      bdsprevoutnode(k)(m) <= (bdff(k)(m) AND statefornode) OR
                             (bdprevff_shift(k)(m) AND NOT(statefornode));
    END GENERATE;
  END GENERATE;    
    
  gen_bdout_append: IF (systolic_symbols < bm_symbols) GENERATE 
    gen_mul_bd_0: FOR k IN systolic_symbols+1 TO bm_symbols GENERATE
      bdsoutnode(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      bdsprevoutnode(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
    END GENERATE;    
  END GENERATE;    
    

  
  
  
  
--*********************
--*** Theta SECTION ***
--*********************
  
  prc_theta: PROCESS (sysclk,reset) 
  BEGIN
  
    IF (reset = '1') THEN  
      thetaff <= conv_std_logic_vector (0,m_bits);
    ELSIF (rising_edge(sysclk)) THEN   
      IF (enable = '1') THEN
        IF (start_bm = '1') THEN
            thetaff <= thetain;
        ELSIF (stateff(1) = '1') THEN
          thetaff <= thetaoutnode;
        END IF;
      END IF;
    END IF;
  END PROCESS;

  gen_theta_out: FOR k IN 1 TO m_bits GENERATE
    thetaoutnode(k) <= (delta_current(k) AND statefornode) OR
                       (thetaff(k) AND NOT(statefornode));
  END GENERATE;
  
  
  
  
--****************
--*** COUNTERS ***
--****************

  prc_count: PROCESS (sysclk,reset)
  BEGIN
      
    IF (reset = '1') THEN
        
      llnumberff     <= conv_std_logic_vector(0,errorcnt_width);
      mloopff        <=  conv_std_logic_vector(0,checkcnt_width);
      chktlm_r        <= conv_std_logic_vector(0,checkcnt_width);

    ELSIF (rising_edge(sysclk)) THEN
    
      IF (enable = '1') THEN

        IF (start_bm = '1') THEN
          chktlm_r <= chktlmin;
          llnumberff <= llnumberin;
          mloopff <= startloopnumber;
        ELSIF (stateff(1) = '1') THEN            
          chktlm_r <= chktlmnode_r;
          llnumberff <= lloutnode;
          mloopff <= mloopplusone;
        END IF;

      END IF;
    
    END IF;
    
  END PROCESS;
  
  llnextnumber <= mloopff(errorcnt_width DOWNTO 1) + 1 - llnumberff;
  mloopplusone <= mloopff + 1;
  chktlmplus_diff <=  mloopff - (llnumberff(checkcnt_width-1 DOWNTO 1) & '0');
  chktlmplus <= ( '0' & chktlm_r) + (chktlmplus_diff & '0') + 1;
  chktlmminusone <= chktlm_r -1;
  gen_chktlm : FOR k IN 1 TO checkcnt_width GENERATE              
    chktlmnode_r(k) <= (chktlmplus(k) AND statefornode) OR
                   (chktlmminusone(k) AND NOT(statefornode));
  END GENERATE;
  
  

  -- 2L <= m?
  chktlm <= (llnumberff(checkcnt_width-1 DOWNTO 1) & '0') - mloopff - 1;
  tlm <= chktlm(checkcnt_width);
  tlm_r <= chktlm_r(checkcnt_width);
  
  
  gen_ll_out: FOR k IN 1 TO errorcnt_width GENERATE
    lloutnode(k) <= (llnextnumber(k) AND statefornode) OR
                    (llnumberff(k) AND NOT(statefornode));
  END GENERATE;
  
  -- lastloop_node(1) <= (mloopff(1) XOR endloopnumber(1));
  -- gen_lll_out: FOR k IN 2 TO checkcnt_width GENERATE
    -- lastloop_node(k) <= lastloop_node(k-1) OR (mloopff(k) XOR endloopnumber(k));
  -- END GENERATE;
  -- lastloop <= NOT(lastloop_node(checkcnt_width));
                  
  lastloop <= roundff(endloop-startloop+1);

  
  
--***************
--*** OUTPUTS ***
--***************

llnumberout <= lloutnode;
nextstage <= stateff(1) AND lastloop;
bm_ready <= is_bm_ready;
bdsout <= bdsoutnode;
bdsprevout <= bdsprevoutnode;
deltaXout <= new_deltaXff;
deltaXprevout <= deltaXprev_node;
chktlmout <= chktlmnode_r;
thetaout <= thetaoutnode;

END rtl;
  
 