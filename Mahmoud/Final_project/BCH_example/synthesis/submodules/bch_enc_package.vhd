library ieee;
use ieee.std_logic_1164.all;

package bch_enc_package is

constant CODE_LENGTH_N    : natural := 79;
constant MESSAGE_LENGTH_K : natural := 39;
constant PARITY_LENGTH    : natural := 40;
constant DATA_WIDTH       : natural := 1;

constant POLY_COEF : std_logic_vector(PARITY_LENGTH downto 0) := "10011001101111101110100111010110100010001";
type lfsr_coef_type is array (0 to DATA_WIDTH, PARITY_LENGTH downto 1) of std_logic;
type lfsr_input_coef_type is array (0 to DATA_WIDTH, DATA_WIDTH - 1 downto 0) of std_logic;

constant LFSR_COEF : lfsr_coef_type := (
                                        "1000100010110101110010111011111011001100",
                                        "1000100010110101110010111011111011001100");

constant LFSR_INPUT_COEF : lfsr_input_coef_type := (
                                        "0",
                                        "0");

constant LFSR_OUTPUT_COEF : lfsr_input_coef_type := (
                                        "0",
                                        "0");

FUNCTION log2_function (constant in_data : positive) return natural;

end bch_enc_package;

package body bch_enc_package is

  -- log2 function
  FUNCTION log2_function
  (constant in_data : positive)
  return natural IS
    variable temp    : integer := in_data;
    variable ret_val : integer := 0;
  begin 

    while temp > 1 loop
      ret_val := ret_val + 1;
      temp    := temp / 2;
    end loop;

    return ret_val;
  END log2_function;

end bch_enc_package;
