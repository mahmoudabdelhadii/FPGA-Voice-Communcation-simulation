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
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;


USE work.rsx_parameters.all;

ENTITY rsx_inverse_ROM_bkp IS
  PORT (
         sysclk: IN STD_LOGIC;
         reset: IN STD_LOGIC;
         enable: IN STD_LOGIC;
         
         in_data : IN STD_LOGIC_VECTOR (m_bits DOWNTO 1);
         out_data : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
        );
END rsx_inverse_ROM_bkp;

ARCHITECTURE rtl OF rsx_inverse_ROM_bkp IS

  type store_ram_type IS ARRAY (2 DOWNTO 1) OF STD_LOGIC_VECTOR (m_bits+1 DOWNTO 1);

  signal enableff : STD_LOGIC_VECTOR(2 DOWNTO 1);
  signal store_ram_output : store_ram_type;
  -- signal output_first_store_ram : STD_LOGIC;
  -- signal output_second_store_ram : STD_LOGIC;
  signal load_ram_output : STD_LOGIC;
  signal shift_store_ram : STD_LOGIC;
  signal zero_ram_output : STD_LOGIC;
  signal ram_mux_out_node : STD_LOGIC_VECTOR (m_bits DOWNTO 1);
  
BEGIN


    prc_store_RAM_output: PROCESS (sysclk,reset)
    BEGIN
        IF (reset = '1') THEN
            enableff <= "00";
            FOR k IN 1 TO 2 LOOP
                store_ram_output(k) <= conv_std_logic_vector (0,m_bits+1);
            END LOOP;
        ELSIF (rising_edge(sysclk)) THEN
            enableff(1) <= enable;
            enableff(2) <= enableff(1);
            
            IF (load_ram_output = '1') THEN
                store_ram_output(1) <= '1' & in_data;
            ELSIF (zero_ram_output = '1') THEN
                store_ram_output(1) <= conv_std_logic_vector (0,m_bits+1);
            END IF;
            
            IF (shift_store_ram = '1') THEN
                store_ram_output(2) <= store_ram_output(1);
            END IF;
            
        END IF;
    END PROCESS;  
    --output_first_store_ram <= enable AND (NOT(store_ram_output(2)(m_bits+1)) AND store_ram_output(1)(m_bits+1));
    --output_second_store_ram <= enable AND (store_ram_output(2)(m_bits+1));
    
    load_ram_output <= enableff(2)  AND ( NOT(enable) OR store_ram_output(2)(m_bits+1) OR store_ram_output(1)(m_bits+1) );
    
    shift_store_ram <=  (enable AND (store_ram_output(2)(m_bits+1))) OR (enableff(2)  AND NOT(enable) AND NOT(store_ram_output(2)(m_bits+1)));
    
    zero_ram_output <= enable AND NOT(enableff(2)) AND (store_ram_output(2)(m_bits+1) OR store_ram_output(1)(m_bits+1));

    ram_mux : PROCESS (store_ram_output,in_data ,enable)
    BEGIN
        IF ((enable AND store_ram_output(2)(m_bits+1)) = '1') THEN
            ram_mux_out_node <= store_ram_output(2)(m_bits DOWNTO 1);
        ELSE 
            IF ((enable AND store_ram_output(1)(m_bits+1)) = '1') THEN
                ram_mux_out_node <= store_ram_output(1)(m_bits DOWNTO 1);
            ELSE
                ram_mux_out_node <= in_data;
            END IF;
        END IF;
    END PROCESS;  
    out_data <= ram_mux_out_node;

END rtl;


