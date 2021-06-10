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

entity BCH_204_128_10_dec_bch_0 is
    port (
          clk       : in  std_logic;
          reset     : in  std_logic;
          data_in   : in  std_logic_vector(8-1 DOWNTO 0);
          load      : in  std_logic;
          sop_in    : in  std_logic;
          eop_in    : in  std_logic;
          sink_ready: in  std_logic;

          ready     : out std_logic;
          data_out  : out std_logic_vector(8-1 DOWNTO 0);
          number_errors : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
          valid_out : out std_logic;
          sop_out   : out std_logic;
          eop_out   : out std_logic
         );
end entity BCH_204_128_10_dec_bch_0;

architecture rtl of BCH_204_128_10_dec_bch_0 is

    component  bchp_decoder 
        port (
              clk       : in  std_logic;
              reset     : in  std_logic;
              data_in   : in  std_logic_vector(8-1 DOWNTO 0);
              load      : in  std_logic;
              sop_in    : in  std_logic;
              eop_in    : in  std_logic;
              sink_ready: in  std_logic;

              ready     : out std_logic;
              data_out  : out std_logic_vector(8-1 DOWNTO 0);
              number_errors : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
              valid_out : out std_logic;
              sop_out   : out std_logic;
              eop_out   : out std_logic
             );
    end component bchp_decoder;

begin

    bchp_decoder_inst : component bchp_decoder
        port map (
                  clk           => clk,
                  reset         => reset,
                  data_in       => data_in,
                  load          => load,
                  sop_in        => sop_in,
                  eop_in        => eop_in,
                  sink_ready    => sink_ready,

                  ready         => ready,
                  data_out      => data_out,
                  number_errors => number_errors,
                  valid_out     => valid_out,
                  sop_out       => sop_out,
                  eop_out       => eop_out
                 );

end architecture rtl; -- of BCH_204_128_10_dec_bch_0


