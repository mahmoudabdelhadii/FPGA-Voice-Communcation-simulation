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
use work.bch_enc_package.all;

library altera_mf;


entity bch_encoder is
  port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    data_in   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    load      : in  std_logic;
    sop_in    : in  std_logic;
    eop_in    : in  std_logic;
    sink_ready: in  std_logic;

    ready     : out std_logic;
    data_out  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    valid_out : out std_logic;
    sop_out   : out std_logic;
    eop_out   : out std_logic
    );
end entity;



architecture arch of bch_encoder is

  component bch_encoder_core
    port     (
              clk       : in  std_logic;
              reset     : in  std_logic;
              data_in   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
              load      : in  std_logic;

              ready     : out std_logic;
              data_out  : out std_logic_vector(DATA_WIDTH-1 downto 0);
              valid_out : out std_logic;
              sop_out   : out std_logic
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


  signal enc_ready, enc_load, enc_valid_out : std_logic;
  signal enc_sop_in, enc_eop_in, enc_sop_out, enc_eop_out : std_logic;
  signal enc_data_in, enc_data_out : std_logic_vector (DATA_WIDTH-1 downto 0);
  constant MESSAGE_CLOCKS : natural := natural(ceil(real(MESSAGE_LENGTH_K)/real(DATA_WIDTH)));
  constant CODEWORD_CLOCKS : natural := natural(ceil(real(CODE_LENGTH_N)/real(DATA_WIDTH)));
  signal eop_counter : natural;

  -- connecting signals of the input FIFO
  constant input_lpm_numwords : positive := 1*MESSAGE_CLOCKS; -- input fifo must have length > 1; currently can store upto 1 complete message words
  constant input_lpm_widthu : positive := log2_function(input_lpm_numwords-1)+1; -- width of the usedw port
  signal input_fifo_rdreq, input_fifo_wrreq : STD_LOGIC;
  signal input_fifo_empty, input_fifo_full: STD_LOGIC;
  signal input_fifo_data, input_fifo_q : STD_LOGIC_VECTOR (DATA_WIDTH+1 downto 0);

  -- connecting signals of the output FIFO
  constant output_lpm_numwords : positive := 10 + 2*CODEWORD_CLOCKS; -- currently has free buffer size of 10, and a backup space of size of 2-codeword
  constant output_lpm_widthu : positive := log2_function(output_lpm_numwords-1)+1; -- width of the usedw port
  signal output_fifo_rdreq, output_fifo_wrreq : STD_LOGIC;
  signal output_fifo_empty, output_fifo_full: STD_LOGIC;
  signal output_fifo_data, output_fifo_q : STD_LOGIC_VECTOR (DATA_WIDTH+1 downto 0);
  signal output_fifo_almost_full : std_logic;
  constant output_almost_full_value : natural := 10; -- almost full signal raised at this value

begin

  bch_encoder_core_inst : bch_encoder_core
    port map (clk => clk,
              reset => reset,
              data_in => enc_data_in,
              load => enc_load,
              ready => enc_ready,
              data_out => enc_data_out,
              valid_out => enc_valid_out,
              sop_out => enc_sop_out);

  eop_proc : process (clk)
  begin
    if rising_edge(clk) then

      if reset = '1' then
        enc_eop_out <= '0';
        eop_counter <= 0;

      else

        -- endofpacket counter counting the number of outputs so far after the last startofpacket signal
        if enc_sop_out = '1' then
          eop_counter <= 1;
        elsif enc_valid_out = '1' then
          eop_counter <= eop_counter + 1;
        elsif eop_counter = CODEWORD_CLOCKS - 2 then
          eop_counter <= 0;
        end if;

        -- endofpacket signal output
        if eop_counter = CODEWORD_CLOCKS - 2 then
          enc_eop_out <= '1';
        else
          enc_eop_out <= '0';
        end if;
        
      end if;

    end if;
  end process;




  input_fifo : scfifo
  GENERIC MAP (
               lpm_numwords             => input_lpm_numwords,
               lpm_showahead            => "ON",
               lpm_width                => DATA_WIDTH+2,
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
            sclr          => reset,
            usedw         => open,
            wrreq         => input_fifo_wrreq
           );

  output_fifo : scfifo
  GENERIC MAP (
               almost_full_value        => output_almost_full_value,
               lpm_numwords             => output_lpm_numwords,
               lpm_showahead            => "ON",
               lpm_width                => DATA_WIDTH+2,
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
            sclr          => reset,
            usedw         => open,
            wrreq         => output_fifo_wrreq
           );




  forward_pressure_asyn : process(reset, load, input_fifo_full, enc_ready, input_fifo_empty, output_fifo_almost_full)
  begin
    if reset = '1' then
      input_fifo_wrreq <= '0';
      input_fifo_rdreq <= '0';
      ready <= '0';
    else

      -- buffer input data into the fifo
      if input_fifo_full = '0' and output_fifo_almost_full = '0' then
        input_fifo_wrreq <= load;
      else
        input_fifo_wrreq <= '0';
      end if;

      -- read input data from fifo
      if input_fifo_empty = '0' and enc_ready = '1' then
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

    end if;
  end process;

  -- node that connects input data
  -- 1. left of the input fifo
  input_fifo_data(DATA_WIDTH-1 downto 0) <= data_in;
  input_fifo_data(DATA_WIDTH+1)          <= sop_in;
  input_fifo_data(DATA_WIDTH)            <= eop_in;
  -- 2. right of the input fifo
  enc_load          <= input_fifo_rdreq;
  enc_data_in       <= input_fifo_q(DATA_WIDTH-1 downto 0);
  enc_sop_in        <= input_fifo_q(DATA_WIDTH+1);
  enc_eop_in        <= input_fifo_q(DATA_WIDTH);
  



  back_pressure_asyn : process (reset, output_fifo_full, enc_valid_out, sink_ready, output_fifo_empty)
  begin
      if reset = '1' then
        output_fifo_wrreq <= '0';
        output_fifo_rdreq <= '0';
      else

        -- buffer output data into the fifo
        if enc_valid_out = '1' and output_fifo_full = '0' then
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
        
      end if;
  end process;

  -- node that connects output data
  -- 1. left of the output fifo
  output_fifo_data(DATA_WIDTH-1 downto 0) <= enc_data_out;
  output_fifo_data(DATA_WIDTH+1)          <= enc_sop_out;
  output_fifo_data(DATA_WIDTH)            <= enc_eop_out;
  -- 2. right of the output fifo
  valid_out     <= output_fifo_rdreq;
  data_out      <= output_fifo_q(DATA_WIDTH-1 downto 0);
  sop_out       <= output_fifo_q(DATA_WIDTH+1);
  eop_out       <= output_fifo_q(DATA_WIDTH);



end architecture;



