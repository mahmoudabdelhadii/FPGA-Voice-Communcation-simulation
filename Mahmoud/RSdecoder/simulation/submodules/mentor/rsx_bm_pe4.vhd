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
--***   RSX_BM_PE4                                ***
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

ENTITY rsx_bm_pe4 IS 
GENERIC (
         startloop : integer := 2;
         endloop : integer := 6
        ); -- mloop: 0 to check_symbols-1
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      start : IN STD_LOGIC; -- start this stage
      syndromesin : IN syndromevector;
      bdsin, bdsprevin : IN errorvector;
      llnumberin : IN STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
      deltain : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);
      
      syndromesout : OUT syndromevector;
      bdsout, bdsprevout : OUT errorvector;
      llnumberout : OUT STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
      deltaout : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
      nextstage : OUT STD_LOGIC; -- start for next level
      bm_ready : OUT STD_LOGIC;
      get_inv_of : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
      get_inv_of_valid : OUT STD_LOGIC;
      value_of_inv : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1)
        );
END rsx_bm_pe4;

ARCHITECTURE rtl OF rsx_bm_pe4 IS

  constant is_error_sup : integer := is_a_strict_sup_b(error_symbols,endloop+1);
  constant systolic_symbols : integer := (1-is_error_sup)*error_symbols + is_error_sup*(endloop+1);

  type systolictype IS ARRAY (systolic_symbols DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  -- state machine section
  signal stateff      : STD_LOGIC_VECTOR (4 DOWNTO 1);
  signal statethrff   : STD_LOGIC;
  signal statethrnode : STD_LOGIC;
  signal statefornode : STD_LOGIC;
  -- syndromes section
  signal syndromesff   : syndromevector;
  signal syndromesff_2 : syndromevector;
  signal syndromesnode : syndromevector;
  -- bd section
  signal bdff, bdff_2               : systolictype;
  signal bdprevff, bdprevff_2       : systolictype;
  signal bdsoutnode, bdsprevoutnode : errorvector;
  signal onenode                    : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  -- core section
  signal syndrome_select       : STD_LOGIC_VECTOR (systolic_symbols DOWNTO 1);
  signal deltaleft, deltaright : systolictype;
  signal bdleft, bdright       : systolictype;
  signal addvector             : systolictype;
  signal mulleftff, mulrightff : systolictype;
  signal mulout                : systolictype;
  signal mulsum                : systolictype;
  -- delta section
  signal deltaff, deltaprevff              : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal deltaff_pipe, deltaprevff_2       : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal invdeltaprevnode, invdeltaprevff_alms  : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal invdeltaprevff_rom                : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal invdeltaprevff                    : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal deltamultnode                     : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal deltazero                         : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal deltaoutnode                      : STD_LOGIC_VECTOR (m_bits DOWNTO 1);

  signal llnumberff   : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  signal llnumberff_2 : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  signal mloopff      : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal mloopff_2    : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal startloopnumber, endloopnumber : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal mloopplusone                   : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal chktlm                         : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal tlm                            : STD_LOGIC;
  signal lastloop                       : STD_LOGIC;
  signal lastloop_node                  : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal lastloopff                     : STD_LOGIC;
  signal llnextnumberff                 : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  signal lloutnode                      : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  
  -- fp section
  signal syndromesin_fp, syndromesin_fp0 : syndromevector;
  signal bdsin_fp                        : errorvector;
  signal bdsprevin_fp                    : errorvector;
  signal llnumberin_fp                   : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  signal deltain_fp                      : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal start_fp, start_fp0             : STD_LOGIC;
  signal data_in_loaded                  : STD_LOGIC;
  signal not_ready_for_new_syndrome      : STD_LOGIC;
  signal bm_is_ready                     : STD_LOGIC;
  
  
  
  
  component rsx_gf_inv
  PORT (
            aa : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);
            cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
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

    component rsp_gf_add  
  GENERIC (m_bits : positive := 8);
  PORT (
        aa, bb : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);
        cc : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
        );
  end component;
  
  component rsp_unary 
  GENERIC (
           inwidth : positive := 8;
           outwidth : positive := 8
          );
  PORT (
        inbus : IN STD_LOGIC_VECTOR (inwidth DOWNTO 1);
        outbus : OUT STD_LOGIC_VECTOR (outwidth DOWNTO 1)
        );
  end component;
         
BEGIN

