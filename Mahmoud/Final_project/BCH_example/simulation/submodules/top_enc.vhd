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


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity BCH_example_bch_0 is
    port (
          clk       : in  std_logic;
          reset     : in  std_logic;
          data_in   : in  std_logic_vector(1-1 downto 0);
          load      : in  std_logic;
          sop_in    : in  std_logic;
          eop_in    : in  std_logic;
          sink_ready: in  std_logic;

          ready     : out std_logic;
          data_out  : out std_logic_vector(1-1 downto 0);
          valid_out : out std_logic;
          sop_out   : out std_logic;
          eop_out   : out std_logic
         );
end entity BCH_example_bch_0;

architecture rtl of BCH_example_bch_0 is

    component  bch_encoder 
        port (
             clk       : in  std_logic;
             reset     : in  std_logic;
             data_in   : in  std_logic_vector(1-1 downto 0);
             load      : in  std_logic;
             sop_in    : in  std_logic;
             eop_in    : in  std_logic;
             sink_ready: in  std_logic;

             ready     : out std_logic;
             data_out  : out std_logic_vector(1-1 downto 0);
             valid_out : out std_logic;
             sop_out   : out std_logic;
             eop_out   : out std_logic
             );
    end component bch_encoder;

begin

    bch_encoder_inst : component bch_encoder
        port map (
            clk       => clk,
            reset     => reset,
            data_in   => data_in,
            load      => load,
            sop_in    => sop_in,
            eop_in    => eop_in,
            sink_ready=> sink_ready,

            ready     => ready,
            valid_out => valid_out,
            data_out  => data_out,
            sop_out   => sop_out,
            eop_out   => eop_out
            );

end architecture rtl; -- of BCH_example_bch_0

