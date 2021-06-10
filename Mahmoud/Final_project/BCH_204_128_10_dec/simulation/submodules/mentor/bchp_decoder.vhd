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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.bchp_parameters.all;
use work.bchp_functions.all;
use work.bchp_auto_package.all;
use work.bchp_package.all;

library altera_mf;

entity bchp_decoder is
  port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    data_in   : in  std_logic_vector(parallel_bits-1 DOWNTO 0);
    load      : in  std_logic;
    sop_in    : in  std_logic;
    eop_in    : in  std_logic;
    sink_ready: in  std_logic;

    ready     : out std_logic;
    data_out  : out std_logic_vector(parallel_bits-1 DOWNTO 0);
    number_errors : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
    valid_out : out std_logic;
    sop_out   : out std_logic;
    eop_out   : out std_logic
    );
end entity;



architecture arch of bchp_decoder is

  component bchp_decoder_core
    port     (
              sysclk, reset : IN STD_LOGIC;
              load : IN STD_LOGIC;
              bits : IN STD_LOGIC_VECTOR (parallel_bits DOWNTO 1);
              sop_in, eop_in : IN STD_LOGIC;
    
              bits_out : OUT STD_LOGIC_VECTOR (parallel_bits DOWNTO 1);
              sop_out  : OUT STD_LOGIC;
              validout : OUT STD_LOGIC;
              number_errors : OUT STD_LOGIC_VECTOR (8 DOWNTO 1)
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


  signal dec_load, dec_valid_out: std_logic;
  signal dec_sop_in, dec_eop_in, dec_sop_out, dec_eop_out : std_logic;
  signal dec_data_in, dec_data_out : std_logic_vector (parallel_bits-1 downto 0);
  signal dec_num_errors_out : std_logic_vector (7 downto 0);
  signal eop_counter : natural;

  -- connecting signals of the input FIFO
  constant input_lpm_numwords : positive := 5; -- input fifo must have length > 1
  constant input_lpm_widthu : positive := log2_function(input_lpm_numwords-1)+1; -- width of the usedw port
  signal input_fifo_rdreq, input_fifo_wrreq : STD_LOGIC;
  signal input_fifo_empty, input_fifo_full: STD_LOGIC;
  signal input_fifo_usedw: STD_LOGIC_VECTOR (input_lpm_widthu-1 downto 0);
  signal input_fifo_data, input_fifo_q : STD_LOGIC_VECTOR (parallel_bits+1 downto 0); -- MSB are the startofpacket and endofpacket signals

  -- connecting signals of the output FIFO
  constant output_lpm_numwords : positive := input_lpm_numwords + poly_delay + 8 + codeword_clocks + (log2_function(t_symbols)*2+4); -- free_buffer + BM_delay + t_chien + codeword_clocks + t_syn
  constant output_lpm_widthu : positive := log2_function(output_lpm_numwords-1)+1; -- width of the usedw port
  signal output_fifo_rdreq, output_fifo_wrreq : STD_LOGIC;
  signal output_fifo_empty, output_fifo_full: STD_LOGIC;
  signal output_fifo_usedw: STD_LOGIC_VECTOR (output_lpm_widthu-1 downto 0);
  signal output_fifo_data, output_fifo_q : STD_LOGIC_VECTOR (parallel_bits+1+8 downto 0); -- MSB are the startofpacket and endofpacket signals; LSB are 8 bits number_errors
  signal output_fifo_almost_full : std_logic;
  constant output_almost_full_value : natural := input_lpm_numwords; -- almost full signal raised at this value

begin

  bchp_decoder_core_inst : bchp_decoder_core
    port map (sysclk          => clk,
              reset           => reset,
              load            => dec_load,
              bits            => dec_data_in,
              sop_in          => dec_sop_in,
              eop_in          => dec_eop_in,
    
              bits_out        => dec_data_out,
              sop_out         => dec_sop_out,
              validout        => dec_valid_out,
              number_errors   => dec_num_errors_out
              );

  eop_proc : process (clk)
  begin
    
    if (rising_edge(clk)) then

      if reset = '1' then
        dec_eop_out <= '0';
        eop_counter <= 0;

      else

      -- endofpacket counter counting the number of outputs so far after the last startofpacket signal
      if dec_sop_out = '1' then
        eop_counter <= 1;
      elsif dec_valid_out = '1' then
        eop_counter <= eop_counter + 1;
      elsif eop_counter = codeword_clocks - 2 then
        eop_counter <= 0;
      end if;

      -- endofpacket signal output
      if eop_counter = codeword_clocks - 2 then
        dec_eop_out <= '1';
      else
        dec_eop_out <= '0';
      end if;

      end if;

    end if;
  end process;



  input_fifo : scfifo
  GENERIC MAP (
               lpm_numwords             => input_lpm_numwords,
               lpm_showahead            => "ON",
               lpm_width                => parallel_bits+2,
               lpm_widthu               => input_lpm_widthu,
               lpm_type                 => "scfifo"
              )
  PORT MAP (
            clock         => clk,
            data          => input_fifo_data,
            empty         => input_fifo_empty,
            full          => input_fifo_full,
            q             => input_fifo_q,
            rdreq         => input_fifo_rdreq,
            usedw         => input_fifo_usedw,
            wrreq         => input_fifo_wrreq,
            sclr          => reset
           );

  output_fifo : scfifo
  GENERIC MAP (
               almost_full_value        => output_almost_full_value,
               lpm_numwords             => output_lpm_numwords,
               lpm_showahead            => "ON",
               lpm_width                => parallel_bits+2+8,
               lpm_widthu               => output_lpm_widthu,
               lpm_type                 => "scfifo"
              )
  PORT MAP (
            almost_full   => output_fifo_almost_full,
            clock         => clk,
            data          => output_fifo_data,
            empty         => output_fifo_empty,
            full          => output_fifo_full,
            q             => output_fifo_q,
            rdreq         => output_fifo_rdreq,
            usedw         => output_fifo_usedw,
            wrreq         => output_fifo_wrreq,
            sclr          => reset
           );




  forward_pressure_asyn : process(load, input_fifo_full, input_fifo_empty, output_fifo_almost_full)
  begin

      -- buffer input data into the fifo
      if input_fifo_full = '0' and output_fifo_almost_full = '0' then
        input_fifo_wrreq <= load;
      else
        input_fifo_wrreq <= '0';
      end if;

      -- read input data from fifo
      if input_fifo_empty = '0' then
        input_fifo_rdreq <= '1';
      else
        input_fifo_rdreq <= '0';
      end if;

      -- stop source from sending more data
      if input_fifo_full = '0' and output_fifo_almost_full = '0' then
        ready <= '1';
      else
        ready <= '0';
      end if;

  end process;

  forward_pressure_data : process(data_in, sop_in, eop_in, input_fifo_empty, input_fifo_rdreq, input_fifo_q)
  begin
    -- node that connects input data
    -- 1. left of the input fifo
    input_fifo_data(parallel_bits-1 downto 0) <= data_in;
    input_fifo_data(parallel_bits+1)          <= sop_in;
    input_fifo_data(parallel_bits)            <= eop_in;

    -- 2. right of the input fifo
    if input_fifo_empty = '0' then
      dec_load        <= input_fifo_rdreq;
      dec_data_in     <= input_fifo_q(parallel_bits-1 downto 0);
      dec_sop_in      <= input_fifo_q(parallel_bits+1);
      dec_eop_in      <= input_fifo_q(parallel_bits);
    else
      dec_load        <= '0';
      dec_data_in     <= (others=>'0');
      dec_sop_in      <= '0';
      dec_eop_in      <= '0';
    end if;
  end process;

  
  



  back_pressure_asyn : process (dec_data_out, output_fifo_full, dec_valid_out, sink_ready, output_fifo_empty)
  begin

        -- buffer output data into the fifo
        if dec_valid_out = '1' and output_fifo_full = '0' then
          output_fifo_wrreq <= '1';
        else
          output_fifo_wrreq <= '0';
        end if;

        -- read output data from fifo
        if sink_ready = '1' and output_fifo_empty = '0' then
          output_fifo_rdreq <= '1';
        else
          output_fifo_rdreq <= '0';
        end if;

  end process;

  back_pressure_data : process(dec_data_out, dec_num_errors_out, dec_sop_out, dec_eop_out, output_fifo_empty, output_fifo_rdreq, output_fifo_q)
  begin
    -- node that connects output data
    -- 1. left of the output fifo
    output_fifo_data(parallel_bits+7 downto 8) <= dec_data_out;
    output_fifo_data(7 downto 0)               <= dec_num_errors_out;
    output_fifo_data(parallel_bits+7+2)        <= dec_sop_out;
    output_fifo_data(parallel_bits+7+1)        <= dec_eop_out;

    -- 2. right of the output fifo
    if output_fifo_empty = '0' then
      valid_out     <= output_fifo_rdreq;
      data_out      <= output_fifo_q(parallel_bits+7 downto 8);
      sop_out       <= output_fifo_q(parallel_bits+7+2);
      eop_out       <= output_fifo_q(parallel_bits+7+1);
      number_errors <= output_fifo_q(7 downto 0);
    else
      valid_out     <= '0';
      data_out      <= (others=>'0');
      sop_out       <= '0';
      eop_out       <= '0';
      number_errors <= (others=>'0');
    end if;

  end process;
  



end architecture;



