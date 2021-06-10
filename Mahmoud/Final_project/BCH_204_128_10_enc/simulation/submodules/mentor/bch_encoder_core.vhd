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

entity bch_encoder_core is
  port (
    clk       : in  std_logic;
    reset     : in  std_logic;
    data_in   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    load      : in  std_logic;

    ready     : out std_logic;
    data_out  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    valid_out : out std_logic;
    sop_out   : out std_logic
    );
end entity;

architecture arch of bch_encoder_core is

  constant NUM_PIPELINE_REGS   : natural := 2;  -- Must be >=2
  constant NUM_CORRECTION_REGS : natural := 2;  -- Must be >=0

  constant MOD_REMAINDER : natural := MESSAGE_LENGTH_K mod DATA_WIDTH;

  constant MESSAGE_CLOCKS : natural := natural(ceil(real(MESSAGE_LENGTH_K)/real(DATA_WIDTH)));
  constant CODEWORD_CLOCKS : natural := natural(ceil(real(CODE_LENGTH_N)/real(DATA_WIDTH)));

  -- Status Signals
  signal valid_out_shift_reg : std_logic_vector(NUM_PIPELINE_REGS+NUM_CORRECTION_REGS downto 0)   := (others => '0');
  signal valid_out_s         : std_logic                                                          := '0';
  signal sop_out_shift_reg   : std_logic_vector(NUM_PIPELINE_REGS+NUM_CORRECTION_REGS+1 downto 0) := (others => '0');
  signal sop_out_s           : std_logic                                                          := '0';
  signal ready_s             : std_logic                                                          := '0';

  -- Control Signals
  signal data_in_ena           : std_logic;
  signal data_in_ena_shift_reg : std_logic_vector(NUM_PIPELINE_REGS+1 downto 1) := (others => '0');

  -- LFSR Signals
  signal data_in_q      : std_logic_vector(DATA_WIDTH-1 downto 0)   := (others => '0');
  signal output_reg_int : std_logic_vector(DATA_WIDTH-1 downto 0)   := (others => '0');
  signal u_reg          : std_logic_vector(PARITY_LENGTH downto 1)  := (others => '0');
  signal y_reg          : std_logic_vector(PARITY_LENGTH downto 1)  := (others => '0');
  signal u_out_s        : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  signal y_out_s        : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  signal lfsr_out_s     : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

  type   u_pipeline_regs_type is array (NUM_PIPELINE_REGS downto 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal u_pipeline_reg : u_pipeline_regs_type := (others => (others => '0'));

  type   data_in_shift_reg_type is array (NUM_PIPELINE_REGS downto 0) of std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal data_in_shift_reg : data_in_shift_reg_type := (others => (others => '0'));

  type   correction_regs_type is array (NUM_CORRECTION_REGS downto 0) of std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal output_reg : correction_regs_type := (others => (others => '0'));

  type   state_type is (st1_idle, st2_receive, st3_switch, st4_parity);
  signal state : state_type := st1_idle;

  signal count : natural range 0 to natural(ceil(real(CODE_LENGTH_N)/real(DATA_WIDTH))) + 1 := 0;


  signal enable : std_logic; -- the enable signal is used to deal with transmission gap

  
begin

  en_proc : process(state, load)
  begin
      -- enable signal holds the design if 
      if (state = st2_receive or state = st3_switch) and load = '0' then
        enable <= '0';
      else
        enable <= '1';
      end if;
  end process;

  data_out  <= output_reg(NUM_CORRECTION_REGS);
  valid_out <= valid_out_shift_reg(NUM_PIPELINE_REGS+NUM_CORRECTION_REGS) and enable;
  sop_out   <= sop_out_shift_reg(NUM_PIPELINE_REGS+NUM_CORRECTION_REGS+1);
  ready     <= ready_s;

  INPUT_SHIFT_REGS : process(clk,enable)
  begin
    if rising_edge(clk) and enable = '1' then
      data_in_shift_reg <= data_in_shift_reg(NUM_PIPELINE_REGS-1 downto 0) & data_in_q;
    end if;
  end process;

  OUTPUT_REGS : process(clk,enable)
  begin
    if rising_edge(clk) and enable = '1' then
      if (load and ready_s) = '1' then
        data_in_q <= data_in;
      else
        data_in_q <= (others => '0');
      end if;
    end if;
  end process;

  -- build feed-forward component of LFSR
  IIR_LFSR_U : process(u_reg, data_in_q)
    variable u_out_temp : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  begin
    u_out_temp := (others => '0');
    for k in 0 to DATA_WIDTH - 1 loop
      for i in 1 to PARITY_LENGTH loop
        if LFSR_COEF(k, i) = '1' then
          u_out_temp(k) := u_out_temp(k) xor u_reg(i);
        end if;
      end loop;
    end loop;
    for k in 0 to DATA_WIDTH - 1 loop
      for i in 0 to DATA_WIDTH - 1 loop
        if LFSR_INPUT_COEF(k, i) = '1' then
          u_out_temp(k) := u_out_temp(k) xor data_in_q(i);
        end if;
      end loop;
    end loop;
    u_out_s <= u_out_temp;
  end process;

  --build feed-back component of LFSR
  IIR_LFSR_Y : process(y_reg)
    variable y_out_temp : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  begin
    y_out_temp := (others => '0');
    for k in 0 to DATA_WIDTH - 1 loop
      for i in 1 to PARITY_LENGTH loop
        if LFSR_COEF(k, i) = '1' then
          y_out_temp(k) := y_out_temp(k) xor y_reg(i);
        end if;
      end loop;
    end loop;
    y_out_s <= y_out_temp;
  end process;

  -- add pipeline registers to feed-forward component of LFSR
  --GEN_PIPELINE_REGS : if NUM_PIPELINE_REGS > 0 generate
  PIPELINE_REGS : process(clk,enable)
  begin
    if rising_edge(clk) and enable = '1' then
      for i in 0 to NUM_PIPELINE_REGS-1 loop  -- - 1 loop
        if i = 0 then
          u_pipeline_reg(1) <= u_out_s;
        else
          u_pipeline_reg(i+1) <= u_pipeline_reg(i);
        end if;
      end loop;
    end if;
  end process;
  --end generate;

  PIPELINE_REGS_DATA_IN_ENA : process(clk,enable)
  begin
    if rising_edge(clk) and enable = '1' then
      for i in 0 to NUM_PIPELINE_REGS loop
        if i = 0 then
          data_in_ena_shift_reg(1) <= data_in_ena;
        else
          data_in_ena_shift_reg(i+1) <= data_in_ena_shift_reg(i);
        end if;
      end loop;
    end if;
  end process;

  VALID_OUT_REGS : process(clk,enable)
  begin
    if rising_edge(clk) and enable = '1' then
      valid_out_shift_reg <= valid_out_shift_reg(NUM_PIPELINE_REGS+NUM_CORRECTION_REGS - 1 downto 0) & valid_out_s;
      sop_out_shift_reg   <= sop_out_shift_reg(NUM_PIPELINE_REGS+NUM_CORRECTION_REGS downto 0) & sop_out_s;
    end if;
  end process;

  lfsr_out_s <= y_out_s xor u_pipeline_reg(NUM_PIPELINE_REGS);

  -- Input delay chain for IIR filter
  U_SHIFT_REG : process(clk,enable)
  begin
    if rising_edge(clk) and enable = '1' then
      for i in 0 to DATA_WIDTH - 1 loop
        u_reg(i+1) <= data_in_q(DATA_WIDTH - 1 - i);
      end loop;
      for i in 1 to PARITY_LENGTH - DATA_WIDTH loop
        u_reg(i+DATA_WIDTH) <= u_reg(i);
      end loop;
    end if;
  end process;

  -- Output feedback delay chain for IIR filter
  Y_SHIFT_REG : process(clk,enable)
    variable data_out_temp : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  begin
    if rising_edge(clk) and enable = '1' then
      data_out_temp := lfsr_out_s;
      for i in 1 to PARITY_LENGTH - DATA_WIDTH loop
        y_reg(i+DATA_WIDTH) <= y_reg(i);
      end loop;
      for i in 0 to DATA_WIDTH - 1 loop
        if data_in_ena_shift_reg(NUM_PIPELINE_REGS-1) = '0' and data_in_ena_shift_reg(NUM_PIPELINE_REGS) = '1' then
          if i < MOD_REMAINDER or MOD_REMAINDER = 0 then
            y_reg(DATA_WIDTH - i) <= data_out_temp(i);
          else
            y_reg(DATA_WIDTH - i) <= '0';
          end if;
        elsif data_in_ena_shift_reg(NUM_PIPELINE_REGS) = '1' then
          y_reg(DATA_WIDTH - i) <= data_out_temp(i);
        else
          y_reg(i+1) <= '0';
        end if;
      end loop;
      output_reg_int <= data_out_temp;
    end if;
  end process;

  -- Feed-forward correction stage after IIR circuit which is enabled when shifting out the remainder.
  OUTPUT_CORRECTION : process(clk, enable)
    variable data_out_temp : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
  begin
    if rising_edge(clk) and enable = '1' then
      data_out_temp := output_reg_int;
      for k in 0 to DATA_WIDTH - 1 loop
        for i in 0 to DATA_WIDTH - 1 loop
          if LFSR_OUTPUT_COEF(k, i) = '1' then
            if data_in_ena_shift_reg(NUM_PIPELINE_REGS) = '0' and data_in_ena_shift_reg(NUM_PIPELINE_REGS+1) = '1' then
              if k >= MOD_REMAINDER and i >= MOD_REMAINDER then
                data_out_temp(k) := data_out_temp(k) xor output_reg_int(i);
              end if;
            elsif data_in_ena_shift_reg(NUM_PIPELINE_REGS+1) = '0' then
              data_out_temp(k) := data_out_temp(k) xor output_reg_int(i);
            end if;
          end if;
        end loop;
      end loop;
      for i in 0 to NUM_CORRECTION_REGS loop
        if i = 0 then
          if data_in_ena_shift_reg(NUM_PIPELINE_REGS) = '0' and data_in_ena_shift_reg(NUM_PIPELINE_REGS+1) = '1' and MOD_REMAINDER /= 0 then
            output_reg(0)(DATA_WIDTH-1 downto MOD_REMAINDER) <= data_out_temp(DATA_WIDTH-1 downto MOD_REMAINDER);
            output_reg(0)(MOD_REMAINDER - 1 downto 0)        <= data_in_shift_reg(NUM_PIPELINE_REGS)(MOD_REMAINDER - 1 downto 0);
          elsif data_in_ena_shift_reg(NUM_PIPELINE_REGS+1) = '1' then
            output_reg(0) <= data_in_shift_reg(NUM_PIPELINE_REGS);
          else
            output_reg(0) <= data_out_temp(DATA_WIDTH - 1 downto 0);
          end if;
        else
          output_reg(i) <= output_reg(i-1);
        end if;
      end loop;
    end if;
  end process;

  SM : process (clk)
  begin
    
    if rising_edge(clk) then

      if reset = '1' then
      state       <= st1_idle;
      ready_s     <= '0';
      data_in_ena <= '0';
      valid_out_s <= '0';
      count       <= 0;
      sop_out_s   <= '0';

      elsif enable = '1' then

        state     <= state;
        sop_out_s <= '0';
        count     <= count + 1;
        case state is
          when st1_idle =>
            ready_s     <= '1';
            data_in_ena <= '0';
            valid_out_s <= '0';
            count       <= 0;
            if load = '1' then
              data_in_ena <= '1';
              sop_out_s   <= '1';
              state       <= st2_receive;
              if MESSAGE_CLOCKS = 2 then -- corner case when ceil(K/data_width)=2, go to state 3 directly
                state   <= st3_switch;
              end if;
            end if;
          when st2_receive =>
            ready_s     <= '1';
            data_in_ena <= '1';
            valid_out_s <= '1';
            if count = MESSAGE_CLOCKS - 3 then
              state   <= st3_switch;
            end if;
          when st3_switch =>
            ready_s     <= '0';
            data_in_ena <= '1';
            valid_out_s <= '1';
            state       <= st4_parity;
          when st4_parity =>
            ready_s     <= '0';
            data_in_ena <= '0';
            valid_out_s <= '1';
            if count = CODEWORD_CLOCKS - 1 then
              state   <= st1_idle;
              ready_s <= '1';
            end if;
          when others =>
            state <= st1_idle;
        end case;
  
      end if;
      
    end if;
  end process;

end architecture;
