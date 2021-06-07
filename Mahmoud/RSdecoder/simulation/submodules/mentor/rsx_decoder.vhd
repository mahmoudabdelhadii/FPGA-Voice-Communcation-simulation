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
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;

USE work.rsx_parameters.all;
USE work.rsx_package.all;

--***************************************************
--***                                             ***
--***   ALTERA REED SOLOMON LIBRARY               ***
--***                                             ***
--***   RSX_DECODER                               ***
--***                                             ***
--***   Function: Parallel Reed Solomon Decoder   ***
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

ENTITY rsx_decoder IS
PORT (
      sysclk, reset, enable : IN STD_LOGIC;
      valid_in : IN STD_LOGIC;
      --sop_in : IN STD_LOGIC;
      --eop_in : IN STD_LOGIC;
      symbols_in : IN STD_LOGIC_VECTOR (data_width DOWNTO 1);
      bypass : IN STD_LOGIC := '0';
    
      symbols_out : OUT STD_LOGIC_VECTOR (data_width DOWNTO 1);
      errorvalues_out : OUT STD_LOGIC_VECTOR (data_width DOWNTO 1);
      errors_out : OUT STD_LOGIC_VECTOR (errorcnt_width_o*channel DOWNTO 1);
      decfail : OUT STD_LOGIC_VECTOR (channel DOWNTO 1);
      valid_out : OUT STD_LOGIC;
      sop_out : OUT STD_LOGIC;
      eop_out : OUT STD_LOGIC;
      ready_in : OUT STD_LOGIC
         );
END rsx_decoder;

ARCHITECTURE rtl of rsx_decoder IS
    
  constant symbolsdelay : positive := codeword_clocks + 4 + -- 4 = syndrome latency
                                      polynomial_speed * check_symbols * channel + 4 + -- 4 = omega latency
                                      6; -- error latency                                  
                                      
  type number_errorsfftype IS ARRAY (8 DOWNTO 1) OF nb_errors_type;
  
  signal syndromes     : syndromevector;
  signal done_syndrome : STD_LOGIC;
  signal syndrome_valid : STD_LOGIC;
  signal valid_in_syndrome : STD_LOGIC;

  signal symbols_in_par  : parallelvector;
  signal symbols_out_par : parallelvector;
  signal error_out_par   : parallelvector;
  
  
  signal bd            : chien_in_vector;
  signal omega         : chien_in_vector;
  signal nb_errors_found_in_bm : nb_errors_type;
  signal done_mb       : STD_LOGIC;
  signal bm_ready       : STD_LOGIC;
  
  signal error_found        : STD_LOGIC_VECTOR (parallel_symbols DOWNTO 1);
  signal nb_errors_found_in_chien : nb_errors_type;
  signal error_correct      : parallelvector;
  signal valid_ch           : STD_LOGIC;
  signal first_check_ch     : STD_LOGIC;
  signal last_check_ch      : STD_LOGIC;
  
  signal symbols_fifo     : STD_LOGIC_VECTOR (data_width DOWNTO 1);    
  signal symbols_fifo_par : parallelvector;    
    
  signal symbols_outff   : parallelvector;
  signal error_outff     : parallelvector;
  signal nb_errors_found_in_bmff : number_errorsfftype;
  
  signal read_fifo     : STD_LOGIC;
  signal valid_outff   : STD_LOGIC;
  signal first_checkff  : STD_LOGIC;
  signal last_checkff  : STD_LOGIC;
  signal has_decoding_failed  : STD_LOGIC_VECTOR (channel DOWNTO 1);
  
  signal ready_fifo : STD_LOGIC;
  signal cancel_syndrome : STD_LOGIC;
  signal valid_bypass, valid_bypassff : STD_LOGIC;
  signal sop_bypass, sop_bypassff : STD_LOGIC;
  signal eop_bypass, eop_bypassff : STD_LOGIC;
  signal syndrome_isnot_null : STD_LOGIC_VECTOR (channel DOWNTO 1);
  
  
  component rsx_syndrome 
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        load : IN STD_LOGIC;
        bm_ready : IN STD_LOGIC;
        symbols : IN parallelvector;
    
        syndromes : OUT syndromevector;
        are_syndromes_not_null : OUT STD_LOGIC_VECTOR (channel DOWNTO 1);
        synvalid : OUT STD_LOGIC
           );
  end component;

  component rsx_bm_auto
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        start : IN STD_LOGIC;
        syndromes : IN syndromevector;

            error_locator : OUT chien_in_vector;
            error_evaluator : OUT chien_in_vector;
            number_errors : OUT nb_errors_type;
            bm_ready : OUT STD_LOGIC;
            done : OUT STD_LOGIC
         );
      end component;
    
      component rsx_search
  GENERIC (
           stopnumber : integer := 127;
           index : integer := 1  -- index is 1,2,3,4,5 
          );
  PORT (
        sysclk, reset, enable : IN STD_LOGIC;
        start : IN STD_LOGIC;
        bd : IN chien_in_vector;
        omega : IN chien_in_vector;
      
            error_found   : OUT STD_LOGIC_VECTOR (parallel_symbols DOWNTO 1);
            number_errors : OUT nb_errors_type;
            error_correct : OUT parallelvector;
            can_read_fifo : OUT STD_LOGIC;
            last_check : OUT STD_LOGIC;
            first_check : OUT STD_LOGIC;
            valid : OUT STD_LOGIC
           );
    end component;
    
  component rsp_fifo
  GENERIC (
         width : positive := 64;
         pipes : positive := 1
        );
  PORT (
      sysclk : IN STD_LOGIC;
      reset : IN STD_LOGIC;
      enable : IN STD_LOGIC;
      write_aa : IN STD_LOGIC;
      read_cc : IN STD_LOGIC;
      aa : IN STD_LOGIC_VECTOR (width DOWNTO 1); 
      cc : OUT STD_LOGIC_VECTOR (width DOWNTO 1)
     );
  end component; 
  
  component rsx_fifo IS 
  GENERIC (
         width : positive := 64;
         depth : positive := 1
        );
  PORT (
      clk : IN STD_LOGIC;
      reset : IN STD_LOGIC;
      enable : IN STD_LOGIC;
      ready_to_input : OUT STD_LOGIC;
      valid_in : IN STD_LOGIC;
      valid_to_syndrome : OUT STD_LOGIC;
      valid_out : OUT STD_LOGIC;
      sop_out : OUT STD_LOGIC;
      eop_out : OUT STD_LOGIC;
      read_cc : IN STD_LOGIC;
      bypass : IN STD_LOGIC;
      cancel_syndrome : OUT STD_LOGIC;
      aa : IN STD_LOGIC_VECTOR (width DOWNTO 1); 
      cc : OUT STD_LOGIC_VECTOR (width DOWNTO 1)
     );
  end component ;
  
  
  constant tclk : time := 1 us;

