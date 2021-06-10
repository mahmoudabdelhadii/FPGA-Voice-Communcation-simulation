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
USE ieee.numeric_std.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all; 

USE work.bchp_parameters.all;
USE work.bchp_package.all;
USE work.bchp_auto_package.all;
USE work.bchp_roots.all;
USE work.bchp_functions.all;

library altera_mf;

--******************************************************************************
--***                                                                        ***
--***   ALTERA BCH LIBRARY                                                   ***
--***                                                                        ***
--***   BCHP_DECODER                                                         ***
--***                                                                        ***
--***   Function: High Speed Parallel BCH Decoder                            ***
--***                                                                        ***
--***   26/06/13 ML                                                          ***
--***                                                                        ***
--***   (c) 2013 Altera Corporation                                          ***
--***                                                                        ***
--***   Change History                                                       ***
--***                                                                        ***
--***   17/12/14 Updated 2014 Version                                        ***
--***                                                                        ***
--***                                                                        ***
--******************************************************************************

--******************************************************************************
--***                                                                        ***
--*** 2014 Version                                                           ***
--***                                                                        ***
--*** 1. Last GF() element always generated in INVMEM.HEX                    ***
--*** 2. Optimized iterations for polynomials                                ***
--*** 3. Systolic Polynomial Array per PE correct for all Polynomials        ***
--*** 4. Optional Power Savings mode for Chien Searchs when data gaps        ***
--***                                                                        ***
--******************************************************************************

--******************************************************************************
--***                                                                        ***
--*** 2013 Version                                                           ***
--***                                                                        ***
--*** 1. Arbitrary gaps supported in data stream                             ***
--*** 2. Syndrome generation using squares                                   ***
--*** 3. Systolic Polynomial Array with optimized vector size per PE         ***
--*** 4. Search using array GF reduction, definable search decomposition     ***
--***                                                                        ***
--******************************************************************************

ENTITY bchp_decoder_core IS 
PORT (
      sysclk, reset : IN STD_LOGIC;
      load : IN STD_LOGIC;
      bits : IN STD_LOGIC_VECTOR (parallel_bits DOWNTO 1);
      sop_in, eop_in : IN STD_LOGIC;
    
      bits_out : OUT STD_LOGIC_VECTOR (parallel_bits DOWNTO 1);
      sop_out  : OUT STD_LOGIC;
      validout : OUT STD_LOGIC;
      number_errors : OUT STD_LOGIC_VECTOR (8 DOWNTO 1)
		 );
END bchp_decoder_core;

