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
USE work.bchp_functions.all;

--***************************************************
--***                                             ***
--***   ALTERA BCH LIBRARY                        ***
--***                                             ***
--***   BCHP_MBOPT_PE6                            ***
--***                                             ***
--***   Function: Berlekamp-Massey (6 clocks)     ***
--***   Optimized PE (BCH only : two iterations   ***
--***   per round)                                ***
--***                                             ***
--***   17/12/14 ML                               ***
--***                                             ***
--***   (c) 2014 Altera Corporation               ***
--***                                             ***
--***   Change History                            ***
--***                                             ***
--***   Feb/2015 Jianxiong Liu:                   ***
--***   Changed to have full pipeline             ***
--***                                             ***
--***                                             ***
--***************************************************

ENTITY bchp_mbopt_pe6 IS 
GENERIC (
         startloop : integer := 0;
         endloop : integer := 19
        ); -- mloop: 0 to check_symbols-1
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      start : IN STD_LOGIC; -- start this stage
      syndromesin : IN syndromevector;
      bdsin, bdsprevin : IN errorvector;
      llnumberin : IN STD_LOGIC_VECTOR (8 DOWNTO 1);
      deltain : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);

      
      syndromesout : OUT syndromevector;
      bdsout, bdsprevout : OUT errorvector;
      llnumberout : OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
      deltaout : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
      nextstage : OUT STD_LOGIC -- start for next level
		);
END bchp_mbopt_pe6;

