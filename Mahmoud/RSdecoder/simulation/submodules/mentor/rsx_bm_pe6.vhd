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
--***   RSX_BM_PE6                                ***
--***                                             ***
--***   Function: Parallel Reed Solomon Decoder   ***
--***   Berlekamp-Massey Error Locator Solver     ***
--***                                             ***
--***   6 Clocks per Round Systolic PE            ***
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

ENTITY rsx_bm_pe6 IS 
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
END rsx_bm_pe6;

ARCHITECTURE rtl OF rsx_bm_pe6 IS

  constant is_error_sup : integer := is_a_strict_sup_b(error_symbols,endloop+1);
  constant systolic_symbols : integer := (1-is_error_sup)*error_symbols + is_error_sup*(endloop+1);

  type systolictype IS ARRAY (systolic_symbols DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  -- state machine section
  signal stateff : STD_LOGIC_VECTOR (6 DOWNTO 1);
  signal statefivff: STD_LOGIC;
  signal statefivnode, statesixnode : STD_LOGIC;
  -- syndromes section
  signal syndromesff   : syndromevector;
  signal syndromesff_2 : syndromevector;
  signal syndromesff_3 : syndromevector;
  signal syndromesnode : syndromevector;
  -- bd section
  signal bdff, bdff_2, bdff_3             : systolictype;
  signal bdprevff, bdprevff_2, bdprevff_3 : systolictype;
  signal bdsoutnode                       : errorvector;
  signal bdsprevoutnode                   : errorvector;
  signal onenode                          : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  -- core section
  signal syndrome_select       : STD_LOGIC_VECTOR (systolic_symbols DOWNTO 1);
  signal deltaleft, deltaright : systolictype;
  signal bdleft, bdright       : systolictype;
  signal addvector             : systolictype;
  signal mulleftff, mulrightff : systolictype;
  signal mulout, muloutff      : systolictype;
  signal mulsum                : systolictype;
  -- delta section
  signal deltaff, deltaff_2, deltaff_3             : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal deltaprevff, deltaprevff_2, deltaprevff_3 : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal invdeltaprevnode, invdeltaprevff          : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal deltamultnode                             : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal deltazero                                 : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal deltaoutnode                              : STD_LOGIC_VECTOR (m_bits DOWNTO 1);

  signal llnumberff, llnumberff_2, llnumberff_3    : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  signal lloutnode                                 : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  signal llnextnumberff                            : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  signal mloopff, mloopff_2, mloopff_3             : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal startloopnumber, endloopnumber            : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal mloopplusoneff                            : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal chktlm                                    : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  signal tlmff                                     : STD_LOGIC;
  signal lastloop, lastloopff                      : STD_LOGIC;
  signal lastloop_node                             : STD_LOGIC_VECTOR (checkcnt_width DOWNTO 1);
  
  -- fp section
  signal syndromesin_fp, syndromesin_fp0 : syndromevector;
  signal bdsin_fp, bdsin_fp0             : errorvector;
  signal bdsprevin_fp, bdsprevin_fp0     : errorvector;
  signal llnumberin_fp, llnumberin_fp0   : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  signal deltain_fp, deltain_fp0         : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
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
          
          not_ready_for_new_syndrome <= stateff(2) OR (stateff(5) AND NOT(lastloop));
      
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
  
    stateff <= "000000";
    statefivff <= '0';
    
  ELSIF (rising_edge(sysclk)) THEN
    
    IF (enable = '1') THEN

      stateff(1) <= start_fp OR (stateff(6) AND NOT(lastloopff));
      FOR k IN 2 TO 6 LOOP
        stateff(k) <= stateff(k-1);
      END LOOP;
      
      statefivff <= statefivnode;
      
    END IF;
  
  END IF;
    
END PROCESS;

statefivnode <= deltazero(m_bits);
statesixnode <= statefivff AND tlmff;

-- stateff(1) - always active, loads mulleftff mulrightff
-- stateff(2) - always active, pipeline out of multipliers
-- stateff(3) - always active, loads deltaff
-- stateff(4) - always active, loads mulleftff mulrightff
-- stateff(5) - bdtemp = bd
   -- if deltaff !=0 => statefivnode = 1 
-- stateff(6) - if statefivff => bdout = addvec else bdout = bdff
   -- if statefivff AND 2L<m => statesixnode = 1
   -- if statesixnode => llout=m+1-L else llout = llff
   -- if statesixnode => i=1 else ??
   -- if statesixnode => bdpout=bdtemp (and shift) else bdpout=bdpff
   -- if statesixnode => deltaout=deltaff else olddeltaff
 
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
          syndromesff_3(j)(k) <= '0';
        END LOOP;
      END LOOP;
    
    ELSIF (rising_edge(sysclk)) THEN
    
      IF (enable = '1') THEN
      
        FOR k IN 1 TO check_symbols LOOP
          FOR j IN 1 TO m_bits LOOP
            IF (start_fp = '1' OR stateff(6) = '1') THEN
              syndromesff(k)(j) <= syndromesnode(k)(j);
            ELSE
              syndromesff(k)(j) <= syndromesff_3(k)(j);
            END IF;
            
            syndromesff_2(k)(j) <= syndromesff(k)(j);
            syndromesff_3(k)(j) <= syndromesff_2(k)(j);
            
          END LOOP;
        END LOOP;
        
      END IF;
      
    END IF;
 
  END PROCESS;

  -- before the input of stage 0, rotate syndromes the other way externally
  gen_stage_one: FOR k IN 1 TO check_symbols-1 GENERATE
    gen_stage_two: FOR m IN 1 TO m_bits GENERATE
      syndromesnode(k)(m) <= (syndromesin_fp(k+1)(m) AND start_fp) OR
                             (syndromesff_3(k+1)(m) AND NOT(start_fp));
    END GENERATE;
  END GENERATE;
  gen_stage_thr: FOR m IN 1 TO m_bits GENERATE
    syndromesnode(check_symbols)(m) <= (syndromesin_fp(1)(m) AND start_fp) OR
                                       (syndromesff_3(1)(m) AND NOT(start_fp));
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
          bdff_3(j)(k)     <= '0';
          bdprevff(j)(k)   <= '0';
          bdprevff_2(j)(k) <= '0';
          bdprevff_3(j)(k) <= '0';
        END LOOP;
      END LOOP;
      
    ELSIF (rising_edge(sysclk)) THEN
    
      IF (enable = '1') THEN
         
        IF (start_fp = '1' OR stateff(6) = '1') THEN
          FOR k IN 1 TO systolic_symbols LOOP
            FOR m IN 1 TO m_bits LOOP
              bdff(k)(m) <= (bdsin_fp(k)(m) AND start_fp) OR
                            (bdsoutnode(k)(m) AND NOT(start_fp));
            END LOOP;
          END LOOP;
        ELSE
          bdff <= bdff_3;
        END IF;
        
        bdff_2 <= bdff;
        bdff_3 <= bdff_2;
        
        
        IF (start_fp = '1' OR stateff(6) = '1') THEN
          FOR k IN 1 TO systolic_symbols LOOP
            FOR m IN 1 TO m_bits LOOP
              bdprevff(k)(m) <= (bdsprevin_fp(k)(m) AND start_fp) OR
                                (bdsprevoutnode(k)(m) AND NOT(start_fp));
            END LOOP;
          END LOOP;
        ELSE
          bdprevff <= bdprevff_3;
        END IF;
        
        bdprevff_2 <= bdprevff;
        bdprevff_3 <= bdprevff_2;
     
      END IF;
      
    END IF;
    
  END PROCESS;
  
  onenode <= conv_std_logic_vector(1,m_bits);

  gen_bdout_one: IF (systolic_symbols = error_symbols) GENERATE
    gen_bdout_two: FOR k IN 1 TO error_symbols GENERATE
      gen_bdout_thr: FOR j IN 1 TO m_bits GENERATE
        bdsoutnode(k)(j) <= (addvector(k)(j) AND statefivff) OR
                            (bdff_3(k)(j) AND NOT(statefivff));
      END GENERATE;
    END GENERATE;
  END GENERATE;
  
  gen_bdout_for: IF (systolic_symbols < error_symbols) GENERATE
    gen_bdout_fiv: FOR k IN 1 TO systolic_symbols GENERATE
      gen_bdout_six: FOR j IN 1 TO m_bits GENERATE
        bdsoutnode(k)(j) <= (addvector(k)(j) AND statefivff) OR
                            (bdff_3(k)(j) AND NOT(statefivff));
      END GENERATE;
      gen_bdout_sev: FOR k IN systolic_symbols+1 TO error_symbols GENERATE
          bdsoutnode(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      END GENERATE;
    END GENERATE;
  END GENERATE;   

  gen_bdprevout_one: FOR j IN 1 TO m_bits GENERATE
    bdsprevoutnode(1)(j) <= (onenode(j) AND statesixnode);
  END GENERATE;
  
  gen_bdprevout_two: IF (systolic_symbols = error_symbols) GENERATE
    gen_bdprevout_thr: FOR k IN 2 TO error_symbols GENERATE
      gen_bdprevout_for: FOR j IN 1 TO m_bits GENERATE
        bdsprevoutnode(k)(j) <= (bdff_3(k-1)(j) AND statesixnode) OR
                                (bdprevff_3(k-1)(j) AND NOT(statesixnode));
      END GENERATE;
    END GENERATE;  
  END GENERATE;
  
  -- vectorsize must be 2 less than error_symbols
  gen_bdprevout_fiv: IF (systolic_symbols < error_symbols) GENERATE
    gen_bdprevout_six: FOR k IN 2 TO systolic_symbols+1 GENERATE
      gen_bdprevout_sev: FOR j IN 1 TO m_bits GENERATE
        bdsprevoutnode(k)(j) <= (bdff_3(k-1)(j) AND statesixnode) OR
                                (bdprevff_3(k-1)(j) AND NOT(statesixnode));
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
    PORT MAP (aa=>bdff_3(j)(m_bits DOWNTO 1),bb=>muloutff(j)(m_bits DOWNTO 1),
              cc=>addvector(j)(m_bits DOWNTO 1));
  END GENERATE;

  prc_mul: PROCESS (sysclk,reset) 
  BEGIN
  
    IF (reset = '1') THEN
        
      FOR j IN 1 TO systolic_symbols LOOP
        FOR k IN 1 TO m_bits LOOP
          mulleftff(j)(k)  <= '0';
          mulrightff(j)(k) <= '0';
          muloutff(j)(k)   <= '0';
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
            muloutff(j)(k)   <= mulout(j)(k);
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
    mulsum(1)(k) <= muloutff(1)(k) XOR syndromesff_3(1)(k);
  END GENERATE;
  gen_muladd_two: FOR j IN 2 TO systolic_symbols GENERATE
    gen_muladd_thr: FOR k IN 1 TO m_bits GENERATE
      mulsum(j)(k) <= muloutff(j)(k) XOR mulsum(j-1)(k); 
      END GENERATE;
  END GENERATE;
  
  
  
--*********************
--*** DELTA SECTION ***
--*********************
  
  prc_delta: PROCESS (sysclk,reset) 
  BEGIN
  
    IF (reset = '1') THEN
        
      FOR k IN 1 TO m_bits LOOP
        deltaff(k)           <= '0';
        deltaff_2(k)         <= '0';
        deltaff_3(k)         <= '0';
        deltaprevff(k)       <= '0';
        deltaprevff_2(k)     <= '0';
        deltaprevff_3(k)     <= '0';
        invdeltaprevff(k)    <= '0';
      END LOOP;
          
    ELSIF (rising_edge(sysclk)) THEN
            
      IF (enable = '1') THEN
        
        deltaff   <= mulsum(systolic_symbols)(m_bits DOWNTO 1);
        deltaff_2 <= deltaff;
        deltaff_3 <= deltaff_2;

        IF (start_fp = '1' OR stateff(6) = '1') THEN  -- IT WAS stage(5) which seems not correct
          FOR m IN 1 TO m_bits LOOP  
            deltaprevff(m) <= (deltain_fp(m) AND start_fp) OR
                              (deltaoutnode(m) AND NOT(start_fp));
          END LOOP;
        ELSE
          deltaprevff <= deltaprevff_3;
        END IF;
        
        deltaprevff_2 <= deltaprevff;
        deltaprevff_3 <= deltaprevff_2;
        
        invdeltaprevff <= invdeltaprevnode;
        
      END IF;
      
    END IF;
    
  END PROCESS;

  get_inv_of <= deltaprevff;
  get_inv_of_valid <= stateff(1);
  invdeltaprevnode <= value_of_inv;
  
  
  
  cdmul: rsp_gf_mul 
  GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  PORT MAP (aa=>deltaff,bb=>invdeltaprevff,
            cc=>deltamultnode);
  
  deltazero(1) <= deltaff_2(1);
  gen_delta_zip: FOR k IN 2 TO m_bits GENERATE
    deltazero(k) <= deltaff_2(k) OR deltazero(k-1);
  END GENERATE;
  
  gen_delta_out: FOR k IN 1 TO m_bits GENERATE
    deltaoutnode(k) <= (deltaff_3(k) AND statesixnode) OR
                       (deltaprevff_3(k) AND NOT(statesixnode));
  END GENERATE;
  
  
  
  
--****************
--*** COUNTERS ***
--****************

  prc_count: PROCESS (sysclk,reset)
  BEGIN
      
    IF (reset = '1') THEN
        
      llnumberff     <= conv_std_logic_vector(0,errorcnt_width);
      llnumberff_2   <= conv_std_logic_vector(0,errorcnt_width);
      llnumberff_3   <= conv_std_logic_vector(0,errorcnt_width);
      llnextnumberff <= conv_std_logic_vector(0,errorcnt_width);
      mloopff        <= conv_std_logic_vector(0,checkcnt_width);
      mloopff_2      <= conv_std_logic_vector(0,checkcnt_width);
      mloopff_3      <= conv_std_logic_vector(0,checkcnt_width);
      mloopplusoneff <= conv_std_logic_vector(0,checkcnt_width);
      tlmff          <= '0';
      lastloopff     <= '0';
      
    ELSIF (rising_edge(sysclk)) THEN
    
      IF (enable = '1') THEN
        
        IF (start_fp = '1' OR stateff(6) = '1') THEN  
          FOR k IN 1 TO errorcnt_width LOOP
            llnumberff(k) <= (llnumberin_fp(k) AND start_fp) OR
                             (lloutnode(k) AND NOT(start_fp));
          END LOOP;
        ELSE
          llnumberff <= llnumberff_3;
        END IF;
        
        llnumberff_2 <= llnumberff;
        llnumberff_3 <= llnumberff_2;
        
        
        tlmff <= chktlm(checkcnt_width);
        
        IF (start_fp = '1' OR stateff(6) = '1') THEN  
          FOR k IN 1 TO checkcnt_width LOOP
            mloopff(k) <= (startloopnumber(k) AND start_fp) OR
                          (mloopplusoneff(k) AND NOT(start_fp));
          END LOOP;
        ELSE  
          mloopff <= mloopff_3;
        END IF;

        mloopff_2 <= mloopff;
        mloopff_3 <= mloopff_2;


        mloopplusoneff <= mloopff_2 + 1;
        
        llnextnumberff <= mloopff_2(errorcnt_width DOWNTO 1) + 1 - llnumberff_2;
        
        lastloopff <= lastloop;
        
      END IF;
    
    END IF;
    
  END PROCESS;

  -- 2L <= m?
  chktlm <= (llnumberff_2(checkcnt_width-1 DOWNTO 1) & '0') - mloopff_2 - 1;
    
  gen_ll_out: FOR k IN 1 TO errorcnt_width GENERATE
    lloutnode(k) <= (llnextnumberff(k) AND statesixnode) OR
                    (llnumberff_3(k) AND NOT(statesixnode));
  END GENERATE;
  
  lastloop_node(1) <= (mloopff_2(1) XOR endloopnumber(1));
  gen_lll_out: FOR k IN 2 TO checkcnt_width GENERATE
    lastloop_node(k) <= lastloop_node(k-1) OR (mloopff_2(k) XOR endloopnumber(k));
  END GENERATE;
  lastloop <= NOT(lastloop_node(checkcnt_width));
                  
--***************
--*** OUTPUTS ***
--***************

syndromesout <= syndromesff_3;
bdsout <= bdsoutnode;
bdsprevout <= bdsprevoutnode;
deltaout <= deltaoutnode;
llnumberout <= lloutnode;
nextstage <= stateff(6) AND lastloopff;
bm_ready <= bm_is_ready;
END rtl;
  
 
