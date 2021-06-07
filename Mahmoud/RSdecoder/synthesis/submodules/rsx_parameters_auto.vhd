
LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE rsx_parameters IS
         constant channel  : positive := 1;
         constant n_symbols : positive := 255;
         constant k_symbols : positive := 223;
         constant m_bits    : positive := 8;
         constant polynomial : positive := 285;
         constant parallel_symbols : positive := 10;
         constant polynomial_speed : integer := 1; -- 4,5, or 6
         constant nb_bm_core : integer := 2;
         constant use_bypass : integer := 0;
         constant device_family : string := "Cyclone V";
END rsx_parameters;