ARCHITECTURE rtl OF bchp_mbopt_pe6 IS

  constant systolic_symbols : positive := systolic_width(endloop,t_symbols);

  type systolictype IS ARRAY (systolic_symbols DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  -- state machine section
  signal stateff : STD_LOGIC_VECTOR (6 DOWNTO 1);
  signal statefivff: STD_LOGIC;
  signal statefivnode, statesixnode : STD_LOGIC;
  -- syndromes section
  signal syndromesff : syndromevector;
  signal syndromesnode : syndromevector;
  -- bd section
  signal bdff, bdtempff, bdprevff : systolictype;
  signal bdsoutnode, bdsprevoutnode : errorvector;
  signal onenode : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  -- core section
  signal syndrome_select : STD_LOGIC_VECTOR (systolic_symbols DOWNTO 1);
  signal deltaleft, deltaright : systolictype;
  signal bdleft, bdright : systolictype;
  signal addvector : systolictype;
  signal mulleftff, mulrightff : systolictype;
  signal muloutff : systolictype;
  signal mulout : systolictype;
  signal mulsum : systolictype;
  -- delta section
  signal deltaff, deltaprevff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal invdeltaprevnode, invdeltaprevff : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal deltamultnode : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal deltazero : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal deltaoutnode : STD_LOGIC_VECTOR (m_bits DOWNTO 1);

  signal llnumberff : STD_LOGIC_VECTOR (8 DOWNTO 1);
  signal mloopff : STD_LOGIC_VECTOR (9 DOWNTO 1);
  signal startloopnumber, endloopnumber : STD_LOGIC_VECTOR (9 DOWNTO 1);
  signal mloopplusoneff : STD_LOGIC_VECTOR (9 DOWNTO 1);
  signal chktlm : STD_LOGIC_VECTOR (9 DOWNTO 1);
  signal tlmff : STD_LOGIC;
  signal lastloop, lastloopff : STD_LOGIC;
  signal llnextnumberff : STD_LOGIC_VECTOR (8 DOWNTO 1);
  signal lloutnode : STD_LOGIC_VECTOR (8 DOWNTO 1);
  
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
 
  component bchp_rom
    GENERIC (
			mem_width : positive := m_bits
			);
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (mem_width-1 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (mem_width-1 DOWNTO 0)
	);
	end component;

  
  -- *************************************
  -- signals for the enhanced version of BM
  -- *************************************

  signal hold_on : STD_LOGIC; -- hold on signal indicates 
  -- registered inputs
  signal start_ff, start_node : STD_LOGIC; 
  signal syndromesin_ff, syndromesin_node : syndromevector;
  signal bdsin_ff, bdsprevin_ff, bdsin_node, bdsprevin_node : errorvector;
  signal llnumberin_ff, llnumberin_node : STD_LOGIC_VECTOR (8 DOWNTO 1);
  signal deltain_ff, deltain_node : STD_LOGIC_VECTOR (m_bits DOWNTO 1);

  -- intermediate registers
  signal deltaprevff2, deltaprevff3, deltaprevff4, deltaprevff5, deltaprevff6 : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal deltaff2, deltaff3 : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal bdff2, bdff3, bdff4, bdff5, bdff6 : systolictype;
  signal syndromesff2, syndromesff3, syndromesff4, syndromesff5, syndromesff6 : syndromevector;
  signal llnumberff2, llnumberff3, llnumberff4, llnumberff5, llnumberff6 : STD_LOGIC_VECTOR (8 DOWNTO 1);
  signal mloopff2, mloopff3, mloopff4, mloopff5 : STD_LOGIC_VECTOR (9 DOWNTO 1);
  signal bdprevff2, bdprevff3, bdprevff4, bdprevff5, bdprevff6 : systolictype;

  -- new state machine array
  type state_machine_array IS ARRAY (3 DOWNTO 1) OF STD_LOGIC_VECTOR (6 DOWNTO 1);
  signal stateff_threads : state_machine_array;
  signal thread_busy : STD_LOGIC_VECTOR (3 DOWNTO 1);


			 
BEGIN

startloopnumber <= conv_std_logic_vector (startloop,9);
endloopnumber <= conv_std_logic_vector (endloop,9);


--*****************************
--*** REGISTER MANAGEMENT ***
--***************************** 
reg_prc : PROCESS
BEGIN
  WAIT UNTIL sysclk'event AND sysclk = '1';

  deltaprevff2 <= deltaprevff;
  deltaprevff3 <= deltaprevff2;
  deltaprevff4 <= deltaprevff3;
  deltaprevff5 <= deltaprevff4;
  deltaprevff6 <= deltaprevff5;

  deltaff2 <= deltaff;
  deltaff3 <= deltaff2;

  bdff2 <= bdff;
  bdff3 <= bdff2;
  bdff4 <= bdff3;
  bdff5 <= bdff4;
  bdff6 <= bdff5;

  bdprevff2 <= bdprevff;
  bdprevff3 <= bdprevff2;
  bdprevff4 <= bdprevff3;
  bdprevff5 <= bdprevff4;
  bdprevff6 <= bdprevff5;

  syndromesff2 <= syndromesff;
  syndromesff3 <= syndromesff2;
  syndromesff4 <= syndromesff3;
  syndromesff5 <= syndromesff4;
  syndromesff6 <= syndromesff5;

  llnumberff2 <= llnumberff;
  llnumberff3 <= llnumberff2;
  llnumberff4 <= llnumberff3;
  llnumberff5 <= llnumberff4;
  llnumberff6 <= llnumberff5;

  mloopff2 <= mloopff;
  mloopff3 <= mloopff2;
  mloopff4 <= mloopff3;
  mloopff5 <= mloopff4;

END PROCESS;

-- combine the states of different threads into a single control
gen_state_machine : FOR k IN 1 to 6 GENERATE
  stateff(k) <= stateff_threads(1)(k) OR stateff_threads(2)(k) OR stateff_threads(3)(k);
END GENERATE;
gen_state_busy : FOR j IN 1 TO 3 GENERATE
  thread_busy(j) <= stateff_threads(j)(1) OR stateff_threads(j)(2) OR stateff_threads(j)(3) OR 
                    stateff_threads(j)(4) OR stateff_threads(j)(5) OR stateff_threads(j)(6);
END GENERATE;


--*****************************
--*** FORWARD PRESSURE ***
--*****************************
input_connection_prc : PROCESS (hold_on,
                                start, syndromesin, bdsin, bdsprevin, llnumberin, deltain,
                                start_ff, syndromesin_ff, bdsin_ff, bdsprevin_ff, llnumberin_ff, deltain_ff)
BEGIN
  IF start = '1' AND hold_on = '0' THEN
    start_node <= start;
    syndromesin_node <= syndromesin;
    bdsin_node <= bdsin;
    bdsprevin_node <= bdsprevin;
    llnumberin_node <= llnumberin;
    deltain_node <= deltain;
  ELSIF start_ff = '1' AND hold_on = '0' THEN
    start_node <= start_ff;
    syndromesin_node <= syndromesin_ff;
    bdsin_node <= bdsin_ff;
    bdsprevin_node <= bdsprevin_ff;
    llnumberin_node <= llnumberin_ff;
    deltain_node <= deltain_ff;
  ELSE
    start_node <= '0';
    syndromesin_node <= (others=>(others=>'0'));
    bdsin_node <= (others=>(others=>'0'));
    bdsprevin_node <= (others=>(others=>'0'));
    llnumberin_node <= (others=>'0');
    deltain_node <= (others=>'0');
  END IF;
END PROCESS;


reg_input_prc : PROCESS (sysclk)
BEGIN

  IF (rising_edge(sysclk)) THEN

    IF (reset = '1') THEN  

    hold_on <= '0';
    start_ff <= '0';
    syndromesin_ff <= (others=>(others=>'0'));
    bdsin_ff <= (others=>(others=>'0'));
    bdsprevin_ff <= (others=>(others=>'0'));
    llnumberin_ff <= (others=>'0');
    deltain_ff <= (others=>'0');

    ELSE

    hold_on <= stateff(2) OR (stateff(5) AND NOT(lastloop));

    IF start = '1' AND hold_on = '1' THEN -- if there is valid input but hold on
      start_ff <= start;
      syndromesin_ff <= syndromesin;
      bdsin_ff <= bdsin;
      bdsprevin_ff <= bdsprevin;
      llnumberin_ff <= llnumberin;
      deltain_ff <= deltain;
    ELSIF hold_on = '0' THEN -- if for any time, last cycle was not hold on, data is guaranteed to have passed through
      start_ff <= '0';
    END IF; -- else hold the current registered data for future hold_on='0'

    END IF;

  END IF;

END PROCESS;


--*****************************
--*** STATE MACHINE SECTION ***
--*****************************

prc_ctl: PROCESS (sysclk)
BEGIN

  
    
  IF (rising_edge(sysclk)) THEN
  
    IF (reset = '1') THEN    
  
    FOR i IN 1 TO 3 LOOP
      stateff_threads(i) <= (others=>'0');
    END LOOP;
    statefivff <= '0';
    
    ELSIF (enable = '1') THEN

      IF start_node = '1' THEN -- if start, find a thread that is not busy right now; NOTE, if all threads are busy --> logic error
        IF thread_busy(1)='0' THEN
          stateff_threads(1)(1) <= '1';
        ELSIF thread_busy(2)='0' THEN
          stateff_threads(2)(1) <= '1';
        ELSIF thread_busy(3)='0' THEN
          stateff_threads(3)(1) <= '1';
        END IF;
      END IF;

      -- shift the states of different threads
      FOR j IN 1 TO 3 LOOP
        IF thread_busy(j) = '1' THEN
          stateff_threads(j)(1) <= stateff_threads(j)(6) AND NOT(lastloopff); -- otherwise, threads enter new state chain if state(6) reached and not lastloop for this chain yet
          FOR k IN 2 TO 6 LOOP
            stateff_threads(j)(k) <= stateff_threads(j)(k-1);
          END LOOP;
        END IF;
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

  prc_syn: PROCESS (sysclk)
  BEGIN
  
    IF (rising_edge(sysclk)) THEN

      IF (reset = '1') THEN
    
      FOR j IN 1 TO check_symbols LOOP
        FOR k IN 1 TO m_bits LOOP
          syndromesff(j)(k) <= '0';
        END LOOP;
      END LOOP;
    
      ELSIF (enable = '1') THEN
      
        FOR k IN 1 TO check_symbols LOOP
          FOR j IN 1 TO m_bits LOOP
            IF (start_node = '1' OR stateff(6) = '1') THEN
              syndromesff(k)(j) <= syndromesnode(k)(j);
            END IF;
          END LOOP;
        END LOOP;
        
      END IF;
      
    END IF;
 
  END PROCESS;
  
  -- rotate input by 2 for mb_systemx
  gen_stage_one: FOR k IN 1 TO check_symbols-2 GENERATE
    gen_stage_two: FOR m IN 1 TO m_bits GENERATE
      syndromesnode(k)(m) <= (syndromesin_node(k+2)(m) AND start_node) OR
                             (syndromesff6(k+2)(m) AND NOT(start_node));
    END GENERATE;
  END GENERATE;
  gen_stage_thr: FOR m IN 1 TO m_bits GENERATE
    syndromesnode(check_symbols-1)(m) <= (syndromesin_node(1)(m) AND start_node) OR
                                         (syndromesff6(1)(m) AND NOT(start_node));
    syndromesnode(check_symbols)(m) <= (syndromesin_node(2)(m) AND start_node) OR
                                       (syndromesff6(2)(m) AND NOT(start_node));
  END GENERATE; 
  
--******************
--*** BD SECTION ***
--******************

  prc_bd: PROCESS (sysclk)
  BEGIN
      
    IF (rising_edge(sysclk)) THEN

      IF (reset = '1') THEN

      FOR j IN 1 TO systolic_symbols LOOP
        FOR k IN 1 TO m_bits LOOP
          bdff(j)(k) <= '0';
          bdprevff(j)(k) <= '0';
        END LOOP;
      END LOOP;
    
      ELSIF (enable = '1') THEN
         
        IF (start_node = '1' OR stateff(6) = '1') THEN
          FOR k IN 1 TO systolic_symbols LOOP
            FOR m IN 1 TO m_bits LOOP
              bdff(k)(m) <= (bdsin_node(k)(m) AND start_node) OR
                            (bdsoutnode(k)(m) AND NOT(start_node));
            END LOOP;
          END LOOP;
        END IF;
        
        IF (start_node = '1' OR stateff(6) = '1') THEN
          FOR k IN 1 TO systolic_symbols LOOP
            FOR m IN 1 TO m_bits LOOP
              bdprevff(k)(m) <= (bdsprevin_node(k)(m) AND start_node) OR
                                (bdsprevoutnode(k)(m) AND NOT(start_node));
            END LOOP;
          END LOOP;
        END IF;
     
      END IF;
      
    END IF;
    
  END PROCESS;
  
  onenode <= conv_std_logic_vector(1,m_bits);
  
  gen_bdout_one: IF (systolic_symbols = t_symbols) GENERATE
    gen_bdout_two: FOR k IN 1 TO t_symbols GENERATE
      gen_bdout_thr: FOR j IN 1 TO m_bits GENERATE
        bdsoutnode(k)(j) <= (addvector(k)(j) AND statefivff) OR
                            (bdff6(k)(j) AND NOT(statefivff));
      END GENERATE;
    END GENERATE;
  END GENERATE;
  
  gen_bdout_for: IF (systolic_symbols < t_symbols) GENERATE
    gen_bdout_fiv: FOR k IN 1 TO systolic_symbols GENERATE
      gen_bdout_six: FOR j IN 1 TO m_bits GENERATE
        bdsoutnode(k)(j) <= (addvector(k)(j) AND statefivff) OR
                            (bdff6(k)(j) AND NOT(statefivff));
      END GENERATE;
      gen_bdout_sev: FOR k IN systolic_symbols+1 TO t_symbols GENERATE
          bdsoutnode(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      END GENERATE;
    END GENERATE;
  END GENERATE;
  
  --gen_bdprevout_one: FOR j IN 1 TO m_bits GENERATE
  --  bdsprevoutnode(1)(j) <= (onenode(j) AND statesixnode);
  --END GENERATE;
  
  --gen_bdprevout_two: IF (systolic_symbols = t_symbols) GENERATE
  --  gen_bdprevout_thr: FOR k IN 2 TO t_symbols GENERATE
  --    gen_bdprevout_for: FOR j IN 1 TO m_bits GENERATE
  --      bdsprevoutnode(k)(j) <= (bdff(k-1)(j) AND statesixnode) OR
  --                              (bdprevff(k-1)(j) AND NOT(statesixnode));
  --    END GENERATE;
  --  END GENERATE;  
  --END GENERATE;
  
  -- vectorsize must be 2 less than t_symbols
  --gen_bdprevout_fiv: IF (systolic_symbols < t_symbols) GENERATE
  --  gen_bdprevout_six: FOR k IN 2 TO systolic_symbols+1 GENERATE
  --    gen_bdprevout_sev: FOR j IN 1 TO m_bits GENERATE
  --      bdsprevoutnode(k)(j) <= (bdff(k-1)(j) AND statesixnode) OR
  --                              (bdprevff(k-1)(j) AND NOT(statesixnode));
  --    END GENERATE;
  --  END GENERATE;  
  --  gen_bdprevout_egt: FOR k IN systolic_symbols+2 TO t_symbols GENERATE
  --      bdsprevoutnode(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
  --  END GENERATE;  
  --END GENERATE;
  
  gen_bdprevout_one: FOR j IN 1 TO m_bits GENERATE
    bdsprevoutnode(1)(j) <= '0';
    bdsprevoutnode(2)(j) <= (onenode(j) AND statesixnode);
    bdsprevoutnode(3)(j) <= (bdff6(1)(j) AND statesixnode) OR
                            (bdprevff6(1)(j) AND NOT(statesixnode));
  END GENERATE;
  
  gen_bdprevout_two: IF (systolic_symbols = t_symbols) GENERATE
    gen_bdprevout_thr: FOR k IN 4 TO t_symbols GENERATE
      gen_bdprevout_for: FOR j IN 1 TO m_bits GENERATE
        bdsprevoutnode(k)(j) <= (bdff6(k-2)(j) AND statesixnode) OR
                                (bdprevff6(k-2)(j) AND NOT(statesixnode));
      END GENERATE;
    END GENERATE;  
  END GENERATE;
  
  -- NOTE: for current version, systolic_symbols must be at least 4 (this is ensured in the function package)
  gen_bdprevout_fiv: IF (systolic_symbols < t_symbols) GENERATE
    gen_bdprevout_six_gate : IF (systolic_symbols+1 >= 4) GENERATE
      gen_bdprevout_six: FOR k IN 4 TO systolic_symbols+1 GENERATE
        gen_bdprevout_sev: FOR j IN 1 TO m_bits GENERATE
          bdsprevoutnode(k)(j) <= (bdff6(k-2)(j) AND statesixnode) OR
                                  (bdprevff6(k-2)(j) AND NOT(statesixnode));
        END GENERATE;
      END GENERATE;  
    END GENERATE;

    gen_bdprevout_egt_gate : IF (systolic_symbols+2 <= t_symbols) GENERATE
      gen_bdprevout_egt: FOR k IN systolic_symbols+2 TO t_symbols GENERATE
          bdsprevoutnode(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      END GENERATE;  
    END GENERATE; 
  END GENERATE;
  
--********************
--*** CORE SECTION ***
--********************

  -- 19/12/2014 changed width from 6 to 8 to support up to t=255
  comp_csynsel: rsp_unary
  GENERIC MAP (inwidth=>8,outwidth=>systolic_symbols)
  PORT MAP (inbus=>llnumberff,outbus=>syndrome_select);
		
  gen_mulmux_one: FOR j IN 1 TO systolic_symbols GENERATE
    gen_mulmux_two: FOR k IN 1 TO m_bits GENERATE
      deltaleft(j)(k) <= syndromesff(check_symbols+1-j)(k) AND syndrome_select(j);
      deltaright(j)(k) <= bdff(j)(k);
    END GENERATE;
  END GENERATE;
  
  gen_mulmux_thr: FOR j IN 1 TO systolic_symbols GENERATE
    gen_mulmux_for: FOR k IN 1 TO m_bits GENERATE
      bdleft(j)(k) <= bdprevff4(j)(k);
      bdright(j)(k) <= deltamultnode(k);
    END GENERATE;
  END GENERATE;

  gen_adder: FOR j IN 1 TO systolic_symbols GENERATE
    comp_gfac: rsp_gf_add
    GENERIC MAP (m_bits=>m_bits)
    PORT MAP (aa=>bdff6(j)(m_bits DOWNTO 1),bb=>muloutff(j)(m_bits DOWNTO 1),
              cc=>addvector(j)(m_bits DOWNTO 1));
  END GENERATE;

  prc_mul: PROCESS (sysclk) 
  BEGIN
          
    IF (rising_edge(sysclk)) THEN

      IF (reset = '1') THEN
        
      FOR j IN 1 TO systolic_symbols LOOP
        FOR k IN 1 TO m_bits LOOP
          mulleftff(j)(k) <= '0';
          mulrightff(j)(k) <= '0';
          muloutff(j)(k) <= '0';
        END LOOP;
      END LOOP;
            
      ELSIF (enable = '1') THEN
      
        FOR j IN 1 TO systolic_symbols LOOP
          FOR k IN 1 TO m_bits LOOP
            mulleftff(j)(k) <= (deltaleft(j)(k) AND stateff(1)) OR
                               (bdleft(j)(k) AND NOT(stateff(1)));
            mulrightff(j)(k) <= (deltaright(j)(k) AND stateff(1)) OR
                                (bdright(j)(k) AND NOT(stateff(1)));
            muloutff(j)(k) <= mulout(j)(k);
          END LOOP;
        END LOOP;
    
      END IF;
      
    END IF;

  END PROCESS;
  
  gen_mul: FOR k IN 1 TO systolic_symbols GENERATE
    comp_gfma: rsp_gf_mul 
    GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
    PORT MAP (aa=>mulleftff(k)(m_bits DOWNTO 1),bb=>mulrightff(k)(m_bits DOWNTO 1),
              cc=>mulout(k)(m_bits DOWNTO 1));
  END GENERATE;

  -- calculate new delta
  gen_muladd_one: FOR k IN 1 TO m_bits GENERATE
    mulsum(1)(k) <= muloutff(1)(k) XOR syndromesff3(1)(k);
  END GENERATE;
  gen_muladd_two: FOR j IN 2 TO systolic_symbols GENERATE
    gen_muladd_thr: FOR k IN 1 TO m_bits GENERATE
      mulsum(j)(k) <= muloutff(j)(k) XOR mulsum(j-1)(k); 
	  END GENERATE;
  END GENERATE;
  
  prc_delta: PROCESS (sysclk) 
  BEGIN
  
    IF (rising_edge(sysclk)) THEN

      IF (reset = '1') THEN
        
      FOR k IN 1 TO m_bits LOOP
        deltaff(k) <= '0';
        deltaprevff(k) <= '0';
        invdeltaprevff(k) <= '0';
      END LOOP;
            
      ELSIF (enable = '1') THEN
        
        IF (stateff(3) = '1') THEN  
          deltaff <= mulsum(systolic_symbols)(m_bits DOWNTO 1);
        END IF;
        
        IF (start_node = '1' OR stateff(6) = '1') THEN
          FOR m IN 1 TO m_bits LOOP  
            deltaprevff(m) <= (deltain_node(m) AND start_node) OR
                              (deltaoutnode(m) AND NOT(start_node));
          END LOOP;
        END IF;
        
        invdeltaprevff <= invdeltaprevnode;
        
      END IF;
      
    END IF;
    
  END PROCESS;

  --cdinv: bchp_gf_inv
  --PORT MAP (aa=>deltaprevff,cc=>invdeltaprevnode);

  -- extra clock, but will still arrive on time  
  comp_rom: bchp_rom
    GENERIC MAP (mem_width=>m_bits)
	PORT MAP (address=>deltaprevff,clock=>sysclk,q=>invdeltaprevnode);
	  
	comp_cdmul: rsp_gf_mul 
  GENERIC MAP (polynomial=>polynomial,m_bits=>m_bits)
  PORT MAP (aa=>deltaff,bb=>invdeltaprevff,
            cc=>deltamultnode);
  
  deltazero(1) <= deltaff2(1);
  gen_delta_zip: FOR k IN 2 TO m_bits GENERATE
    deltazero(k) <= deltaff2(k) OR deltazero(k-1);
  END GENERATE;
  
  gen_delta_out: FOR k IN 1 TO m_bits GENERATE
    deltaoutnode(k) <= (deltaff3(k) AND statesixnode) OR
                       (deltaprevff6(k) AND NOT(statesixnode));
  END GENERATE;
  
--****************
--*** COUNTERS ***
--****************

  prc_count: PROCESS (sysclk)
  BEGIN
      
    IF (rising_edge(sysclk)) THEN

      IF (reset = '1') THEN
        
        llnumberff <= "00000000";
        tlmff <= '0';
        mloopff <= "000000000";
        mloopplusoneff <= "000000000";
        llnextnumberff <= "00000000";
        lastloopff <= '0';

      ELSE
    
      IF (enable = '1') THEN
        
        IF (start_node = '1' OR stateff(6) = '1') THEN  
          FOR k IN 1 TO 8 LOOP
            llnumberff(k) <= (llnumberin_node(k) AND start_node) OR
                             (lloutnode(k) AND NOT(start_node));
          END LOOP;
        END IF;
        
        tlmff <= chktlm(9);
        
        IF (start_node = '1' OR stateff(6) = '1') THEN  
          FOR k IN 1 TO 9 LOOP
            mloopff(k) <= (startloopnumber(k) AND start_node) OR
                          (mloopplusoneff(k) AND NOT(start_node));
          END LOOP;
        END IF;
   
        mloopplusoneff <= mloopff5 + 2;
        
        llnextnumberff <= mloopff5(8 DOWNTO 1) + 1 - llnumberff5;
        
        lastloopff <= lastloop;
        
      END IF;

      END IF;
    
    END IF;
    
  END PROCESS;

  -- 2L <= m?
  chktlm <= (llnumberff5 & '0') - mloopff5 - 1;
    
  gen_ll_out: FOR k IN 1 TO 8 GENERATE
    lloutnode(k) <= (llnextnumberff(k) AND statesixnode) OR
                    (llnumberff6(k) AND NOT(statesixnode));
  END GENERATE;
  
  lastloop <= NOT((mloopff5(8) XOR endloopnumber(8)) OR (mloopff5(7) XOR endloopnumber(7)) OR 
                  (mloopff5(6) XOR endloopnumber(6)) OR (mloopff5(5) XOR endloopnumber(5)) OR 
                  (mloopff5(4) XOR endloopnumber(4)) OR (mloopff5(3) XOR endloopnumber(3)) OR 
                  (mloopff5(2) XOR endloopnumber(2)) OR (mloopff5(1) XOR endloopnumber(1)));
  
--***************
--*** OUTPUTS ***
--***************

syndromesout <= syndromesff6;
bdsout <= bdsoutnode;
bdsprevout <= bdsprevoutnode;
deltaout <= deltaoutnode;
llnumberout <= lloutnode;
nextstage <= stateff(6) AND lastloopff;

END rtl;
  
 
