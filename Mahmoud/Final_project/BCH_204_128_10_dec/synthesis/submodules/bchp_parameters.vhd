LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE bchp_parameters IS

  constant n_symbols : positive := 204;
  constant k_symbols : positive := 128;
  constant t_symbols : positive := 10;
  constant m_bits : positive := 8;
  constant polynomial : positive := 285;
  constant parallel_bits : positive := 8;

  constant power_save : integer := 1; -- 0 search always on, 1 search selective

END bchp_parameters;