startloopnumber <= conv_std_logic_vector (startloop,checkcnt_width);
endloopnumber <= conv_std_logic_vector (endloop,checkcnt_width);



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
            syndromesin_fp0(j)(k) <= '0';
          END LOOP;
        END LOOP;
        data_in_loaded <= '0';
        not_ready_for_new_syndrome <= '0';
        
      ELSIF (rising_edge(sysclk)) THEN
        
        IF (enable = '1') THEN

          IF (bm_is_ready = '1') THEN
            FOR j IN 1 TO check_symbols LOOP
              syndromesin_fp0(j) <= syndromesin(j);
            END LOOP;
          END IF;

          data_in_loaded <= (start AND (not_ready_for_new_syndrome XOR data_in_loaded))  OR (not_ready_for_new_syndrome AND data_in_loaded);
          
          not_ready_for_new_syndrome <= (stateff(1) OR (stateff(3) AND NOT(lastloop))  );
          
        END IF;
      
      END IF;

    END PROCESS;

    bm_is_ready <= NOT (data_in_loaded AND not_ready_for_new_syndrome);
    
    
    start_fp <= (start OR data_in_loaded )   AND NOT(not_ready_for_new_syndrome)  ;
  
    gen_stage_one: FOR k IN 1 TO m_bits GENERATE
      gen_stage_two_synd: FOR j IN 1 TO check_symbols GENERATE 
        syndromesin_fp(j)(k) <= (syndromesin_fp0(j)(k) AND data_in_loaded) OR
                                 (syndromesin(j)(k) AND NOT(data_in_loaded));
      END GENERATE;    
    END GENERATE;

  
END GENERATE;

notfirst_BM_fp : IF (startloop > 0) GENERATE
  syndromesin_fp <= syndromesin;
  start_fp       <= start;
END GENERATE;

  bdsin_fp       <= bdsin;
  bdsprevin_fp   <= bdsprevin;
  deltain_fp     <= deltain;
  llnumberin_fp  <= llnumberin;



--*****************************
--*** STATE MACHINE SECTION ***
--*****************************

prc_ctl: PROCESS (sysclk,reset)
BEGIN

  IF (reset = '1') THEN    
  
    stateff <= "0000";
    statethrff <= '0';
    
  ELSIF (rising_edge(sysclk)) THEN
    
    IF (enable = '1') THEN

      stateff(1) <= start_fp OR (stateff(4) AND NOT(lastloopff));
      FOR k IN 2 TO 4 LOOP
        stateff(k) <= stateff(k-1);
      END LOOP;
      
      statethrff <= statethrnode;
      
    END IF;
  
  END IF;
    
END PROCESS;

statethrnode <= deltazero(m_bits);
statefornode <= statethrff AND tlm;

-- stateff(1) - always active, loads mulleftff mulrightff
-- stateff(2) - always active, loads deltaff
-- stateff(3) - bdtemp = bd
   -- if deltaff !=0 => statethrnode = 1 
-- stateff(4) - if statethrff => bdout = addvec else bdout = bdff
   -- if statethrff AND 2L<m => statefornode = 1
   -- if statefornode => llout=m+1-L else llout = llff
   -- if statefornode => i=1 else ??
   -- if statefornode => bdpout=bdtemp (and shift) else bdpout=bdpff
   -- if statefornode => deltaout=deltaff else olddeltaff
 
    --s1  = B"0000000000000001", -- load syndromes
    --s2  = B"0000001110000000",  -- calc new delta = Sm + (series)B(j)*S(m-j), shift BDprev
    --s77 = B"0000001000000000",  -- 1 pipe stage to top of gfmuls
    --s3  = B"0000000000000000",  -- if new delta <> 0, calc new BD

    --s4  = B"0000000000001000",  -- TD = BD, BD = BD - deltamult*(D^i)*BDprev
    --s5  = B"0000000000000010",  -- load BD, check 2L <= m?
    --s6  = B"0000010000000100",  -- L = m+1-L, i=1, BDprev = BDtemp, olddelta = delta

    --s8  = B"0000100000010000",  -- inc mloop, shift synregs left