BEGIN
  
    map_serial_parallel : FOR k IN 1 TO parallel_symbols GENERATE
       symbols_in_par(k)(m_bits DOWNTO 1) <= symbols_in(k*m_bits DOWNTO 1+m_bits*(k-1));
       symbols_out(k*m_bits DOWNTO 1+m_bits*(k-1))<= symbols_out_par(k)(m_bits DOWNTO 1);
       errorvalues_out(k*m_bits DOWNTO 1+m_bits*(k-1))<= error_out_par(k)(m_bits DOWNTO 1);
    END GENERATE;
    

    comp_syn: rsx_syndrome
    PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
              load=> valid_in_syndrome,
              symbols=>symbols_in_par,
              syndromes=>syndromes,
              are_syndromes_not_null=>syndrome_isnot_null,
              bm_ready=>bm_ready,
              synvalid=>done_syndrome);
              
    syndrome_valid <= done_syndrome AND NOT(cancel_syndrome);
                          
  comp_poly: rsx_bm_auto
  PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
            start=>syndrome_valid,
            bm_ready=>bm_ready,
            syndromes=>syndromes,
            
            error_locator=>bd,
            error_evaluator=>omega,
            number_errors=>nb_errors_found_in_bm,
            done=>done_mb);
            
  comp_chien1: rsx_search
  GENERIC MAP (stopnumber=>codeword_clocks,index=>search_offset)
  PORT MAP (sysclk=>sysclk,reset=>reset,enable=>enable,
            start=>done_mb,
            bd=>bd,omega=>omega,
            error_found=>error_found,error_correct=>error_correct,
            number_errors=>nb_errors_found_in_chien,
            can_read_fifo=>read_fifo,
            first_check=>first_check_ch,
            last_check=>last_check_ch,
            valid=>valid_ch);

  comp_fifo_test: rsx_fifo 
  GENERIC MAP(width=>data_width,depth=>symbolsdelay)
  PORT MAP (clk=>sysclk,reset=>reset, enable=>enable,
            ready_to_input=>ready_fifo,
            valid_in=>valid_in,
            valid_to_syndrome=>valid_in_syndrome,
            valid_out=>valid_bypass,
            cancel_syndrome=>cancel_syndrome,
            read_cc=> read_fifo,
            sop_out=> sop_bypass,
            eop_out=> eop_bypass,
            bypass=>bypass,
            aa=>symbols_in(data_width DOWNTO 1),
            cc=>symbols_fifo(data_width DOWNTO 1));
            
    prc_out: PROCESS (sysclk,reset)
    BEGIN
      
      IF (reset = '1') THEN
        FOR k IN 1 TO parallel_symbols LOOP
          symbols_fifo_par(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
        END LOOP;
        FOR k IN 1 TO parallel_symbols LOOP
          symbols_outff(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
          error_outff(k)(m_bits DOWNTO 1) <= conv_std_logic_vector (0,m_bits);
        END LOOP;
        FOR k IN 1 TO 8 LOOP
          FOR j IN 1 TO channel LOOP
            nb_errors_found_in_bmff(k)(j)(errorcnt_width DOWNTO 1) <= conv_std_logic_vector (0,errorcnt_width);
          END LOOP;
        END LOOP;
        
        first_checkff <= '0';
        last_checkff <= '0';
        
        valid_outff <= '0';
        valid_bypassff <= '0';
        sop_bypassff <= '0';
        eop_bypassff <= '0';
        has_decoding_failed <= conv_std_logic_vector (0,channel);
        
      ELSIF (rising_edge(sysclk)) THEN
        
        IF (enable = '1') THEN
          FOR k IN 1 TO parallel_symbols LOOP
             symbols_fifo_par(k)(m_bits DOWNTO 1) <= symbols_fifo(k*m_bits DOWNTO 1+m_bits*(k-1));
          END LOOP;
          FOR k IN 1 TO parallel_symbols LOOP
            FOR m IN 1 TO m_bits LOOP
              symbols_outff(k)(m) <= symbols_fifo_par(k)(m) XOR (error_correct(k)(m) AND error_found(k));
              error_outff(k)(m) <=  error_correct(k)(m) AND error_found(k);
            END LOOP;
          END LOOP;
          
          
          FOR j IN 1 TO channel LOOP
            nb_errors_found_in_bmff(1)(j) <= nb_errors_found_in_bm(j);
            FOR k IN 2 TO 7 LOOP
              nb_errors_found_in_bmff(k)(j) <= nb_errors_found_in_bmff(k-1)(j);
            END LOOP;
            IF polynomial_speed > 2 THEN
              nb_errors_found_in_bmff(8)(j) <= nb_errors_found_in_bmff(8-1)(j);
            ELSIF polynomial_speed < 4 AND first_check_ch = '1' THEN
              nb_errors_found_in_bmff(8)(j) <= nb_errors_found_in_bmff(8-1)(j);
            END IF;

            IF (eop_bypassff = '1') THEN
              has_decoding_failed(j) <= syndrome_isnot_null(j);
            ELSIF (nb_errors_found_in_bmff(8)(j) = nb_errors_found_in_chien(j)) THEN
              has_decoding_failed(j) <= '0';
            ELSE
              has_decoding_failed(j) <= last_check_ch AND valid_ch;
            END IF;
          END LOOP;

          valid_bypassff <= valid_bypass;
          sop_bypassff <= sop_bypass;
          eop_bypassff <= eop_bypass;

          first_checkff <= first_check_ch OR sop_bypassff;
          last_checkff <= last_check_ch OR eop_bypassff;          
          valid_outff <= valid_ch OR valid_bypassff;
          
        END IF;
        
      END IF;
      
    END PROCESS;
      
  gen_out: FOR k IN 1 TO parallel_symbols GENERATE
    symbols_out_par(k)(m_bits DOWNTO 1) <= symbols_outff(k)(m_bits DOWNTO 1);
    error_out_par(k)(m_bits DOWNTO 1) <= error_outff(k)(m_bits DOWNTO 1);
  END GENERATE;
  gen_out_error: FOR k IN 1 TO channel GENERATE
    errors_out(k*errorcnt_width_o DOWNTO (k-1)*errorcnt_width_o+1) <= nb_errors_found_in_bmff(8)(k)(errorcnt_width_o DOWNTO 1);
    decfail(k) <= has_decoding_failed(k);
  END GENERATE;
  sop_out <= first_checkff;
  eop_out <= last_checkff;
  valid_out <= valid_outff;
  ready_in <= ready_fifo;
  
END rtl;

