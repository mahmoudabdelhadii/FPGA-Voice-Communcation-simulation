
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;

USE work.rsx_parameters.all;
USE work.rsx_package.all;
USE work.rsx_roots.all;

ENTITY rsx_bm_auto IS
  PORT (
         sysclk, reset, enable : IN STD_LOGIC;
         start : IN STD_LOGIC;
         bm_ready : OUT STD_LOGIC;
         syndromes : IN syndromevector;
         error_locator : OUT chien_in_vector;
         error_evaluator : OUT chien_in_vector;
         number_errors : OUT nb_errors_type;
         done : OUT STD_LOGIC
        );
END rsx_bm_auto;

ARCHITECTURE rtlauto OF rsx_bm_auto IS

    signal syndromes_ini : syndromevector;
    signal bdsprev_ini : errorvector;
    signal bds_ini : errorvector;
    signal zerocnt_ini : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
    signal onetheta : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
    signal deltaX_1, deltaXprev_1 : syndromevector;
    signal theta_1 : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
    signal bds_1, bdsprevnode_1 : errorvector;
    signal llnumber_1 : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
    signal deltaX_2, deltaXprev_2 : syndromevector;
    signal theta_2 : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
    signal bds_2, bdsprevnode_2 : errorvector;
    signal llnumber_2 : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
    signal bdsout : errorvector;
    signal omegaout : errorvector;
    signal errorsout : STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
    signal stage : STD_LOGIC_VECTOR (2 DOWNTO 1);
    signal stageout : STD_LOGIC;
    signal syndromesshift : errorvector;

    signal get_inv_of : inv_alpha_type := (others=>(others=>'0'));
    signal value_of_inv : inv_alpha_type := (others=>(others=>'0'));
    signal get_inv_of_valid : STD_LOGIC_VECTOR (nbinvmax DOWNTO 1) := (others=>'0');

  component rsx_bm_pe1 
  GENERIC (startloop : integer := 2;endloop : integer := 6);
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        start : IN STD_LOGIC;
        bm_ready : OUT STD_LOGIC;
        deltaXin, deltaXprevin : IN syndromevector;
        bdsin, bdsprevin : IN errorvector;
        llnumberin : IN STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
        thetain : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);
        deltaXout, deltaXprevout : OUT syndromevector;
        bdsout, bdsprevout : OUT errorvector;
        llnumberout : OUT STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
        thetaout : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1);
        nextstage : OUT STD_LOGIC
        );
  end component;

BEGIN
  syndromes_ini(1)(m_bits DOWNTO 1) <= syndromes(32)(m_bits DOWNTO 1);
  gen_zerosyn: FOR k IN 1 TO 31 GENERATE
  syndromes_ini(k+1)(m_bits DOWNTO 1) <= syndromes(k)(m_bits DOWNTO 1);
  END GENERATE;
  bdsprev_ini(1)(m_bits DOWNTO 1) <= conv_std_logic_vector (1,m_bits);
  bds_ini(1)(m_bits DOWNTO 1) <= conv_std_logic_vector (ribm,m_bits);
  gen_bda: FOR k IN 2 TO bm_symbols GENERATE
  bdsprev_ini(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
  bds_ini(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
  END GENERATE;  zerocnt_ini <= conv_std_logic_vector(0,errorcnt_width);
  onetheta <= conv_std_logic_vector (1,m_bits);

  comp_round1: rsx_bm_pe1
  GENERIC MAP (startloop=>0,endloop=>25)
  PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
            start=>start,
            bm_ready=>bm_ready,
            deltaXin=>syndromes_ini,
            deltaXprevin=>syndromes_ini,
            bdsin=>bds_ini,
            bdsprevin=>bdsprev_ini,
            llnumberin=>zerocnt_ini,
            thetain=>onetheta,
            deltaXout=>deltaX_1,
            thetaout=>theta_1,
            bdsprevout=>bdsprevnode_1,
            deltaXprevout=>deltaXprev_1,
            bdsout=>bds_1,
            llnumberout=>llnumber_1,
            nextstage=>stage(1));

  comp_round2: rsx_bm_pe1
  GENERIC MAP (startloop=>26,endloop=>31)
  PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
            start=>stage(1),
            deltaXin=>deltaX_1,
            deltaXprevin=>deltaXprev_1,
            bdsin=>bds_1,
            bdsprevin=>bdsprevnode_1,
            llnumberin=>llnumber_1,
            thetain=>theta_1,
            deltaXout=>deltaX_2,
            bdsout=>bds_2,
            llnumberout=>llnumber_2,
            nextstage=>stage(2));

  bdsout <= bds_2;
  gen_omegaout: FOR k IN 1 TO bm_symbols GENERATE
    omegaout(k) <= deltaX_2(k+1);
  END GENERATE;
  errorsout <= llnumber_2;
  stageout <= stage(2);

  done <= stageout;
  number_errors(1) <= errorsout;
  error_evaluator(1) <= omegaout;
  error_locator(1) <= bdsout;

END rtlauto;