ARCHITECTURE rtl OF bchp_decoder_core IS

  type number_errorsfftype IS ARRAY (8 DOWNTO 1) OF STD_LOGIC_VECTOR (8 DOWNTO 1);

  signal startff : STD_LOGIC_VECTOR (6 DOWNTO 1);
  signal validff : STD_LOGIC;
  signal validcountff : UNSIGNED (16 DOWNTO 1);
  signal countok : STD_LOGIC;
  signal number_errorsff : number_errorsfftype;
  signal bits_outff : STD_LOGIC_VECTOR (parallel_bits DOWNTO 1);

  signal syndromes : syndromevector;
  signal syndromes_done : STD_LOGIC;
  
  signal bd : errorvector;
  signal number_errorsnode : STD_LOGIC_VECTOR (8 DOWNTO 1);

  signal error_found : STD_LOGIC_VECTOR (parallel_bits DOWNTO 1);


  component bchp_syndromes_sqr
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        load : IN STD_LOGIC;
        bits : IN STD_LOGIC_VECTOR (parallel_bits DOWNTO 1);
    
        syndromes : OUT syndromevector;
        synvalid : OUT STD_LOGIC
        );
  end component;
 	

  component bchp_mb_system
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        start : IN STD_LOGIC;
        syndromes : IN syndromevector;

        bd : OUT errorvector;
        errors : OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
        done : OUT STD_LOGIC 
  );
  end component;
 	

  component bchp_search IS 
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        start_search : IN STD_LOGIC;
        errorlocator : IN errorvector; -- error locator polynomial, shifted for first index
      
        error_found : OUT STD_LOGIC_VECTOR (parallel_bits DOWNTO 1)
        );
  end component; 


  -- single-clock FIFO from altera_mf library
  component scfifo
  generic (
           add_ram_output_register: string := "OFF";
           allow_rwcycle_when_full: string := "OFF";
           almost_empty_value: natural := 0;
           almost_full_value: natural := 0;
           lpm_numwords: natural;
           lpm_showahead: string := "OFF";
           lpm_width: natural;
           lpm_widthu: natural := 1;
           overflow_checking: string := "ON";
           underflow_checking: string := "ON";
           use_eab: string := "ON";
           lpm_hint: string := "UNUSED";
           lpm_type: string := "scfifo"
           );
  port    (
           aclr: in std_logic := '0';
           almost_empty: out std_logic;
           almost_full: out std_logic;
           clock: in std_logic;
           data: in std_logic_vector(lpm_width-1 downto 0);
           empty: out std_logic;
           full: out std_logic;
           q : out std_logic_vector(lpm_width-1 downto 0);
           rdreq: in std_logic;
           sclr: in std_logic := '0';
           usedw: out std_logic_vector(lpm_widthu-1 downto 0);
           wrreq: in std_logic
           );
  end component;
  	

  -- connecting signals of the bits FIFO
  constant lpm_numwords : positive := howmany_fifo_words(codeword_clocks, poly_delay);
  constant lpm_widthu : positive := log2_function(lpm_numwords-1)+1; -- width of the usedw port
  constant almost_full_value : natural := lpm_numwords*4/5; -- almost full signal raised at this value
  signal fifo_rdreq : STD_LOGIC;
  signal del_bits_fifo : STD_LOGIC_VECTOR (parallel_bits downto 1);

  -- latency control
  constant num_latency_counter : natural := ((poly_delay+2)/codeword_clocks + 1) + 1; -- number of latency counters (last +1 is for quantization margin)
  type counter_array IS ARRAY (num_latency_counter downto 1) of integer RANGE 0 to poly_delay+2;
  signal latency_counter : counter_array;
  signal chien_start_node : std_logic;
  signal counter_finish : std_logic_vector (num_latency_counter downto 1);
  signal counter_busy : std_logic_vector (num_latency_counter downto 0);

  -- signal that deals with transmission gap
  signal packet_started, enable : std_logic;

	 	   
