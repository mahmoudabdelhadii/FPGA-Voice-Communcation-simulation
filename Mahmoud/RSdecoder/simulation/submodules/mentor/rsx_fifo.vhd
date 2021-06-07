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

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;
LIBRARY altera_lnsim;
USE altera_lnsim.altera_lnsim_components.all;
USE work.rsx_functions.all;
USE work.rsx_package.all;
USE work.rsx_parameters.all;

--***************************************************
--***                                             ***
--***   REED SOLOMON CORE LIBRARY                 ***
--***                                             ***
--***   RSP_DEL.VHD                               ***
--***                                             ***
--***   Function: Multiple Clock Bus Delay        ***
--***                                             ***
--***   31/01/08 ML                               ***
--***                                             ***
--***   (c) 2008 Altera Corporation               ***
--***                                             ***
--***   Change History                            ***
--***                                             ***
--***                                             ***
--***                                             ***
--***                                             ***
--***                                             ***
--***************************************************

ENTITY rsx_fifo IS 
GENERIC (
         width : positive := 64;
         depth : positive := 1
        );
PORT (
      clk : IN STD_LOGIC;
      reset : IN STD_LOGIC;
      enable : IN STD_LOGIC;
      ready_to_input : OUT STD_LOGIC;
      sop_in : IN STD_LOGIC := '0';
      eop_in : IN STD_LOGIC := '0';
      valid_in : IN STD_LOGIC;
      read_cc : IN STD_LOGIC;
      bypass : IN STD_LOGIC;
      valid_to_syndrome : OUT STD_LOGIC;
      valid_out : OUT STD_LOGIC;
      sop_out : OUT STD_LOGIC;
      eop_out : OUT STD_LOGIC;
      cancel_syndrome : OUT STD_LOGIC;
      aa : IN STD_LOGIC_VECTOR (width DOWNTO 1); 
      cc : OUT STD_LOGIC_VECTOR (width DOWNTO 1)
     );
END rsx_fifo ;


