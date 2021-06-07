
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_arith.all;


LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

USE work.rsx_parameters.all;

USE work.rsx_package.all;

ENTITY rsx_inverse_ROM IS
  GENERIC (
         nb_input : integer := 1
 );
  PORT (
         sysclk: IN STD_LOGIC;
         reset : IN STD_LOGIC;
         enable : IN STD_LOGIC;
         alpha : IN inv_alpha_type;
         read_enable : IN STD_LOGIC_VECTOR (nbinvmax DOWNTO 1);
         inverse_of_alpha : OUT inv_alpha_type := (others=>(others=>'0'))
        );
END rsx_inverse_ROM;

ARCHITECTURE rtl OF rsx_inverse_ROM IS

    signal inverse_of_alpha_from_ROM :inv_alpha_type := (others=>(others=>'0'));
    signal alpha_delay : inv_alpha_type;
    signal write_enable : STD_LOGIC_VECTOR (nbinvmax DOWNTO 1);
    signal address_a_node :inv_alpha_type;
    component rsx_fit_counter
    GENERIC (
          minus_one : positive := 1);
    PORT (
          sysclk, reset: IN STD_LOGIC;
          address, data : OUT STD_LOGIC_VECTOR (m_bits DOWNTO 1)
          );
      end component;

 BEGIN

    delay: FOR k IN 1 TO nb_input GENERATE
      delaying_address: PROCESS (alpha(k)) 
      BEGIN
        alpha_delay(k) <= alpha(k) after 1 ps;
      END PROCESS;
    END GENERATE;

    eccnode0: FOR k IN 1 TO nb_input GENERATE
      inverse_of_alpha(k) <= inverse_of_alpha_from_ROM(k);
    END GENERATE;

    more_than_one_core: IF (nb_input>1) GENERATE
    ramb: FOR k IN 1 TO nb_input/2 GENERATE
    RAM: altsyncram
    GENERIC MAP (
            operation_mode => "BIDIR_DUAL_PORT",
            numwords_a => 256,
            width_a => m_bits,
            widthad_a => m_bits,
            outdata_reg_a => "CLOCK0",
            numwords_b => 256,
            width_b => m_bits,
            widthad_b => m_bits,
            address_reg_b => "CLOCK0",
            indata_reg_b => "CLOCK0",   
            outdata_reg_b => "CLOCK0",   
            lpm_type  => "altsyncram", 
            power_up_uninitialized => "FALSE", 
            ram_block_type => "AUTO",
            init_file => "rsx_decoder_rom_inverse.hex",
            wrcontrol_wraddress_reg_b => "CLOCK0",
            init_file_layout => "PORT_A"
            ) PORT MAP ( 
            clock0 => sysclk,
            wren_a    => '0',
            address_a => alpha_delay(2*(k-1)+1),
            q_a       => inverse_of_alpha_from_ROM(2*(k-1)+1),
            wren_b    => '0',
            address_b => alpha_delay(2*(k-1)+2),
            q_b       => inverse_of_alpha_from_ROM(2*(k-1)+2)
        );

    END GENERATE;
    END GENERATE;
    ramEXTRA: IF ((nb_input mod 2) = 1) GENERATE
      RAM: altsyncram
    GENERIC MAP (
            operation_mode => "BIDIR_DUAL_PORT",
            numwords_a => 256,
            width_a => m_bits,
            widthad_a => m_bits,
            outdata_reg_a => "CLOCK0",
            numwords_b => 256,
            width_b => m_bits,
            widthad_b => m_bits,
            address_reg_b => "CLOCK0",
            indata_reg_b => "CLOCK0",
            outdata_reg_b => "CLOCK0",   
            lpm_type  => "altsyncram", 
            power_up_uninitialized => "FALSE", 
            ram_block_type => "AUTO",
            init_file => "rsx_decoder_rom_inverse.hex",
            wrcontrol_wraddress_reg_b => "CLOCK0",
            init_file_layout => "PORT_A"
            ) PORT MAP ( 
            clock0 => sysclk,
            wren_a    => '0',
            address_a => alpha_delay(nb_input),
            q_a       => inverse_of_alpha_from_ROM(nb_input),
            wren_b    => '0',
            address_b => (others => '0')
      );

    END GENERATE;
END rtl;