BEGIN

  -- updated on 09/03/2015: the enable process is used for forward pressure, to deal with transmission gap
  en_proc : process(sysclk)
  begin
    if rising_edge(sysclk) then
      if reset = '1' then
        packet_started <= '0';
      else
        if sop_in = '1' then
          packet_started <= '1';
        elsif eop_in = '1' then
          packet_started <= '0';
        end if;
      end if;
    end if;
  end process;

  enable <= not(packet_started and not(load));


  -- updated on 12/02/2015, the fixed delay module is replaced by FIFO
  -- the FIFO holds all input bits, waiting for found errors from Chien search
  bits_fifo : scfifo
  GENERIC MAP (
               almost_full_value        => almost_full_value,
               lpm_numwords             => lpm_numwords,
               lpm_showahead            => "OFF",
               lpm_width                => parallel_bits,
               lpm_widthu               => lpm_widthu,
               lpm_type                 => "scfifo"
              )
  PORT MAP (
            almost_full   => open,
            clock         => sysclk,
            data          => bits,
            empty         => open,
            full          => open,
            q             => del_bits_fifo,
            rdreq         => fifo_rdreq,
            sclr          => reset,
            usedw         => open,
            wrreq         => load
           );
  
  -- process for synchronising the input FIFO and output from Chien search module
  prc_del : PROCESS (sysclk)
  BEGIN
    
    IF rising_edge(sysclk) THEN

      IF (reset  = '1') THEN
    
        startff <= "000000";
        validff <= '0';
        sop_out <= '0';
        validcountff <= to_unsigned(0,16);
        fifo_rdreq <= '0';
        FOR k IN 1 TO 8 LOOP
          number_errorsff(k)(8 DOWNTO 1) <= "00000000";
        END LOOP;
        FOR k IN 1 TO parallel_bits LOOP
          bits_outff(k) <= '0';
        END LOOP;

      ELSE

        IF (startff(5) = '1') OR (startff(6) = '1') OR (validcountff > 2) THEN
          fifo_rdreq <= '1';
        ELSE
          fifo_rdreq <= '0';
        END IF;
      
        startff(1) <= chien_start_node;
          FOR k IN 2 TO 6 LOOP
          startff(k) <= startff(k-1);
        END LOOP;
      
        IF (startff(6) = '1') THEN
          validcountff <= to_unsigned(codeword_clocks,16);
        ELSIF (countok = '1') THEN
          validcountff <= validcountff - 1;
        END IF;
      
        validff <= countok;

        -- startofpacket signal
        IF validcountff = to_unsigned(codeword_clocks,16) THEN
          sop_out <= '1';
        ELSE
          sop_out <= '0';
        END IF;
      
        IF (chien_start_node = '1') THEN
          number_errorsff(1)(8 DOWNTO 1) <= number_errorsnode;
        END IF;
        FOR k IN 2 TO 8 LOOP
          number_errorsff(k)(8 DOWNTO 1) <= number_errorsff(k-1)(8 DOWNTO 1);
        END LOOP;
      
        FOR k IN 1 TO parallel_bits LOOP
          bits_outff(k) <= del_bits_fifo(k) XOR error_found(k);
        END LOOP;

      END IF;
        
    END IF;
    
  END PROCESS;
  
  countok <= validcountff(16) OR validcountff(15) OR validcountff(14) OR validcountff(13) OR
             validcountff(12) OR validcountff(11) OR validcountff(10) OR validcountff(9) OR 
             validcountff(8) OR  validcountff(7) OR  validcountff(6) OR  validcountff(5) OR 
             validcountff(4) OR  validcountff(3) OR  validcountff(2) OR  validcountff(1);



  -- process for buffering between BM system and Chien search module
  prc_chien_start : PROCESS (latency_counter, counter_busy, counter_finish)
  BEGIN

    counter_busy(0) <= '1'; -- counter_busy(0) bit is not tied to any latency counter

    FOR j IN 1 TO num_latency_counter LOOP
      IF latency_counter(j) = poly_delay+2 THEN
        counter_finish(j) <= '1';
      ELSE
        counter_finish(j) <= '0';
      END IF;

      IF latency_counter(j) > 0 THEN
        counter_busy(j) <= '1';
      ELSE
        counter_busy(j) <= '0';
      END IF;
    END LOOP;

    IF unsigned(counter_finish) > 0 THEN
      chien_start_node <= '1';
    ELSE
      chien_start_node <= '0';
    END IF;

  END PROCESS;


  prc_latency_control : PROCESS (sysclk)

    variable all_one_pattern : std_logic_vector (num_latency_counter downto 0); -- this is a variable used to validate latency_counter busy pattern

  BEGIN

    IF rising_edge(sysclk) THEN

      IF (reset  = '1') THEN

        latency_counter <= (others=>0);
      
      ELSE
        all_one_pattern := (others => '1');
  
        FOR j IN 1 TO num_latency_counter LOOP
          IF (latency_counter(j) = 0) AND (syndromes_done = '1') AND (counter_busy(j-1 downto 0) = all_one_pattern(j-1 downto 0)) THEN
            latency_counter(j) <= latency_counter(j) + 1;
          ELSIF (latency_counter(j) > 0) AND (latency_counter(j) < poly_delay + 2) THEN
            latency_counter(j) <= latency_counter(j) + 1;
          ELSIF latency_counter(j) = poly_delay + 2 THEN
            latency_counter(j) <= 0;
          END IF;
        END LOOP;

      END IF;

    END IF;

  END PROCESS;
  
         


  -- connecting the major modules for the system
  comp_syn: bchp_syndromes_sqr
  PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
            load=>load,
            bits=>bits,
            syndromes=>syndromes,
            synvalid=>syndromes_done);

  comp_poly: bchp_mb_system 
  PORT MAP (sysclk=>sysclk,reset=>reset,enable=>'1',
            start=>syndromes_done,
            syndromes=>syndromes,
            bd=>bd,
            errors=>number_errorsnode,
            done=>open);

  comp_find: bchp_search 
  PORT MAP (sysclk=>sysclk,reset=>reset,enable=>'1',
            start_search=>chien_start_node,
            errorlocator=>bd,
            error_found=>error_found);

		              
  bits_out <= bits_outff;
  number_errors <= number_errorsff(8)(8 DOWNTO 1);
  validout <= validff;
  
END rtl;