ARCHITECTURE rtl OF rsx_fifo  IS

  
  constant  fifo_nb_element : positive := 2**clog2(depth+10);
  constant  fifo_nb_element_buffer : positive := 5;
  constant  fifo_nb_element_w : positive := clog2(fifo_nb_element);

  
  
  signal is_almost_empty, is_almost_full : STD_LOGIC;
  signal is_empty, is_not_empty : STD_LOGIC;
  signal read_fifo, write_to_fifo : STD_LOGIC;
  signal data_in_fifo : STD_LOGIC_VECTOR (width DOWNTO 1);
  signal read,read_pb, read_pb0 : STD_LOGIC;
  signal valid_pb, valid_pb_test : STD_LOGIC_VECTOR (fifo_nb_element_buffer-1 DOWNTO 1);
  signal valid_output : STD_LOGIC;
  signal bypass_this_codeword : STD_LOGIC;
  signal this_codeword_is_bypassed, next_codeword_is_not_bypassed : STD_LOGIC;
  signal this_codeword_is_bypassed_out : STD_LOGIC;
  signal cancel_syndromeff : STD_LOGIC_VECTOR (4+channel DOWNTO 1);
  
  signal countinff, countoutff : STD_LOGIC_VECTOR (syndcnt_width DOWNTO 1);
  signal track_counter_diff : STD_LOGIC_VECTOR (fifo_nb_element_buffer DOWNTO 1);
  signal track_counter_plusone : STD_LOGIC;
  signal incr_counter_in, incr_counter_out : STD_LOGIC;
  signal last_input_symbol, first_input_symbol : STD_LOGIC;
  signal last_output_symbol, first_output_symbol : STD_LOGIC;
  signal one_before_last_output_symbol : STD_LOGIC;
  signal ready_pb : STD_LOGIC;
  
    component scfifo IS
    GENERIC (
    lpm_width: natural;
    add_ram_output_register: string := "OFF";
    allow_rwcycle_when_full: string := "OFF";
    almost_empty_value: natural := 0;
    almost_full_value: natural := 0;
    intended_device_family: string := "unused";
    lpm_numwords: natural;
    lpm_showahead: string := "OFF";
    lpm_widthu: natural := 1;
    overflow_checking: string := "ON";
    underflow_checking: string := "ON";
    use_eab: string := "ON";
    lpm_hint: string := "UNUSED";
    lpm_type: string := "scfifo"
    );
    PORT(
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
    
    
    
BEGIN


  ready_no_bypass : IF (use_bypass=0) GENERATE
    ready_to_input <= enable;
    read <= read_cc;
    ready_pb <= '1';
    cancel_syndrome <= '0';
    valid_to_syndrome <= valid_in;
    sop_out <= '0';
    eop_out <= '0';
    valid_out <= '0';
    
  END GENERATE;
  
  ready_bypass : IF (use_bypass=1) GENERATE
  
      prc_main: PROCESS (clk,reset)
      BEGIN
        IF (reset = '1') THEN
            countinff <= conv_std_logic_vector (0,syndcnt_width);
            countoutff <= conv_std_logic_vector (0,syndcnt_width);
            track_counter_diff <= conv_std_logic_vector (1,fifo_nb_element_buffer);
            track_counter_plusone <= '0';
        ELSIF (rising_edge(clk)) THEN
          IF (enable = '1') THEN
            IF (ready_pb = '1'  AND valid_in = '1') THEN
              IF (last_input_symbol ='1') THEN
                countinff <= conv_std_logic_vector (0,syndcnt_width);
              ELSE
                countinff <= countinff + 1;
              END IF;
            END IF;
          
            IF (valid_output = '1') THEN
              IF (last_output_symbol ='1') THEN
                countoutff <= conv_std_logic_vector (0,syndcnt_width);
              ELSE
                countoutff <= countoutff + 1;
              END IF;
            END IF;
          
            IF (ready_pb ='0' AND is_almost_empty = '1') THEN
              track_counter_diff <= conv_std_logic_vector (2,fifo_nb_element_buffer);
            ELSE
              IF (ready_pb = '1' AND valid_in = '1') THEN
                IF (valid_output = '0') THEN -- +1
                  track_counter_diff(1) <= '0';
                  FOR k IN 1 TO fifo_nb_element_buffer-1 LOOP
                    track_counter_diff(k+1) <= track_counter_diff(k);
                  END LOOP;
                END IF;
                IF (last_input_symbol ='1') THEN
                  track_counter_plusone <= '1';
                END IF;
              ELSIF (valid_output = '1') THEN
                IF (ready_pb = '0' OR valid_in = '0') THEN -- -1
                  track_counter_diff(fifo_nb_element_buffer) <= '0';
                  FOR k IN 2 TO fifo_nb_element_buffer LOOP
                    track_counter_diff(k-1) <= track_counter_diff(k);
                  END LOOP;
                END IF;
                IF (last_output_symbol ='1') THEN
                  track_counter_plusone <= '0';
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
      END PROCESS;
      incr_counter_in <= this_codeword_is_bypassed AND ready_pb AND valid_in;
      incr_counter_out <= this_codeword_is_bypassed AND valid_output;

      
      
      
      prc_last_symbol_in: PROCESS (countinff,valid_in)
      BEGIN
        FOR k IN 1 TO check_symbols LOOP 
          IF (countinff = codeword_clocks-1) THEN
            last_input_symbol <= valid_in;
          ELSE
            last_input_symbol <= '0';
          END IF;
          IF (countinff = 0) THEN
            first_input_symbol <= valid_in;
          ELSE
            first_input_symbol <= '0';
          END IF;
        END LOOP;
      END PROCESS;
      
      prc_last_symbol_out: PROCESS (countoutff,valid_output)
      BEGIN
        FOR k IN 1 TO check_symbols LOOP 
          IF (countoutff = codeword_clocks-1) THEN
            last_output_symbol <= valid_output;
          ELSE
            last_output_symbol <= '0';
          END IF;
          IF (countoutff = codeword_clocks-2) THEN
            one_before_last_output_symbol <= valid_output;
          ELSE
            one_before_last_output_symbol <= '0';
          END IF;
          IF (countoutff = 0) THEN
            first_output_symbol <= valid_output;
          ELSE
            first_output_symbol <= '0';
          END IF;
        END LOOP;
      END PROCESS;
  
  
  
    sop_out <= first_output_symbol;
    eop_out <= last_output_symbol;
  
    prc: PROCESS (clk,reset)
    BEGIN
      IF (reset = '1') THEN
        ready_pb <= '1';
      ELSIF (rising_edge(clk)) THEN
        IF (enable = '1') THEN
          IF (bypass = '1' AND first_input_symbol ='1' AND is_almost_empty = '0') THEN
            ready_pb <= '0';
          ELSIF (ready_pb ='0' AND is_almost_empty = '1') THEN
            ready_pb <= '1';
          END IF;
        END IF;
      END IF;
    END PROCESS;
    ready_to_input <= ready_pb AND enable;

    read <= read_pb OR read_cc;
    
    prc_valid_pb: PROCESS (clk,reset)
    BEGIN
      IF (reset = '1') THEN
        valid_pb <= conv_std_logic_vector (0,fifo_nb_element_buffer-1);
        valid_pb_test <= conv_std_logic_vector (0,fifo_nb_element_buffer-1);
        is_not_empty <= '1';
      ELSIF (rising_edge(clk)) THEN
        IF (enable = '1') THEN

          IF (one_before_last_output_symbol ='1' AND next_codeword_is_not_bypassed = '1' ) THEN
            valid_pb_test <= conv_std_logic_vector (1,fifo_nb_element_buffer-1);
          ELSE
              IF (ready_pb ='1' AND bypass_this_codeword = '1') THEN
                valid_pb_test(fifo_nb_element_buffer-2) <= '1';
              ELSIF (ready_pb ='1' AND bypass_this_codeword = '0') THEN
                valid_pb_test(fifo_nb_element_buffer-2) <= '0';
              END IF;
              FOR k IN 2 TO fifo_nb_element_buffer-2 LOOP
                valid_pb_test(k-1) <= valid_pb_test(k);
              END LOOP;
          END IF;
          
            IF (ready_pb ='1' AND bypass_this_codeword = '1') THEN
              valid_pb(2) <= '1';
            ELSIF (one_before_last_output_symbol ='1' AND next_codeword_is_not_bypassed = '1' ) THEN
              valid_pb(2) <= '0';
            END IF;
            valid_pb(1) <= read_pb;  
  
        END IF;
        is_not_empty <= NOT(is_empty);
      END IF;
    END PROCESS;
    
      
      prc_read_pb: PROCESS (incr_counter_in,track_counter_diff)
      BEGIN
        read_pb0 <= '0';
        IF(track_counter_diff(5 downto 4) /= "00" AND incr_counter_in = '1' ) THEN
          read_pb0 <= '1';
        ELSIF (this_codeword_is_bypassed = '0' AND this_codeword_is_bypassed_out ='1') THEN
          read_pb0 <= '1';
        ELSIF (incr_counter_in = '0') THEN
          read_pb0 <= '0';
        END IF;
      END PROCESS;
    
     read_pb <= (valid_pb(2) AND read_pb0);
    
    valid_output <= valid_pb(1) AND is_not_empty;
    valid_out <= valid_output;
    
    prc_cancelsyndrome: PROCESS (clk,reset)
    BEGIN
      IF (reset = '1') THEN
        bypass_this_codeword <= '0';
        cancel_syndromeff <= conv_std_logic_vector (0,4+channel);
      ELSIF (rising_edge(clk)) THEN
        IF (enable = '1') THEN
          IF (first_input_symbol ='1') THEN
            bypass_this_codeword <= bypass;
          ELSIF (last_input_symbol = '1') THEN
            bypass_this_codeword <= '0';
          END IF;
        
          IF (last_input_symbol = '1' AND bypass_this_codeword = '1') THEN
            cancel_syndromeff <= (4+channel downto 5 => '1', others => '0');
          ELSE
            cancel_syndromeff(4+channel) <= '0';
            IF (channel>1) THEN
              FOR k IN 5+1 TO 4+channel LOOP
                cancel_syndromeff(k-1) <= cancel_syndromeff(k);
              END LOOP;
            END IF;
            FOR k IN 2 TO 4+channel LOOP
              cancel_syndromeff(k-1) <= cancel_syndromeff(k);
            END LOOP;            
          END IF;

        END IF;
      END IF;
    END PROCESS;
    cancel_syndrome <=cancel_syndromeff(1);
    
    valid_to_syndrome <= valid_in AND ready_pb;
    
    next_codeword_is_not_bypassed <= (first_input_symbol AND NOT(bypass)) OR NOT(bypass_this_codeword);
    this_codeword_is_bypassed <= (first_input_symbol AND bypass) OR  (bypass_this_codeword AND NOT(first_input_symbol AND NOT(bypass)));
    
    prc_this_codeword_is_bypassed: PROCESS (clk,reset)
    BEGIN
      IF (reset = '1') THEN
        this_codeword_is_bypassed_out <= '0';
      ELSIF (rising_edge(clk)) THEN
        IF (enable = '1') THEN
          IF (first_output_symbol ='1' AND this_codeword_is_bypassed ='1') THEN
            this_codeword_is_bypassed_out <= '1';
          ELSIF (last_output_symbol ='1' AND this_codeword_is_bypassed ='0') THEN 
            this_codeword_is_bypassed_out <= '0';
          END IF;
        END IF;
      END IF;
    END PROCESS;
    
  END GENERATE;




  -- map component input with FIFO input
  write_to_fifo <= valid_in AND ready_pb AND enable;   
  read_fifo     <= read AND enable;  
  data_in_fifo  <= aa;
  
  delay_fifo: scfifo
  GENERIC MAP(
    lpm_width => width,  --data and valid
    almost_empty_value => fifo_nb_element_buffer,
    almost_full_value => fifo_nb_element-fifo_nb_element_buffer,
    lpm_numwords => fifo_nb_element,
    lpm_showahead => "OFF",
    lpm_widthu => fifo_nb_element_w,
    overflow_checking =>  "ON",
    underflow_checking => "ON",
    use_eab => "ON",
    lpm_type => "scfifo",
    intended_device_family => device_family
    ) PORT MAP(
    clock => clk,
    sclr => reset,
    --aclr => ,
    almost_empty => is_almost_empty,
    -- almost_full => is_almost_full,
    data => data_in_fifo,
    empty => is_empty,
    --full => ,
    q => cc,
    rdreq => read_fifo,
    --usedw => ,
    wrreq => write_to_fifo
  );
  
  
  
    
END rtl;