--************************
--*** SYNDROME SECTION ***
--************************

  prc_syn: PROCESS (sysclk,reset)
  BEGIN
  
    IF (reset = '1') THEN
    
      FOR j IN 1 TO check_symbols LOOP
        FOR k IN 1 TO m_bits LOOP
          syndromesff(j)(k)   <= '0';
          syndromesff_2(j)(k) <= '0';
        END LOOP;
      END LOOP;
    
    ELSIF (rising_edge(sysclk)) THEN
    
      IF (enable = '1') THEN
      
        FOR k IN 1 TO check_symbols LOOP
          FOR j IN 1 TO m_bits LOOP
            IF (start_fp = '1' OR stateff(4) = '1') THEN
              syndromesff(k)(j) <= syndromesnode(k)(j);
            ELSE
              syndromesff(k)(j) <= syndromesff_2(k)(j);
            END IF;
            
            syndromesff_2(k)(j) <= syndromesff(k)(j);
            
          END LOOP;
        END LOOP;
        
      END IF;
      
    END IF;
 
  END PROCESS;

  -- before the input of stage 0, rotate syndromes the other way externally
  gen_stage_one: FOR k IN 1 TO check_symbols-1 GENERATE
    gen_stage_two: FOR m IN 1 TO m_bits GENERATE
      syndromesnode(k)(m) <= (syndromesin_fp(k+1)(m) AND start_fp) OR
                             (syndromesff_2(k+1)(m) AND NOT(start_fp));
    END GENERATE;
  END GENERATE;
  gen_stage_thr: FOR m IN 1 TO m_bits GENERATE
    syndromesnode(check_symbols)(m) <= (syndromesin_fp(1)(m) AND start_fp) OR
                                       (syndromesff_2(1)(m) AND NOT(start_fp));
  END GENERATE; 
  
  
  
