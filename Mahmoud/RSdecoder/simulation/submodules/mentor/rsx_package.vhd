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

USE work.rsx_parameters.all;
USE work.rsx_functions.all;

PACKAGE rsx_package IS
  
  constant first_root : integer := 0;
  constant field_modulo : positive := 2**m_bits - 1;
  constant check_symbols : positive := n_symbols - k_symbols;
  constant error_symbols : positive := check_symbols/2;
  constant parallel_symbols_per_channel : positive := parallel_symbols/channel;
  constant riBm : integer := is_riBm_used(polynomial_speed);
  
  constant codeword_clocks : positive := howmanyclocks(n_symbols,parallel_symbols_per_channel);
  constant polynomial_cores : positive := howmanycores(codeword_clocks,polynomial_speed);
  constant gap_symbols : integer := 0;
  
  constant syndcnt_width : positive := clog2(codeword_clocks);
  
  constant last_symbols : positive := parallel_symbols - gap_symbols; -- number of non 0'd symbols in last part of codeword
  
  constant search_offset : integer := field_modulo - n_symbols + 1;
  
  constant even_terms : positive := error_symbols / 2; -- floor(error_symbols/2)
  constant derivative_terms : positive := (error_symbols+1) / 2; -- ceil(error_symbols/2))

  constant number_cores : positive := channel;
  constant number_cores_per_channel : positive := 2;
  
  constant parallel_searchsymbols : positive := parallel_symbols_per_channel / number_cores_per_channel;
  constant last_searchsymbols : positive := parallel_symbols_per_channel - parallel_searchsymbols * (number_cores_per_channel-1); 
  
  constant data_width : positive := parallel_symbols * m_bits;
  
  constant checkcnt_width   : positive := clog2(check_symbols+1);
  constant errorcnt_width   : positive := clog2(error_symbols+2); -- to be able to count one more error
  constant errorcnt_width_o : positive := clog2(error_symbols+1);
  
  constant nbinvmax : positive := max(parallel_symbols,nb_bm_core);

  constant bm_symbols : positive := error_symbols + riBm;

  -- FIFO
  -- in Normal mode, area optimization (add_ram_output_register = "OFF", lpm_showahead = "OFF")
  constant  fifo_delay : positive := 1;

  type symbol_in_syndromevector IS ARRAY (parallel_symbols_per_channel DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type symbol_in_syndrome IS ARRAY (channel DOWNTO 1) OF symbol_in_syndromevector;
  
  type syndromevector IS ARRAY (check_symbols DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type syndrome_out_vector IS ARRAY (channel DOWNTO 1) OF syndromevector;
  
  type errorvector    IS ARRAY (bm_symbols DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type parallelvector IS ARRAY (parallel_symbols DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  type chien_in_vector IS ARRAY (channel DOWNTO 1) OF errorvector;

  type evenvector IS ARRAY (even_terms DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type oddvector IS ARRAY (derivative_terms DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type searchvector IS ARRAY (parallel_searchsymbols DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  type lastsearchvector IS ARRAY (last_searchsymbols DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  type nb_errors_type IS ARRAY (channel DOWNTO 1) OF STD_LOGIC_VECTOR (errorcnt_width DOWNTO 1);
  
  type inv_alpha_type IS ARRAY (nbinvmax DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
  function log2_ceil_one(arg : in integer) return integer;  -- log2_ceil(1)=0
  function get_count_error_base(par : in integer) return integer;
  function get_duplication_factor(par : in integer) return integer;
    
    component rsx_fit_counter
    GENERIC (
           minus_one : positive := 142
          ); 
    PORT  (
          sysclk, reset : IN STD_LOGIC;
          address, data : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
          );
    end component;
    
                  
END rsx_package;

PACKAGE BODY rsx_package IS
  ---------------------------------------------------------------------------
  -- LOG2_CEIL_ONE Function.
  ---------------------------------------------------------------------------
  function log2_ceil_one(arg : in integer) return integer is
    variable res : integer;
  begin
    res := 0;
    for i in 0 to 30 loop
      if (arg > (2**i)) then
        res := i+1;
      end if;
    end loop;  -- i
    if res = 0 then
      res := 1;
    end if;
    return res;
  end log2_ceil_one;
  
  function get_duplication_factor(par : in integer) return integer is
    variable dup : integer;
  begin
    if par <= 36 then
      dup := 1;
    elsif par <= 64 then
      dup := 2;
    else
      dup := 3;
    end if;
    return dup;
  end get_duplication_factor;
  
  function get_count_error_base(par : in integer) return integer is
    variable bas : integer;
  begin
    if par <= 36 then
      bas := 6;
    elsif par <= 49 then
      bas := 7;
    elsif par <= 64 then
      bas := 8;
    end if;
    return bas;
  end get_count_error_base;
  
  END PACKAGE BODY rsx_package;
  
