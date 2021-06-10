library ieee;
use ieee.std_logic_1164.all;

package bch_enc_package is

constant CODE_LENGTH_N    : natural := 204;
constant MESSAGE_LENGTH_K : natural := 128;
constant PARITY_LENGTH    : natural := 76;
constant DATA_WIDTH       : natural := 8;

constant POLY_COEF : std_logic_vector(PARITY_LENGTH downto 0) := "10010110010100111001000111001111011100000100011010100001110011000000100101101";
type lfsr_coef_type is array (0 to DATA_WIDTH, PARITY_LENGTH downto 1) of std_logic;
type lfsr_input_coef_type is array (0 to DATA_WIDTH, DATA_WIDTH - 1 downto 0) of std_logic;

constant LFSR_COEF : lfsr_coef_type := (
                                        "1011010010000001100111000010101100010000011101111001110001001110010100110100",
                                        "0101101001000000110011100001010110001000001110111100111000100111001010011010",
                                        "0010110100100000011001110000101011000100000111011110011100010011100101001101",
                                        "1010001000010001101011111010111001110010011110010110111111000111100110010010",
                                        "0101000100001000110101111101011100111001001111001011011111100011110011001001",
                                        "1001110000000101111101111100000010001100111010011100011110111111101101010000",
                                        "0100111000000010111110111110000001000110011101001110001111011111110110101000",
                                        "0010011100000001011111011111000000100011001110100111000111101111111011010100",
                                        "0010011100000001011111011111000000100011001110100111000111101111111011010100");

constant LFSR_INPUT_COEF : lfsr_input_coef_type := (
                                        "00000000",
                                        "00000000",
                                        "00000000",
                                        "00000001",
                                        "00000010",
                                        "00000101",
                                        "00001010",
                                        "00010100",
                                        "00010100");

constant LFSR_OUTPUT_COEF : lfsr_input_coef_type := (
                                        "00000000",
                                        "00000000",
                                        "00000000",
                                        "00000001",
                                        "00000010",
                                        "00000101",
                                        "00001011",
                                        "00010110",
                                        "00010110");

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
