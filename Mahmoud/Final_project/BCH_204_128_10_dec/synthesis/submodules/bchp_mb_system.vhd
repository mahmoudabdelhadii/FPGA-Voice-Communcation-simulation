LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;

USE work.bchp_parameters.all;
USE work.bchp_package.all;
USE work.bchp_roots.all;

ENTITY bchp_mb_system IS
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      start : IN STD_LOGIC;
      syndromes : IN syndromevector;

      bd : OUT errorvector;
      errors : OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
      done : OUT STD_LOGIC
);
END bchp_mb_system;

ARCHITECTURE rtl OF bchp_mb_system IS

  signal zerosyndromes : syndromevector;
  signal zerobds, zerobdsprev : errorvector;

  signal zeroll : STD_LOGIC_VECTOR (8 DOWNTO 1);
  signal zerodelta : STD_LOGIC_VECTOR (m_bits DOWNTO 1);

  signal syndromes_1 : syndromevector;
  signal bds_1, bdsprev_1 : errorvector;
  signal delta_1 : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  signal ll_1 : STD_LOGIC_VECTOR (8 DOWNTO 1);
  signal onebit_1 : STD_LOGIC;
  signal done_1 : STD_LOGIC;

  signal bdff : errorvector;
  signal llff : STD_LOGIC_VECTOR (8 DOWNTO 1);
  signal doneff : STD_LOGIC;

BEGIN

  zerosyndromes(1)(m_bits DOWNTO 1) <= syndromes(check_symbols-1)(m_bits DOWNTO 1);
  zerosyndromes(2)(m_bits DOWNTO 1) <= syndromes(check_symbols)(m_bits DOWNTO 1);
  gen_zerosyn: FOR k IN 1 TO check_symbols-2 GENERATE
    zerosyndromes(k+2)(m_bits DOWNTO 1) <= syndromes(k)(m_bits DOWNTO 1);
  END GENERATE;
  gen_zerobds: FOR k IN 1 TO t_symbols GENERATE
    zerobds(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
  END GENERATE;
  zerobdsprev(1)(m_bits DOWNTO 1) <= conv_std_logic_vector (1,m_bits);
  gen_zerobdprevs: FOR k IN 2 TO t_symbols GENERATE
    zerobdsprev(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
  END GENERATE;
  zeroll <= conv_std_logic_vector (0,8);
  zerodelta <= conv_std_logic_vector (0,m_bits);

  comp_01: bchp_mb_pex 
  GENERIC MAP (speed=>6,startloop=>0,endloop=>18)
  PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,start=>start,syndromesin=>zerosyndromes,
            bdsin=>zerobds,bdsprevin=>zerobdsprev,llnumberin=>zeroll,deltain=>zerodelta,

            syndromesout=>syndromes_1,bdsout=>bds_1,bdsprevout=>bdsprev_1,llnumberout=>ll_1,deltaout=>delta_1,
            nextstage=>done_1);

  prc_hold: PROCESS (sysclk)
  BEGIN
    IF (rising_edge(sysclk)) THEN
      IF (reset = '1') THEN
      FOR k IN 1 TO t_symbols LOOP
        bdff(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
      END LOOP;
      llff <= conv_std_logic_vector (0,8);
      doneff <= '0';
      ELSIF (enable = '1') THEN
        IF (done_1 = '1') THEN
          FOR k IN 1 TO t_symbols LOOP
            bdff(k)(m_bits DOWNTO 1) <= bds_1(k)(m_bits DOWNTO 1);
          END LOOP;
          llff <= ll_1;
        END IF;
        doneff <= done_1;
      END IF;
    END IF;
  END PROCESS;

  bd <= bdff;
  errors <= llff;
  done <= doneff;

END rtl;


