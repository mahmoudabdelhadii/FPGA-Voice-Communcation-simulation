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
--***   2 Clocks per Round Systolic PE            ***
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

ENTITY rsx_bm_pe2 IS 
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
END rsx_bm_pe2;

ARCHITECTURE rtl OF rsx_bm_pe2 IS

  constant is_error_sup : integer := is_a_strict_sup_b(error_symbols,endloop+1);
  constant systolic_symbols : integer := (1-is_error_sup)*error_symbols + is_error_sup*(endloop+1) +  riBm;
  type systolictype IS ARRAY (systolic_symbols DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  
  -- state machine section
  signal stateff          : STD_LOGIC_VECTOR (2 DOWNTO 1);
  signal roundffnode      : STD_LOGIC_VECTOR (check_symbols DOWNTO 1);
  signal nextroundffnode  : STD_LOGIC_VECTOR (check_symbols DOWNTO 1);
  signal roundff,roundff2 : STD_LOGIC_VECTOR (endloop-startloop+1 DOWNTO 1);
  signal statefornode     : STD_LOGIC_VECTOR (check_symbols DOWNTO 1);
  attribute noprune : boolean;
  attribute noprune of statefornode: signal is true;
  
  -- sigma section
  signal bdff                       : systolictype;
  signal bdprevff                   : systolictype;
  signal bdsoutnode                 : errorvector;
  signal bdsprevoutnode             : errorvector;
  signal next_bdsprevout            : systolictype;
  signal bdprevff_shift             : errorvector;
  signal mulout_bd, mulout_bdprev   : systolictype;
  signal mulout_bdff, mulout_bdprevff   : systolictype;
  
  -- delta section
  signal deltaXff                          : syndromevector;
  signal new_deltaX                        : syndromevector;
  signal deltaXprevff                      : syndromevector; 
  signal new_deltaXprev                    : syndromevector;  
  signal deltaX_node                       : syndromevector;  
  signal deltaXprev_shift                  : syndromevector; 
  signal thetaff, thetaff2                 : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal thetaoutnode                      : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal delta_current,delta_current2      : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal deltazero                         : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal mulout_deltaX, mulout_deltaXprev  : syndromevector;
  signal mulout_deltaXff, mulout_deltaXprevff  : syndromevector;
  
  

  signal llnumberff,llnumberff2        : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  signal mloopff,mloopff2               : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal startloopnumber                : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal mloopplusone                   : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal chktlm                         : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal chktlm_r,chktlm_r2             : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal chktlmnode_r                   : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal chktlmplus                     : STD_LOGIC_VECTOR (checkcnt_width+1 DOWNTO 1);
  signal chktlmplus_diff                : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal chktlmminusone                 : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal tlm                            : STD_LOGIC;
  signal tlm_r                          : STD_LOGIC;
  signal lastloop, lastloop2            : STD_LOGIC;
  signal lastloop_node                  : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal llnextnumber                   : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  signal lloutnode                      : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  

  -- backpressure section
  signal deltaXin_fp0, deltaXin_fp      : syndromevector;
  signal deltaXprevin_fp                : syndromevector;
  signal start_fp, start_fp0            : STD_LOGIC;
  signal data_in_loaded                 : STD_LOGIC;
  signal not_ready_for_new_syndrome     : STD_LOGIC;
  signal bm_is_ready                    : STD_LOGIC;
  

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



--*****************************
--*** FORWARD PRESSURE      ***
--*****************************
-- if input data is valid at the wrong moment
-- it is stored in a register and fed in at 
-- the next clock cycle
first_BM_fp : IF (startloop = 0) GENERATE

    prc_fp: PROCESS (sysclk,reset)
    BEGIN

      IF (reset = '1') THEN
      
        FOR k IN 1 TO m_bits LOOP
          FOR j IN 1 TO check_symbols LOOP
            deltaXin_fp0(j)(k) <= '0';
          END LOOP;
        END LOOP;
        data_in_loaded <= '0';
        not_ready_for_new_syndrome <= '0';
        
      ELSIF (rising_edge(sysclk)) THEN
        
        IF (enable = '1') THEN

          IF (bm_is_ready = '1') THEN
              deltaXin_fp0 <= deltaXin;
          END IF;

          data_in_loaded <= (start AND (not_ready_for_new_syndrome XOR data_in_loaded))  OR (not_ready_for_new_syndrome AND data_in_loaded);
          not_ready_for_new_syndrome <= stateff(1) AND NOT(lastloop);
          
        END IF;
      
      END IF;

    END PROCESS;

    bm_is_ready <= NOT (data_in_loaded AND not_ready_for_new_syndrome);
    
    
    start_fp <= (start OR data_in_loaded )   AND NOT(not_ready_for_new_syndrome)  ;
  
    gen_stage_one: FOR k IN 1 TO m_bits GENERATE
      gen_stage_two_synd: FOR j IN 1 TO check_symbols GENERATE 
        deltaXin_fp(j)(k) <= (deltaXin_fp0(j)(k) AND data_in_loaded) OR
                                 (deltaXin(j)(k) AND NOT(data_in_loaded));
      END GENERATE;    
    END GENERATE;
    deltaXprevin_fp <= deltaXin_fp;

  
END GENERATE;

notfirst_BM_fp : IF (startloop > 0) GENERATE
  deltaXin_fp    <= deltaXin;
  deltaXprevin_fp <= deltaXprevin;
  start_fp       <= start;
END GENERATE;

--*****************************
--*** STATE MACHINE SECTION ***
--*****************************

prc_ctl: PROCESS (sysclk,reset)
BEGIN

  IF (reset = '1') THEN    
  
    stateff <= "00";
    roundff <= conv_std_logic_vector(0,endloop-startloop+1);
    roundff2 <= conv_std_logic_vector(0,endloop-startloop+1);
    statefornode <= conv_std_logic_vector(0,check_symbols);
    
    
  ELSIF (rising_edge(sysclk)) THEN
    
    IF (enable = '1') THEN

      stateff(1) <= start_fp OR (stateff(2) AND NOT(lastloop2));
      stateff(2) <= stateff(1);
      
      IF (start_fp = '1') THEN
        roundff(1) <= '1';
        roundff(endloop-startloop+1 downto 2) <= conv_std_logic_vector(0,endloop-startloop);
      ELSIF(stateff(2) = '1' AND endloop/=startloop) THEN
        roundff(1) <=  '0';
        roundff(endloop-startloop+1 downto 2) <= roundff2(endloop-startloop downto 1);
      END IF;
      roundff2 <= roundff;
      
      FOR k IN 1 TO check_symbols LOOP
        statefornode(k) <= deltazero(m_bits) AND tlm;
      END LOOP;
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


--************************
--*** Delta SECTION ***
--************************

  prc_syn: PROCESS (sysclk,reset)
  BEGIN
  
    IF (reset = '1') THEN
    
      deltaXff            <= (others => (others => '0'));
      deltaXprevff        <= (others => (others => '0'));
      new_deltaXprev     <= (others => (others => '0'));
      mulout_deltaXff     <= (others => (others => '0'));
      mulout_deltaXprevff <= (others => (others => '0'));
      
    ELSIF (rising_edge(sysclk)) THEN
    
      IF (enable = '1') THEN

        IF (start_fp = '1' OR stateff(2) = '1') THEN
          FOR k IN 1 TO check_symbols-1 LOOP
            FOR m IN 1 TO m_bits LOOP
              deltaXff(k)(m) <= (deltaXin_fp(k+1)(m) AND start_fp) OR
                                 (new_deltaX(k+1)(m) AND NOT(start_fp));
              deltaXprevff(k)(m) <= (deltaXprevin_fp(k+1)(m) AND start_fp) OR
                                 (new_deltaXprev(k+1)(m) AND NOT(start_fp));
            END LOOP;
          END LOOP;
          FOR m IN 1 TO m_bits LOOP
            deltaXff(check_symbols)(m) <= (deltaXin_fp(1)(m) AND start_fp) OR
                                           (new_deltaX(1)(m) AND NOT(start_fp));
            deltaXprevff(check_symbols)(m) <= (deltaXprevin_fp(1)(m) AND start_fp) OR
                                           (new_deltaXprev(1)(m) AND NOT(start_fp));
          END LOOP; 
        END IF;
        
        mulout_deltaXff <= mulout_deltaX;
        mulout_deltaXprevff <= mulout_deltaXprev;
        
        gen_stage_deltaprev: FOR k IN 1 TO check_symbols LOOP
          IF (deltazero(m_bits) = '1' AND tlm = '1') THEN
            new_deltaXprev(k) <= deltaXff(k);
          ELSE
            new_deltaXprev(k) <= deltaXprev_shift(k);
          END IF;
        END LOOP;
        
      END IF;
      
    END IF;
 
  END PROCESS;
  

  delta_current <= deltaXff(1);
  deltazero(1) <= delta_current(1);
  gen_delta_zipr: FOR k IN 2 TO m_bits GENERATE
    deltazero(k) <= delta_current(k) OR deltazero(k-1);
  END GENERATE;
  
  prc_delta_current: PROCESS (sysclk,reset) 
  BEGIN
    IF (reset = '1') THEN  
      delta_current2  <= conv_std_logic_vector (0,m_bits);
    ELSIF (rising_edge(sysclk)) THEN   
      IF (enable = '1') THEN
        delta_current2 <= delta_current;
      END IF;
    END IF;
  END PROCESS;
  
  -- before the input of stage 0, rotate syndromes the other way externally  
  shift_deltaX: FOR i IN 1 TO m_bits GENERATE
    shift_deltaX_k: FOR k IN 1 TO check_symbols-1 GENERATE
      deltaXprev_shift(k+1)(i) <= deltaXprevff(k)(i) AND NOT(roundffnode(check_symbols-k+1));
    END GENERATE;
    deltaXprev_shift(1)(i) <= deltaXprevff(check_symbols)(i) AND NOT(roundffnode(1));
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
              
    new_deltaX(k) <=  mulout_deltaXff(k) XOR  mulout_deltaXprevff(k);
              
  END GENERATE;
  
  
  
--******************
--*** Sigma SECTION ***
--******************

  prc_bd: PROCESS (sysclk,reset)
  BEGIN
      
    IF (reset = '1') THEN

      bdff       <= (others=>(others=>'0'));
      bdprevff   <= (others=>(others=>'0'));
      next_bdsprevout    <= (others=>(others=>'0'));
      mulout_bdff        <= (others=>(others=>'0'));
      mulout_bdprevff    <= (others=>(others=>'0'));

    ELSIF (rising_edge(sysclk)) THEN
    
      IF (enable = '1') THEN
        
        IF (start_fp = '1' OR stateff(2) = '1') THEN
          FOR k IN 1 TO systolic_symbols LOOP
            FOR m IN 1 TO m_bits LOOP
              bdff(k)(m) <= (bdsin(k)(m) AND start_fp) OR
                            (bdsoutnode(k)(m) AND NOT(start_fp));
              bdprevff(k)(m) <= (bdsprevin(k)(m) AND start_fp) OR
                                (bdsprevoutnode(k)(m) AND NOT(start_fp));
            END LOOP;
          END LOOP;
        END IF;
        
        mulout_bdff <= mulout_bd;
        mulout_bdprevff <= mulout_bdprev;
        
        gen_stage_bdprev: FOR k IN 1 TO systolic_symbols LOOP
          IF (deltazero(m_bits) = '1' AND tlm = '1') THEN
            next_bdsprevout(k) <= bdff(k);
          ELSE
            next_bdsprevout(k) <= bdprevff_shift(k);
          END IF;
        END LOOP;        
        
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
  
  bdsoutnode(1) <= mulout_bdff(1);
  gen_sum_bd: FOR k IN 2 TO systolic_symbols GENERATE
    bdsoutnode(k) <=  mulout_bdff(k) XOR  mulout_bdprevff(k-1);   
  END GENERATE; 
  
  gen_stage_bdprev: FOR k IN 1 TO systolic_symbols GENERATE
    bdsprevoutnode(k) <= next_bdsprevout(k);
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
      thetaff  <= conv_std_logic_vector (0,m_bits);
      thetaff2 <= conv_std_logic_vector (0,m_bits);
    ELSIF (rising_edge(sysclk)) THEN   
      IF (enable = '1') THEN
        IF (start_fp = '1') THEN
            thetaff <= thetain;
        ELSIF (stateff(2) = '1') THEN
          thetaff <= thetaoutnode;
        END IF;
        thetaff2 <= thetaff;
      END IF;
      
    END IF;
  END PROCESS;

  gen_theta_out: FOR k IN 1 TO m_bits GENERATE
    thetaoutnode(k) <= (delta_current2(k) AND statefornode(((k-1) mod check_symbols) + 1)) OR
                       (thetaff2(k) AND NOT(statefornode(((k-1) mod check_symbols) + 1  )));
  END GENERATE;
  
  
  
  
--****************
--*** COUNTERS ***
--****************

  prc_count: PROCESS (sysclk,reset)
  BEGIN
      
    IF (reset = '1') THEN
        
      llnumberff      <= conv_std_logic_vector(0,errorcnt_width);
      llnumberff2     <= conv_std_logic_vector(0,errorcnt_width);
      mloopff         <=  conv_std_logic_vector(0,checkcnt_width);
      mloopff2        <=  conv_std_logic_vector(0,checkcnt_width);
      chktlm_r        <= conv_std_logic_vector(0,checkcnt_width);
      chktlm_r2       <= conv_std_logic_vector(0,checkcnt_width);
      --chktlmplus_diff  <= conv_std_logic_vector(0,checkcnt_width);

    ELSIF (rising_edge(sysclk)) THEN
    
      IF (enable = '1') THEN

        IF (start_fp = '1') THEN
          chktlm_r <= chktlmin;
          llnumberff <= llnumberin;
          mloopff <= startloopnumber;
        ELSIF (stateff(2) = '1') THEN            
          chktlm_r <= chktlmnode_r;
          llnumberff <= lloutnode;
          mloopff <= mloopplusone;
        END IF;
        
        llnumberff2 <= llnumberff;
        mloopff2    <= mloopff;
        chktlm_r2   <= chktlm_r;
        
      END IF;
    
    END IF;
    
  END PROCESS;
  
  llnextnumber <= mloopff2(errorcnt_width DOWNTO 1) + 1 - llnumberff2;
  mloopplusone <= mloopff2 + 1;
  
  chktlmplus_diff <=  mloopff2 - (llnumberff2(checkcnt_width-1 DOWNTO 1) & '0');
  chktlmplus <= ( '0' & chktlm_r2) + (chktlmplus_diff & '0') + 1;
  chktlmminusone <= chktlm_r2 - 1;
  gen_chktlm : FOR k IN 1 TO checkcnt_width GENERATE              
    chktlmnode_r(k) <= (chktlmplus(k) AND statefornode(k)) OR
                   (chktlmminusone(k) AND NOT(statefornode(k)));
  END GENERATE;
  
  

  -- 2L <= m?
  chktlm <= (llnumberff(checkcnt_width-1 DOWNTO 1) & '0') - mloopff - 1;
  tlm    <= chktlm(checkcnt_width);
  tlm_r  <= chktlm_r(checkcnt_width);
  
  
  gen_ll_out: FOR k IN 1 TO errorcnt_width GENERATE
    lloutnode(k) <= (llnextnumber(k) AND statefornode(k)) OR
                    (llnumberff2(k) AND NOT(statefornode(k)));
  END GENERATE;
  
  lastloop <= roundff(endloop-startloop+1);
  lastloop2 <= roundff2(endloop-startloop+1);
  
  
  
--***************
--*** OUTPUTS ***
--***************

llnumberout <= lloutnode;
nextstage <= stateff(2) AND lastloop2;
bm_ready <= bm_is_ready;
bdsout <= bdsoutnode;
bdsprevout <= bdsprevoutnode;
deltaXout <= new_deltaX;
deltaXprevout <= new_deltaXprev;
chktlmout <= chktlmnode_r;
thetaout <= thetaoutnode;

END rtl;
  
 