--******************
--*** BD SECTION ***
--******************

  prc_bd: PROCESS (sysclk,reset)
  BEGIN
      
    IF (reset = '1') THEN

      FOR j IN 1 TO systolic_symbols LOOP
        FOR k IN 1 TO m_bits LOOP
          bdff(j)(k)       <= '0';
          bdff_2(j)(k)     <= '0';
          bdprevff(j)(k)   <= '0';
          bdprevff_2(j)(k) <= '0';
        END LOOP;
      END LOOP;
      
    ELSIF (rising_edge(sysclk)) THEN
    
      IF (enable = '1') THEN
         
        IF (start_fp = '1' OR stateff(4) = '1') THEN
          FOR k IN 1 TO systolic_symbols LOOP
            FOR m IN 1 TO m_bits LOOP
              bdff(k)(m) <= (bdsin_fp(k)(m) AND start_fp) OR
                            (bdsoutnode(k)(m) AND NOT(start_fp));
            END LOOP;
          END LOOP;
        ELSE
          bdff <= bdff_2;
        END IF;
        
        bdff_2 <= bdff;
        
        
        IF (start_fp = '1' OR stateff(4) = '1') THEN
          FOR k IN 1 TO systolic_symbols LOOP
            FOR m IN 1 TO m_bits LOOP
              bdprevff(k)(m) <= (bdsprevin_fp(k)(m) AND start_fp) OR
                                (bdsprevoutnode(k)(m) AND NOT(start_fp));
            END LOOP;
          END LOOP;
        ELSE
          bdprevff <= bdprevff_2;
        END IF;
        bdprevff_2 <= bdprevff;
      END IF;
      
    END IF;
    
  END PROCESS;
  
  onenode <= conv_std_logic_vector(1,m_bits);
  
  gen_bdout_one: IF (systolic_symbols = error_symbols) GENERATE
    gen_bdout_two: FOR k IN 1 TO error_symbols GENERATE
      gen_bdout_thr: FOR j IN 1 TO m_bits GENERATE
        bdsoutnode(k)(j) <= (addvector(k)(j) AND statethrff) OR
                            (bdff_2(k)(j) AND NOT(statethrff));
      END GENERATE;
    END GENERATE;
  END GENERATE;
  
  gen_bdout_for: IF (systolic_symbols < error_symbols) GENERATE
    gen_bdout_fiv: FOR k IN 1 TO systolic_symbols GENERATE
      gen_bdout_six: FOR j IN 1 TO m_bits GENERATE
        bdsoutnode(k)(j) <= (addvector(k)(j) AND statethrff) OR
                            (bdff_2(k)(j) AND NOT(statethrff));
      END GENERATE;
      gen_bdout_sev: FOR k IN systolic_symbols+1 TO error_symbols GENERATE
          bdsoutnode(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      END GENERATE;
    END GENERATE;
  END GENERATE;  
    
  gen_bdprevout_one: FOR j IN 1 TO m_bits GENERATE
    bdsprevoutnode(1)(j) <= (onenode(j) AND statefornode);
  END GENERATE;
  
  gen_bdprevout_two: IF (systolic_symbols = error_symbols) GENERATE
    gen_bdprevout_thr: FOR k IN 2 TO error_symbols GENERATE
      gen_bdprevout_for: FOR j IN 1 TO m_bits GENERATE
        bdsprevoutnode(k)(j) <= (bdff_2(k-1)(j) AND statefornode) OR
                                (bdprevff_2(k-1)(j) AND NOT(statefornode));
      END GENERATE;
    END GENERATE;  
  END GENERATE;
  
  -- vectorsize must be 2 less than error_symbols
  gen_bdprevout_fiv: IF (systolic_symbols < error_symbols) GENERATE
    gen_bdprevout_six: FOR k IN 2 TO systolic_symbols+1 GENERATE
      gen_bdprevout_sev: FOR j IN 1 TO m_bits GENERATE
        bdsprevoutnode(k)(j) <= (bdff_2(k-1)(j) AND statefornode) OR
                                (bdprevff_2(k-1)(j) AND NOT(statefornode));
      END GENERATE;
    END GENERATE;  
    gen_bdprevout_egt: FOR k IN systolic_symbols+2 TO error_symbols GENERATE
        bdsprevoutnode(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
    END GENERATE;  
  END GENERATE;

--********************
--*** CORE SECTION ***
--********************

  csynsel: rsp_unary
  GENERIC MAP (inwidth=>errorcnt_width_o,outwidth=>systolic_symbols)
  PORT MAP (inbus=>llnumberff(errorcnt_width_o DOWNTO 1),outbus=>syndrome_select);
        
  gen_mulmux_one: FOR j IN 1 TO systolic_symbols GENERATE
    gen_mulmux_two: FOR k IN 1 TO m_bits GENERATE
      deltaleft(j)(k)  <= syndromesff(check_symbols+1-j)(k) AND syndrome_select(j);
      deltaright(j)(k) <= bdff(j)(k);
    END GENERATE;
  END GENERATE;
  
  gen_mulmux_thr: FOR j IN 1 TO systolic_symbols GENERATE
    gen_mulmux_for: FOR k IN 1 TO m_bits GENERATE
      bdleft(j)(k)  <= bdprevff(j)(k);
      bdright(j)(k) <= deltamultnode(k);
    END GENERATE;
  END GENERATE;

  gen_adder: FOR j IN 1 TO systolic_symbols GENERATE
    gfac: rsp_gf_add
    GENERIC MAP (m_bits=>m_bits)
    PORT MAP (aa=>bdff_2(j)(m_bits DOWNTO 1),bb=>mulout(j)(m_bits DOWNTO 1),
              cc=>addvector(j)(m_bits DOWNTO 1));
  END GENERATE;

  prc_mul: PROCESS (sysclk,reset) 
  BEGIN
  
    IF (reset = '1') THEN
        
      FOR j IN 1 TO systolic_symbols LOOP
        FOR k IN 1 TO m_bits LOOP
          mulleftff(j)(k)  <= '0';
          mulrightff(j)(k) <= '0';
        END LOOP;
      END LOOP;
          
    ELSIF (rising_edge(sysclk)) THEN
            
      IF (enable = '1') THEN
      
        FOR j IN 1 TO systolic_symbols LOOP
          FOR k IN 1 TO m_bits LOOP
            mulleftff(j)(k) <= (deltaleft(j)(k) AND stateff(1)) OR
                               (bdleft(j)(k) AND NOT(stateff(1)));
            mulrightff(j)(k) <= (deltaright(j)(k) AND stateff(1)) OR
                                (bdright(j)(k) AND NOT(stateff(1)));
          END LOOP;
        END LOOP;
    
      END IF;
      
    END IF;

  END PROCESS;
  
  gen_mul: FOR k IN 1 TO systolic_symbols GENERATE
    gfma: rsp_gf_mul 
    GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
    PORT MAP (aa=>mulleftff(k)(m_bits DOWNTO 1),bb=>mulrightff(k)(m_bits DOWNTO 1),
              cc=>mulout(k)(m_bits DOWNTO 1));
  END GENERATE;

  -- calculate new delta
  gen_muladd_one: FOR k IN 1 TO m_bits GENERATE
    mulsum(1)(k) <= mulout(1)(k) XOR syndromesff_2(1)(k);
  END GENERATE;
  gen_muladd_two: FOR j IN 2 TO systolic_symbols GENERATE
    gen_muladd_thr: FOR k IN 1 TO m_bits GENERATE
      mulsum(j)(k) <= mulout(j)(k) XOR mulsum(j-1)(k); 
      END GENERATE;
  END GENERATE;
  
  
  
--*********************
--*** DELTA SECTION ***
--*********************
  
  prc_delta: PROCESS (sysclk,reset) 
  BEGIN
  
    IF (reset = '1') THEN
        
      FOR k IN 1 TO m_bits LOOP
        deltaff(k)        <= '0';
        deltaff_pipe(k)   <= '0';
        deltaprevff(k)    <= '0';
        deltaprevff_2(k)  <= '0';
      END LOOP;
          
    ELSIF (rising_edge(sysclk)) THEN
            
      IF (enable = '1') THEN
        
        deltaff      <= mulsum(systolic_symbols)(m_bits DOWNTO 1);
        deltaff_pipe <= deltaff;
        
        IF (start_fp = '1' OR stateff(4) = '1') THEN
          FOR m IN 1 TO m_bits LOOP  
            deltaprevff(m) <= (deltain_fp(m) AND start_fp) OR
                              (deltaoutnode(m) AND NOT(start_fp));
          END LOOP;
        ELSE
            deltaprevff <= deltaprevff_2;
        END IF;
        
        deltaprevff_2 <= deltaprevff;
        
        
      END IF;
      
    END IF;
    
  END PROCESS;
  
  get_inv_of <= deltaprevff;
  get_inv_of_valid <= stateff(1);
  invdeltaprevff <= value_of_inv;

  
  cdmul: rsp_gf_mul 
  GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  PORT MAP (aa=>deltaff,bb=>invdeltaprevff,
            cc=>deltamultnode);
  
  deltazero(1) <= deltaff(1);
  gen_delta_zip: FOR k IN 2 TO m_bits GENERATE
    deltazero(k) <= deltaff(k) OR deltazero(k-1);
  END GENERATE;
  
  gen_delta_out: FOR k IN 1 TO m_bits GENERATE
    deltaoutnode(k) <= (deltaff_pipe(k) AND statefornode) OR
                       (deltaprevff_2(k) AND NOT(statefornode));
  END GENERATE;
  
  
  
  
--****************
--*** COUNTERS ***
--****************

  prc_count: PROCESS (sysclk,reset)
  BEGIN
      
    IF (reset = '1') THEN
        
      llnumberff     <= conv_std_logic_vector(0,errorcnt_width);
      llnumberff_2   <= conv_std_logic_vector(0,errorcnt_width);
      llnextnumberff <= conv_std_logic_vector(0,errorcnt_width);
      mloopff        <= conv_std_logic_vector(0,checkcnt_width);
      mloopff_2      <= conv_std_logic_vector(0,checkcnt_width);
      lastloopff     <= '0';
      
    ELSIF (rising_edge(sysclk)) THEN
    
      IF (enable = '1') THEN
        
        IF (start_fp = '1' OR stateff(4) = '1') THEN  
          FOR k IN 1 TO errorcnt_width LOOP
            llnumberff(k) <= (llnumberin_fp(k) AND start_fp) OR
                             (lloutnode(k) AND NOT(start_fp));
          END LOOP;
        ELSE
          llnumberff <= llnumberff_2;
        END IF;
        llnumberff_2 <= llnumberff;
        
        llnextnumberff <= mloopff(errorcnt_width DOWNTO 1) + 1 - llnumberff;
        
        IF (start_fp = '1' OR stateff(4) = '1') THEN  
          FOR k IN 1 TO checkcnt_width LOOP
            mloopff(k) <= (startloopnumber(k) AND start_fp) OR
                          (mloopplusone(k) AND NOT(start_fp));
          END LOOP;
        ELSE
          mloopff <= mloopff_2;
        END IF;
        
        mloopff_2 <= mloopff;

        lastloopff <= lastloop;
        
      END IF;
    
    END IF;
    
  END PROCESS;
  
  mloopplusone <= mloopff_2 + 1;

  -- 2L <= m?
  chktlm <= (llnumberff_2(checkcnt_width-1 DOWNTO 1) & '0') - mloopff_2 - 1;
  tlm <= chktlm(checkcnt_width);
  
  gen_ll_out: FOR k IN 1 TO errorcnt_width GENERATE
    lloutnode(k) <= (llnextnumberff(k) AND statefornode) OR
                    (llnumberff_2(k) AND NOT(statefornode));
  END GENERATE;
              
  lastloop_node(1) <= (mloopff(1) XOR endloopnumber(1));
  gen_lll_out: FOR k IN 2 TO checkcnt_width GENERATE
    lastloop_node(k) <= lastloop_node(k-1) OR (mloopff(k) XOR endloopnumber(k));
  END GENERATE;
  lastloop <= NOT(lastloop_node(checkcnt_width));


--***************
--*** OUTPUTS ***
--***************

syndromesout <= syndromesff_2;
bdsout <= bdsoutnode;
bdsprevout <= bdsprevoutnode;
deltaout <= deltaoutnode;
llnumberout <= lloutnode;
nextstage <= stateff(4) AND lastloopff;
bm_ready <= bm_is_ready;
END rtl;
  
 