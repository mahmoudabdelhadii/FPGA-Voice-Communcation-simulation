-- ------------------------------------------------------------------------- 
-- High Level Design Compiler for Intel(R) FPGAs Version 18.1 (Release Build #625)
-- Quartus Prime development tool and MATLAB/Simulink Interface
-- 
-- Legal Notice: Copyright 2018 Intel Corporation.  All rights reserved.
-- Your use of  Intel Corporation's design tools,  logic functions and other
-- software and  tools, and its AMPP partner logic functions, and any output
-- files any  of the foregoing (including  device programming  or simulation
-- files), and  any associated  documentation  or information  are expressly
-- subject  to the terms and  conditions of the  Intel FPGA Software License
-- Agreement, Intel MegaCore Function License Agreement, or other applicable
-- license agreement,  including,  without limitation,  that your use is for
-- the  sole  purpose of  programming  logic devices  manufactured by  Intel
-- and  sold by Intel  or its authorized  distributors. Please refer  to the
-- applicable agreement for further details.
-- ---------------------------------------------------------------------------

-- VHDL created from filter1_rtl_core
-- VHDL created on Thu Jun 10 01:49:05 2021


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;
use std.TextIO.all;
use work.dspba_library_package.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;
LIBRARY altera_lnsim;
USE altera_lnsim.altera_lnsim_components.altera_syncram;
LIBRARY lpm;
USE lpm.lpm_components.all;

entity filter1_rtl_core is
    port (
        xIn_v : in std_logic_vector(0 downto 0);  -- sfix1
        xIn_c : in std_logic_vector(7 downto 0);  -- sfix8
        xIn_0 : in std_logic_vector(7 downto 0);  -- sfix8
        xOut_v : out std_logic_vector(0 downto 0);  -- ufix1
        xOut_c : out std_logic_vector(7 downto 0);  -- ufix8
        xOut_0 : out std_logic_vector(21 downto 0);  -- sfix22
        clk : in std_logic;
        areset : in std_logic
    );
end filter1_rtl_core;

architecture normal of filter1_rtl_core is

    attribute altera_attribute : string;
    attribute altera_attribute of normal : architecture is "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF; -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION ON; -name MESSAGE_DISABLE 10036; -name MESSAGE_DISABLE 10037; -name MESSAGE_DISABLE 14130; -name MESSAGE_DISABLE 14320; -name MESSAGE_DISABLE 15400; -name MESSAGE_DISABLE 14130; -name MESSAGE_DISABLE 10036; -name MESSAGE_DISABLE 12020; -name MESSAGE_DISABLE 12030; -name MESSAGE_DISABLE 12010; -name MESSAGE_DISABLE 12110; -name MESSAGE_DISABLE 14320; -name MESSAGE_DISABLE 13410; -name MESSAGE_DISABLE 113007";
    
    signal GND_q : STD_LOGIC_VECTOR (0 downto 0);
    signal VCC_q : STD_LOGIC_VECTOR (0 downto 0);
    signal d_xIn_0_14_q : STD_LOGIC_VECTOR (7 downto 0);
    signal d_in0_m0_wi0_wo0_assign_id1_q_14_q : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_run_count : STD_LOGIC_VECTOR (1 downto 0);
    signal u0_m0_wo0_run_preEnaQ : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_run_q : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_run_out : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_run_enableQ : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_run_ctrl : STD_LOGIC_VECTOR (2 downto 0);
    signal u0_m0_wo0_memread_q : STD_LOGIC_VECTOR (0 downto 0);
    signal d_u0_m0_wo0_memread_q_13_q : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_compute_q : STD_LOGIC_VECTOR (0 downto 0);
    signal d_u0_m0_wo0_compute_q_16_q : STD_LOGIC_VECTOR (0 downto 0);
    signal d_u0_m0_wo0_compute_q_17_q : STD_LOGIC_VECTOR (0 downto 0);
    signal d_u0_m0_wo0_compute_q_18_q : STD_LOGIC_VECTOR (0 downto 0);
    signal d_u0_m0_wo0_compute_q_19_q : STD_LOGIC_VECTOR (0 downto 0);
    signal d_u0_m0_wo0_compute_q_20_q : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_count0_inner_q : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_count0_inner_i : SIGNED (5 downto 0);
    attribute preserve : boolean;
    attribute preserve of u0_m0_wo0_wi0_r0_ra0_count0_inner_i : signal is true;
    signal u0_m0_wo0_wi0_r0_ra0_count0_q : STD_LOGIC_VECTOR (6 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_count0_i : UNSIGNED (5 downto 0);
    attribute preserve of u0_m0_wo0_wi0_r0_ra0_count0_i : signal is true;
    signal u0_m0_wo0_wi0_r0_ra0_count1_lutreg_q : STD_LOGIC_VECTOR (6 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_count1_q : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_count1_i : UNSIGNED (5 downto 0);
    attribute preserve of u0_m0_wo0_wi0_r0_ra0_count1_i : signal is true;
    signal u0_m0_wo0_wi0_r0_ra0_count1_eq : std_logic;
    attribute preserve of u0_m0_wo0_wi0_r0_ra0_count1_eq : signal is true;
    signal u0_m0_wo0_wi0_r0_wa0_q : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_wi0_r0_wa0_i : UNSIGNED (5 downto 0);
    attribute preserve of u0_m0_wo0_wi0_r0_wa0_i : signal is true;
    signal u0_m0_wo0_wi0_r0_memr0_reset0 : std_logic;
    signal u0_m0_wo0_wi0_r0_memr0_ia : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_wi0_r0_memr0_aa : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_wi0_r0_memr0_ab : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_wi0_r0_memr0_iq : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_wi0_r0_memr0_q : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_ca0_q : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_ca0_i : UNSIGNED (5 downto 0);
    attribute preserve of u0_m0_wo0_ca0_i : signal is true;
    signal u0_m0_wo0_ca0_eq : std_logic;
    attribute preserve of u0_m0_wo0_ca0_eq : signal is true;
    signal u0_m0_wo0_cm0_q : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_mtree_mult1_0_a0 : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_mtree_mult1_0_b0 : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_mtree_mult1_0_s1 : STD_LOGIC_VECTOR (15 downto 0);
    signal u0_m0_wo0_mtree_mult1_0_pr : SIGNED (15 downto 0);
    signal u0_m0_wo0_mtree_mult1_0_q : STD_LOGIC_VECTOR (15 downto 0);
    signal d_u0_m0_wo0_mtree_mult1_0_q_18_q : STD_LOGIC_VECTOR (15 downto 0);
    signal d_u0_m0_wo0_mtree_mult1_0_q_19_q : STD_LOGIC_VECTOR (15 downto 0);
    signal d_u0_m0_wo0_mtree_mult1_0_q_20_q : STD_LOGIC_VECTOR (15 downto 0);
    signal u0_m0_wo0_aseq_q : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_aseq_eq : std_logic;
    signal d_u0_m0_wo0_aseq_q_18_q : STD_LOGIC_VECTOR (0 downto 0);
    signal d_u0_m0_wo0_aseq_q_19_q : STD_LOGIC_VECTOR (0 downto 0);
    signal d_u0_m0_wo0_aseq_q_20_q : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_oseq_q : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_oseq_eq : std_logic;
    signal u0_m0_wo0_oseq_gated_reg_q : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_a : STD_LOGIC_VECTOR (6 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_b : STD_LOGIC_VECTOR (6 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_o : STD_LOGIC_VECTOR (6 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_c : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_q : STD_LOGIC_VECTOR (5 downto 0);
    signal d_u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_q_14_q : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_a : STD_LOGIC_VECTOR (3 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_b : STD_LOGIC_VECTOR (3 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_o : STD_LOGIC_VECTOR (3 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_cin : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_q : STD_LOGIC_VECTOR (1 downto 0);
    signal u0_m0_wo0_accum_p1_of_4_a : STD_LOGIC_VECTOR (6 downto 0);
    signal u0_m0_wo0_accum_p1_of_4_b : STD_LOGIC_VECTOR (6 downto 0);
    signal u0_m0_wo0_accum_p1_of_4_i : STD_LOGIC_VECTOR (6 downto 0);
    signal u0_m0_wo0_accum_p1_of_4_o : STD_LOGIC_VECTOR (6 downto 0);
    signal u0_m0_wo0_accum_p1_of_4_c : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_accum_p1_of_4_q : STD_LOGIC_VECTOR (5 downto 0);
    signal d_u0_m0_wo0_accum_p1_of_4_q_21_q : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_accum_p2_of_4_a : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_accum_p2_of_4_b : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_accum_p2_of_4_i : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_accum_p2_of_4_o : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_accum_p2_of_4_cin : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_accum_p2_of_4_c : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_accum_p2_of_4_q : STD_LOGIC_VECTOR (5 downto 0);
    signal d_u0_m0_wo0_accum_p2_of_4_q_21_q : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_accum_p3_of_4_a : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_accum_p3_of_4_b : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_accum_p3_of_4_i : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_accum_p3_of_4_o : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_accum_p3_of_4_cin : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_accum_p3_of_4_c : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_accum_p3_of_4_q : STD_LOGIC_VECTOR (5 downto 0);
    signal d_u0_m0_wo0_accum_p3_of_4_q_21_q : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_accum_p4_of_4_a : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_accum_p4_of_4_b : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_accum_p4_of_4_i : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_accum_p4_of_4_o : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_accum_p4_of_4_cin : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_accum_p4_of_4_q : STD_LOGIC_VECTOR (3 downto 0);
    signal d_u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_tessel0_0_merged_bit_select_c_13_q : STD_LOGIC_VECTOR (0 downto 0);
    signal d_u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_tessel0_0_merged_bit_select_c_13_q : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_BitJoin_for_c_q : STD_LOGIC_VECTOR (1 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_BitJoin_for_c_q : STD_LOGIC_VECTOR (1 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_count0_run_q : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_oseq_gated_q : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_tessel0_0_merged_bit_select_b : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_tessel0_0_merged_bit_select_c : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_tessel0_0_merged_bit_select_b : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_tessel0_0_merged_bit_select_c : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_count1_lut_q : STD_LOGIC_VECTOR (6 downto 0);
    signal u0_m0_wo0_accum_BitSelect_for_a_tessel0_0_b : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_accum_BitSelect_for_a_tessel1_0_b : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_accum_BitSelect_for_a_tessel2_0_b : STD_LOGIC_VECTOR (3 downto 0);
    signal u0_m0_wo0_accum_BitSelect_for_a_tessel2_1_b : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_accum_BitSelect_for_a_tessel3_0_b : STD_LOGIC_VECTOR (0 downto 0);
    signal out0_m0_wo0_lineup_select_delay_0_q : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_add_0_0_BitJoin_for_q_q : STD_LOGIC_VECTOR (7 downto 0);
    signal u0_m0_wo0_accum_BitJoin_for_q_q : STD_LOGIC_VECTOR (21 downto 0);
    signal u0_m0_wo0_accum_BitSelect_for_a_BitJoin_for_d_q : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_accum_BitSelect_for_a_BitJoin_for_e_q : STD_LOGIC_VECTOR (3 downto 0);
    signal out0_m0_wo0_assign_id3_q : STD_LOGIC_VECTOR (0 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_resize_in : STD_LOGIC_VECTOR (5 downto 0);
    signal u0_m0_wo0_wi0_r0_ra0_resize_b : STD_LOGIC_VECTOR (5 downto 0);

begin


    -- VCC(CONSTANT,1)@0
    VCC_q <= "1";

    -- u0_m0_wo0_run(ENABLEGENERATOR,13)@10 + 2
    u0_m0_wo0_run_ctrl <= u0_m0_wo0_run_out & xIn_v & u0_m0_wo0_run_enableQ;
    u0_m0_wo0_run_clkproc: PROCESS (clk, areset)
        variable u0_m0_wo0_run_enable_c : SIGNED(5 downto 0);
        variable u0_m0_wo0_run_inc : SIGNED(1 downto 0);
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_run_q <= "0";
            u0_m0_wo0_run_enable_c := TO_SIGNED(31, 6);
            u0_m0_wo0_run_enableQ <= "0";
            u0_m0_wo0_run_count <= "00";
            u0_m0_wo0_run_inc := (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (u0_m0_wo0_run_out = "1") THEN
                IF (u0_m0_wo0_run_enable_c(5) = '1') THEN
                    u0_m0_wo0_run_enable_c := u0_m0_wo0_run_enable_c - (-32);
                ELSE
                    u0_m0_wo0_run_enable_c := u0_m0_wo0_run_enable_c + (-1);
                END IF;
                u0_m0_wo0_run_enableQ <= STD_LOGIC_VECTOR(u0_m0_wo0_run_enable_c(5 downto 5));
            ELSE
                u0_m0_wo0_run_enableQ <= "0";
            END IF;
            CASE (u0_m0_wo0_run_ctrl) IS
                WHEN "000" | "001" => u0_m0_wo0_run_inc := "00";
                WHEN "010" | "011" => u0_m0_wo0_run_inc := "11";
                WHEN "100" => u0_m0_wo0_run_inc := "00";
                WHEN "101" => u0_m0_wo0_run_inc := "01";
                WHEN "110" => u0_m0_wo0_run_inc := "11";
                WHEN "111" => u0_m0_wo0_run_inc := "00";
                WHEN OTHERS => 
            END CASE;
            u0_m0_wo0_run_count <= STD_LOGIC_VECTOR(SIGNED(u0_m0_wo0_run_count) + SIGNED(u0_m0_wo0_run_inc));
            u0_m0_wo0_run_q <= u0_m0_wo0_run_out;
        END IF;
    END PROCESS;
    u0_m0_wo0_run_preEnaQ <= u0_m0_wo0_run_count(1 downto 1);
    u0_m0_wo0_run_out <= u0_m0_wo0_run_preEnaQ and VCC_q;

    -- u0_m0_wo0_memread(DELAY,14)@12
    u0_m0_wo0_memread : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => u0_m0_wo0_run_q, xout => u0_m0_wo0_memread_q, clk => clk, aclr => areset );

    -- d_u0_m0_wo0_memread_q_13(DELAY,116)@12 + 1
    d_u0_m0_wo0_memread_q_13 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => u0_m0_wo0_memread_q, xout => d_u0_m0_wo0_memread_q_13_q, clk => clk, aclr => areset );

    -- u0_m0_wo0_compute(DELAY,16)@13
    u0_m0_wo0_compute : dspba_delay
    GENERIC MAP ( width => 1, depth => 2, reset_kind => "ASYNC" )
    PORT MAP ( xin => d_u0_m0_wo0_memread_q_13_q, xout => u0_m0_wo0_compute_q, clk => clk, aclr => areset );

    -- d_u0_m0_wo0_compute_q_16(DELAY,117)@13 + 3
    d_u0_m0_wo0_compute_q_16 : dspba_delay
    GENERIC MAP ( width => 1, depth => 3, reset_kind => "ASYNC" )
    PORT MAP ( xin => u0_m0_wo0_compute_q, xout => d_u0_m0_wo0_compute_q_16_q, clk => clk, aclr => areset );

    -- u0_m0_wo0_aseq(SEQUENCE,35)@16 + 1
    u0_m0_wo0_aseq_clkproc: PROCESS (clk, areset)
        variable u0_m0_wo0_aseq_c : SIGNED(7 downto 0);
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_aseq_c := "00000000";
            u0_m0_wo0_aseq_q <= "0";
            u0_m0_wo0_aseq_eq <= '0';
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (d_u0_m0_wo0_compute_q_16_q = "1") THEN
                IF (u0_m0_wo0_aseq_c = "00000000") THEN
                    u0_m0_wo0_aseq_eq <= '1';
                ELSE
                    u0_m0_wo0_aseq_eq <= '0';
                END IF;
                IF (u0_m0_wo0_aseq_eq = '1') THEN
                    u0_m0_wo0_aseq_c := u0_m0_wo0_aseq_c + 32;
                ELSE
                    u0_m0_wo0_aseq_c := u0_m0_wo0_aseq_c - 1;
                END IF;
                u0_m0_wo0_aseq_q <= STD_LOGIC_VECTOR(u0_m0_wo0_aseq_c(7 downto 7));
            END IF;
        END IF;
    END PROCESS;

    -- d_u0_m0_wo0_compute_q_17(DELAY,118)@16 + 1
    d_u0_m0_wo0_compute_q_17 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => d_u0_m0_wo0_compute_q_16_q, xout => d_u0_m0_wo0_compute_q_17_q, clk => clk, aclr => areset );

    -- u0_m0_wo0_wi0_r0_ra0_count1(COUNTER,24)@12
    -- low=0, high=32, step=1, init=1
    u0_m0_wo0_wi0_r0_ra0_count1_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_wi0_r0_ra0_count1_i <= TO_UNSIGNED(1, 6);
            u0_m0_wo0_wi0_r0_ra0_count1_eq <= '0';
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (u0_m0_wo0_memread_q = "1") THEN
                IF (u0_m0_wo0_wi0_r0_ra0_count1_i = TO_UNSIGNED(31, 6)) THEN
                    u0_m0_wo0_wi0_r0_ra0_count1_eq <= '1';
                ELSE
                    u0_m0_wo0_wi0_r0_ra0_count1_eq <= '0';
                END IF;
                IF (u0_m0_wo0_wi0_r0_ra0_count1_eq = '1') THEN
                    u0_m0_wo0_wi0_r0_ra0_count1_i <= u0_m0_wo0_wi0_r0_ra0_count1_i + 32;
                ELSE
                    u0_m0_wo0_wi0_r0_ra0_count1_i <= u0_m0_wo0_wi0_r0_ra0_count1_i + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    u0_m0_wo0_wi0_r0_ra0_count1_q <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR(RESIZE(u0_m0_wo0_wi0_r0_ra0_count1_i, 6)));

    -- u0_m0_wo0_wi0_r0_ra0_count1_lut(LOOKUP,22)@12
    u0_m0_wo0_wi0_r0_ra0_count1_lut_combproc: PROCESS (u0_m0_wo0_wi0_r0_ra0_count1_q)
    BEGIN
        -- Begin reserved scope level
        CASE (u0_m0_wo0_wi0_r0_ra0_count1_q) IS
            WHEN "000000" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0100001";
            WHEN "000001" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0100010";
            WHEN "000010" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0100011";
            WHEN "000011" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0100100";
            WHEN "000100" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0100101";
            WHEN "000101" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0100110";
            WHEN "000110" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0100111";
            WHEN "000111" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0101000";
            WHEN "001000" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0101001";
            WHEN "001001" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0101010";
            WHEN "001010" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0101011";
            WHEN "001011" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0101100";
            WHEN "001100" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0101101";
            WHEN "001101" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0101110";
            WHEN "001110" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0101111";
            WHEN "001111" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0110000";
            WHEN "010000" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0110001";
            WHEN "010001" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0110010";
            WHEN "010010" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0110011";
            WHEN "010011" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0110100";
            WHEN "010100" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0110101";
            WHEN "010101" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0110110";
            WHEN "010110" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0110111";
            WHEN "010111" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0111000";
            WHEN "011000" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0111001";
            WHEN "011001" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0111010";
            WHEN "011010" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0111011";
            WHEN "011011" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0111100";
            WHEN "011100" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0111101";
            WHEN "011101" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0111110";
            WHEN "011110" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0111111";
            WHEN "011111" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0000000";
            WHEN "100000" => u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= "0000001";
            WHEN OTHERS => -- unreachable
                           u0_m0_wo0_wi0_r0_ra0_count1_lut_q <= (others => '-');
        END CASE;
        -- End reserved scope level
    END PROCESS;

    -- u0_m0_wo0_wi0_r0_ra0_count1_lutreg(REG,23)@12
    u0_m0_wo0_wi0_r0_ra0_count1_lutreg_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_wi0_r0_ra0_count1_lutreg_q <= "0100001";
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (u0_m0_wo0_memread_q = "1") THEN
                u0_m0_wo0_wi0_r0_ra0_count1_lutreg_q <= STD_LOGIC_VECTOR(u0_m0_wo0_wi0_r0_ra0_count1_lut_q);
            END IF;
        END IF;
    END PROCESS;

    -- u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_tessel0_0_merged_bit_select(BITSELECT,113)@12
    u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_tessel0_0_merged_bit_select_b <= STD_LOGIC_VECTOR(u0_m0_wo0_wi0_r0_ra0_count1_lutreg_q(5 downto 0));
    u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_tessel0_0_merged_bit_select_c <= STD_LOGIC_VECTOR(u0_m0_wo0_wi0_r0_ra0_count1_lutreg_q(6 downto 6));

    -- u0_m0_wo0_wi0_r0_ra0_count0_inner(COUNTER,19)@12
    -- low=-1, high=31, step=-1, init=31
    u0_m0_wo0_wi0_r0_ra0_count0_inner_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_wi0_r0_ra0_count0_inner_i <= TO_SIGNED(31, 6);
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (u0_m0_wo0_memread_q = "1") THEN
                IF (u0_m0_wo0_wi0_r0_ra0_count0_inner_i(5 downto 5) = "1") THEN
                    u0_m0_wo0_wi0_r0_ra0_count0_inner_i <= u0_m0_wo0_wi0_r0_ra0_count0_inner_i - 32;
                ELSE
                    u0_m0_wo0_wi0_r0_ra0_count0_inner_i <= u0_m0_wo0_wi0_r0_ra0_count0_inner_i - 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    u0_m0_wo0_wi0_r0_ra0_count0_inner_q <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR(RESIZE(u0_m0_wo0_wi0_r0_ra0_count0_inner_i, 6)));

    -- u0_m0_wo0_wi0_r0_ra0_count0_run(LOGICAL,20)@12
    u0_m0_wo0_wi0_r0_ra0_count0_run_q <= STD_LOGIC_VECTOR(u0_m0_wo0_wi0_r0_ra0_count0_inner_q(5 downto 5));

    -- u0_m0_wo0_wi0_r0_ra0_count0(COUNTER,21)@12
    -- low=0, high=63, step=1, init=0
    u0_m0_wo0_wi0_r0_ra0_count0_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_wi0_r0_ra0_count0_i <= TO_UNSIGNED(0, 6);
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (u0_m0_wo0_memread_q = "1" and u0_m0_wo0_wi0_r0_ra0_count0_run_q = "1") THEN
                u0_m0_wo0_wi0_r0_ra0_count0_i <= u0_m0_wo0_wi0_r0_ra0_count0_i + 1;
            END IF;
        END IF;
    END PROCESS;
    u0_m0_wo0_wi0_r0_ra0_count0_q <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR(RESIZE(u0_m0_wo0_wi0_r0_ra0_count0_i, 7)));

    -- u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_tessel0_0_merged_bit_select(BITSELECT,112)@12
    u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_tessel0_0_merged_bit_select_b <= STD_LOGIC_VECTOR(u0_m0_wo0_wi0_r0_ra0_count0_q(5 downto 0));
    u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_tessel0_0_merged_bit_select_c <= STD_LOGIC_VECTOR(u0_m0_wo0_wi0_r0_ra0_count0_q(6 downto 6));

    -- u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2(ADD,51)@12 + 1
    u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_a <= STD_LOGIC_VECTOR("0" & u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_tessel0_0_merged_bit_select_b);
    u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_b <= STD_LOGIC_VECTOR("0" & u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_tessel0_0_merged_bit_select_b);
    u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_o <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_o <= STD_LOGIC_VECTOR(UNSIGNED(u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_a) + UNSIGNED(u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_b));
        END IF;
    END PROCESS;
    u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_c(0) <= u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_o(6);
    u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_q <= u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_o(5 downto 0);

    -- d_u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_tessel0_0_merged_bit_select_c_13(DELAY,133)@12 + 1
    d_u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_tessel0_0_merged_bit_select_c_13 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_tessel0_0_merged_bit_select_c, xout => d_u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_tessel0_0_merged_bit_select_c_13_q, clk => clk, aclr => areset );

    -- u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_BitJoin_for_c(BITJOIN,77)@13
    u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_BitJoin_for_c_q <= GND_q & d_u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_tessel0_0_merged_bit_select_c_13_q;

    -- d_u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_tessel0_0_merged_bit_select_c_13(DELAY,132)@12 + 1
    d_u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_tessel0_0_merged_bit_select_c_13 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_tessel0_0_merged_bit_select_c, xout => d_u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_tessel0_0_merged_bit_select_c_13_q, clk => clk, aclr => areset );

    -- u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_BitJoin_for_c(BITJOIN,72)@13
    u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_BitJoin_for_c_q <= GND_q & d_u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_tessel0_0_merged_bit_select_c_13_q;

    -- u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2(ADD,52)@13 + 1
    u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_cin <= u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_c;
    u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_a <= STD_LOGIC_VECTOR("0" & u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_a_BitJoin_for_c_q) & '1';
    u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_b <= STD_LOGIC_VECTOR("0" & u0_m0_wo0_wi0_r0_ra0_add_0_0_BitSelect_for_b_BitJoin_for_c_q) & u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_cin(0);
    u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_o <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_o <= STD_LOGIC_VECTOR(UNSIGNED(u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_a) + UNSIGNED(u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_b));
        END IF;
    END PROCESS;
    u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_q <= u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_o(2 downto 1);

    -- d_u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_q_14(DELAY,128)@13 + 1
    d_u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_q_14 : dspba_delay
    GENERIC MAP ( width => 6, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_q, xout => d_u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_q_14_q, clk => clk, aclr => areset );

    -- u0_m0_wo0_wi0_r0_ra0_add_0_0_BitJoin_for_q(BITJOIN,53)@14
    u0_m0_wo0_wi0_r0_ra0_add_0_0_BitJoin_for_q_q <= u0_m0_wo0_wi0_r0_ra0_add_0_0_p2_of_2_q & d_u0_m0_wo0_wi0_r0_ra0_add_0_0_p1_of_2_q_14_q;

    -- u0_m0_wo0_wi0_r0_ra0_resize(BITSELECT,26)@14
    u0_m0_wo0_wi0_r0_ra0_resize_in <= STD_LOGIC_VECTOR(u0_m0_wo0_wi0_r0_ra0_add_0_0_BitJoin_for_q_q(5 downto 0));
    u0_m0_wo0_wi0_r0_ra0_resize_b <= STD_LOGIC_VECTOR(u0_m0_wo0_wi0_r0_ra0_resize_in(5 downto 0));

    -- d_xIn_0_14(DELAY,114)@10 + 4
    d_xIn_0_14 : dspba_delay
    GENERIC MAP ( width => 8, depth => 4, reset_kind => "ASYNC" )
    PORT MAP ( xin => xIn_0, xout => d_xIn_0_14_q, clk => clk, aclr => areset );

    -- d_in0_m0_wi0_wo0_assign_id1_q_14(DELAY,115)@10 + 4
    d_in0_m0_wi0_wo0_assign_id1_q_14 : dspba_delay
    GENERIC MAP ( width => 1, depth => 4, reset_kind => "ASYNC" )
    PORT MAP ( xin => xIn_v, xout => d_in0_m0_wi0_wo0_assign_id1_q_14_q, clk => clk, aclr => areset );

    -- u0_m0_wo0_wi0_r0_wa0(COUNTER,27)@14
    -- low=0, high=63, step=1, init=1
    u0_m0_wo0_wi0_r0_wa0_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_wi0_r0_wa0_i <= TO_UNSIGNED(1, 6);
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (d_in0_m0_wi0_wo0_assign_id1_q_14_q = "1") THEN
                u0_m0_wo0_wi0_r0_wa0_i <= u0_m0_wo0_wi0_r0_wa0_i + 1;
            END IF;
        END IF;
    END PROCESS;
    u0_m0_wo0_wi0_r0_wa0_q <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR(RESIZE(u0_m0_wo0_wi0_r0_wa0_i, 6)));

    -- u0_m0_wo0_wi0_r0_memr0(DUALMEM,28)@14
    u0_m0_wo0_wi0_r0_memr0_ia <= STD_LOGIC_VECTOR(d_xIn_0_14_q);
    u0_m0_wo0_wi0_r0_memr0_aa <= u0_m0_wo0_wi0_r0_wa0_q;
    u0_m0_wo0_wi0_r0_memr0_ab <= u0_m0_wo0_wi0_r0_ra0_resize_b;
    u0_m0_wo0_wi0_r0_memr0_dmem : altera_syncram
    GENERIC MAP (
        ram_block_type => "M10K",
        operation_mode => "DUAL_PORT",
        width_a => 8,
        widthad_a => 6,
        numwords_a => 64,
        width_b => 8,
        widthad_b => 6,
        numwords_b => 64,
        lpm_type => "altera_syncram",
        width_byteena_a => 1,
        address_reg_b => "CLOCK0",
        indata_reg_b => "CLOCK0",
        rdcontrol_reg_b => "CLOCK0",
        byteena_reg_b => "CLOCK0",
        outdata_reg_b => "CLOCK0",
        outdata_aclr_b => "NONE",
        clock_enable_input_a => "NORMAL",
        clock_enable_input_b => "NORMAL",
        clock_enable_output_b => "NORMAL",
        read_during_write_mode_mixed_ports => "DONT_CARE",
        power_up_uninitialized => "FALSE",
        init_file => "UNUSED",
        intended_device_family => "Cyclone V"
    )
    PORT MAP (
        clocken0 => '1',
        clock0 => clk,
        address_a => u0_m0_wo0_wi0_r0_memr0_aa,
        data_a => u0_m0_wo0_wi0_r0_memr0_ia,
        wren_a => d_in0_m0_wi0_wo0_assign_id1_q_14_q(0),
        address_b => u0_m0_wo0_wi0_r0_memr0_ab,
        q_b => u0_m0_wo0_wi0_r0_memr0_iq
    );
    u0_m0_wo0_wi0_r0_memr0_q <= u0_m0_wo0_wi0_r0_memr0_iq(7 downto 0);

    -- u0_m0_wo0_ca0(COUNTER,29)@13
    -- low=0, high=32, step=1, init=0
    u0_m0_wo0_ca0_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_ca0_i <= TO_UNSIGNED(0, 6);
            u0_m0_wo0_ca0_eq <= '0';
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (u0_m0_wo0_compute_q = "1") THEN
                IF (u0_m0_wo0_ca0_i = TO_UNSIGNED(31, 6)) THEN
                    u0_m0_wo0_ca0_eq <= '1';
                ELSE
                    u0_m0_wo0_ca0_eq <= '0';
                END IF;
                IF (u0_m0_wo0_ca0_eq = '1') THEN
                    u0_m0_wo0_ca0_i <= u0_m0_wo0_ca0_i + 32;
                ELSE
                    u0_m0_wo0_ca0_i <= u0_m0_wo0_ca0_i + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    u0_m0_wo0_ca0_q <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR(RESIZE(u0_m0_wo0_ca0_i, 6)));

    -- u0_m0_wo0_cm0(LOOKUP,33)@13 + 1
    u0_m0_wo0_cm0_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_cm0_q <= "00000000";
        ELSIF (clk'EVENT AND clk = '1') THEN
            CASE (u0_m0_wo0_ca0_q) IS
                WHEN "000000" => u0_m0_wo0_cm0_q <= "00000000";
                WHEN "000001" => u0_m0_wo0_cm0_q <= "00000000";
                WHEN "000010" => u0_m0_wo0_cm0_q <= "00000000";
                WHEN "000011" => u0_m0_wo0_cm0_q <= "00000000";
                WHEN "000100" => u0_m0_wo0_cm0_q <= "00000000";
                WHEN "000101" => u0_m0_wo0_cm0_q <= "00000001";
                WHEN "000110" => u0_m0_wo0_cm0_q <= "00000011";
                WHEN "000111" => u0_m0_wo0_cm0_q <= "00000100";
                WHEN "001000" => u0_m0_wo0_cm0_q <= "00000000";
                WHEN "001001" => u0_m0_wo0_cm0_q <= "11111000";
                WHEN "001010" => u0_m0_wo0_cm0_q <= "11101111";
                WHEN "001011" => u0_m0_wo0_cm0_q <= "11110000";
                WHEN "001100" => u0_m0_wo0_cm0_q <= "00000000";
                WHEN "001101" => u0_m0_wo0_cm0_q <= "00100010";
                WHEN "001110" => u0_m0_wo0_cm0_q <= "01001101";
                WHEN "001111" => u0_m0_wo0_cm0_q <= "01110000";
                WHEN "010000" => u0_m0_wo0_cm0_q <= "01111111";
                WHEN "010001" => u0_m0_wo0_cm0_q <= "01110000";
                WHEN "010010" => u0_m0_wo0_cm0_q <= "01001101";
                WHEN "010011" => u0_m0_wo0_cm0_q <= "00100010";
                WHEN "010100" => u0_m0_wo0_cm0_q <= "00000000";
                WHEN "010101" => u0_m0_wo0_cm0_q <= "11110000";
                WHEN "010110" => u0_m0_wo0_cm0_q <= "11101111";
                WHEN "010111" => u0_m0_wo0_cm0_q <= "11111000";
                WHEN "011000" => u0_m0_wo0_cm0_q <= "00000000";
                WHEN "011001" => u0_m0_wo0_cm0_q <= "00000100";
                WHEN "011010" => u0_m0_wo0_cm0_q <= "00000011";
                WHEN "011011" => u0_m0_wo0_cm0_q <= "00000001";
                WHEN "011100" => u0_m0_wo0_cm0_q <= "00000000";
                WHEN "011101" => u0_m0_wo0_cm0_q <= "00000000";
                WHEN "011110" => u0_m0_wo0_cm0_q <= "00000000";
                WHEN "011111" => u0_m0_wo0_cm0_q <= "00000000";
                WHEN "100000" => u0_m0_wo0_cm0_q <= "00000000";
                WHEN OTHERS => -- unreachable
                               u0_m0_wo0_cm0_q <= (others => '-');
            END CASE;
        END IF;
    END PROCESS;

    -- u0_m0_wo0_mtree_mult1_0(MULT,34)@14 + 3
    u0_m0_wo0_mtree_mult1_0_pr <= SIGNED(SIGNED(u0_m0_wo0_mtree_mult1_0_a0) * SIGNED(u0_m0_wo0_mtree_mult1_0_b0));
    u0_m0_wo0_mtree_mult1_0_component: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_mtree_mult1_0_a0 <= (others => '0');
            u0_m0_wo0_mtree_mult1_0_b0 <= (others => '0');
            u0_m0_wo0_mtree_mult1_0_s1 <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            u0_m0_wo0_mtree_mult1_0_a0 <= STD_LOGIC_VECTOR(u0_m0_wo0_cm0_q);
            u0_m0_wo0_mtree_mult1_0_b0 <= STD_LOGIC_VECTOR(u0_m0_wo0_wi0_r0_memr0_q);
            u0_m0_wo0_mtree_mult1_0_s1 <= STD_LOGIC_VECTOR(u0_m0_wo0_mtree_mult1_0_pr);
        END IF;
    END PROCESS;
    u0_m0_wo0_mtree_mult1_0: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_mtree_mult1_0_q <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            u0_m0_wo0_mtree_mult1_0_q <= u0_m0_wo0_mtree_mult1_0_s1;
        END IF;
    END PROCESS;

    -- u0_m0_wo0_accum_BitSelect_for_a_tessel0_0(BITSELECT,78)@17
    u0_m0_wo0_accum_BitSelect_for_a_tessel0_0_b <= STD_LOGIC_VECTOR(u0_m0_wo0_mtree_mult1_0_q(5 downto 0));

    -- u0_m0_wo0_accum_p1_of_4(ADD,63)@17 + 1
    u0_m0_wo0_accum_p1_of_4_a <= STD_LOGIC_VECTOR("0" & u0_m0_wo0_accum_BitSelect_for_a_tessel0_0_b);
    u0_m0_wo0_accum_p1_of_4_b <= STD_LOGIC_VECTOR("0" & u0_m0_wo0_accum_p1_of_4_q);
    u0_m0_wo0_accum_p1_of_4_i <= u0_m0_wo0_accum_p1_of_4_a;
    u0_m0_wo0_accum_p1_of_4_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_accum_p1_of_4_o <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (d_u0_m0_wo0_compute_q_17_q = "1") THEN
                IF (u0_m0_wo0_aseq_q = "1") THEN
                    u0_m0_wo0_accum_p1_of_4_o <= u0_m0_wo0_accum_p1_of_4_i;
                ELSE
                    u0_m0_wo0_accum_p1_of_4_o <= STD_LOGIC_VECTOR(UNSIGNED(u0_m0_wo0_accum_p1_of_4_a) + UNSIGNED(u0_m0_wo0_accum_p1_of_4_b));
                END IF;
            END IF;
        END IF;
    END PROCESS;
    u0_m0_wo0_accum_p1_of_4_c(0) <= u0_m0_wo0_accum_p1_of_4_o(6);
    u0_m0_wo0_accum_p1_of_4_q <= u0_m0_wo0_accum_p1_of_4_o(5 downto 0);

    -- d_u0_m0_wo0_aseq_q_18(DELAY,125)@17 + 1
    d_u0_m0_wo0_aseq_q_18 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => u0_m0_wo0_aseq_q, xout => d_u0_m0_wo0_aseq_q_18_q, clk => clk, aclr => areset );

    -- d_u0_m0_wo0_compute_q_18(DELAY,119)@17 + 1
    d_u0_m0_wo0_compute_q_18 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => d_u0_m0_wo0_compute_q_17_q, xout => d_u0_m0_wo0_compute_q_18_q, clk => clk, aclr => areset );

    -- d_u0_m0_wo0_mtree_mult1_0_q_18(DELAY,122)@17 + 1
    d_u0_m0_wo0_mtree_mult1_0_q_18 : dspba_delay
    GENERIC MAP ( width => 16, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => u0_m0_wo0_mtree_mult1_0_q, xout => d_u0_m0_wo0_mtree_mult1_0_q_18_q, clk => clk, aclr => areset );

    -- u0_m0_wo0_accum_BitSelect_for_a_tessel1_0(BITSELECT,80)@18
    u0_m0_wo0_accum_BitSelect_for_a_tessel1_0_b <= STD_LOGIC_VECTOR(d_u0_m0_wo0_mtree_mult1_0_q_18_q(11 downto 6));

    -- u0_m0_wo0_accum_p2_of_4(ADD,64)@18 + 1
    u0_m0_wo0_accum_p2_of_4_cin <= u0_m0_wo0_accum_p1_of_4_c;
    u0_m0_wo0_accum_p2_of_4_a <= STD_LOGIC_VECTOR("0" & u0_m0_wo0_accum_BitSelect_for_a_tessel1_0_b) & '1';
    u0_m0_wo0_accum_p2_of_4_b <= STD_LOGIC_VECTOR("0" & u0_m0_wo0_accum_p2_of_4_q) & u0_m0_wo0_accum_p2_of_4_cin(0);
    u0_m0_wo0_accum_p2_of_4_i <= u0_m0_wo0_accum_p2_of_4_a;
    u0_m0_wo0_accum_p2_of_4_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_accum_p2_of_4_o <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (d_u0_m0_wo0_compute_q_18_q = "1") THEN
                IF (d_u0_m0_wo0_aseq_q_18_q = "1") THEN
                    u0_m0_wo0_accum_p2_of_4_o <= u0_m0_wo0_accum_p2_of_4_i;
                ELSE
                    u0_m0_wo0_accum_p2_of_4_o <= STD_LOGIC_VECTOR(UNSIGNED(u0_m0_wo0_accum_p2_of_4_a) + UNSIGNED(u0_m0_wo0_accum_p2_of_4_b));
                END IF;
            END IF;
        END IF;
    END PROCESS;
    u0_m0_wo0_accum_p2_of_4_c(0) <= u0_m0_wo0_accum_p2_of_4_o(7);
    u0_m0_wo0_accum_p2_of_4_q <= u0_m0_wo0_accum_p2_of_4_o(6 downto 1);

    -- d_u0_m0_wo0_aseq_q_19(DELAY,126)@18 + 1
    d_u0_m0_wo0_aseq_q_19 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => d_u0_m0_wo0_aseq_q_18_q, xout => d_u0_m0_wo0_aseq_q_19_q, clk => clk, aclr => areset );

    -- d_u0_m0_wo0_compute_q_19(DELAY,120)@18 + 1
    d_u0_m0_wo0_compute_q_19 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => d_u0_m0_wo0_compute_q_18_q, xout => d_u0_m0_wo0_compute_q_19_q, clk => clk, aclr => areset );

    -- d_u0_m0_wo0_mtree_mult1_0_q_19(DELAY,123)@18 + 1
    d_u0_m0_wo0_mtree_mult1_0_q_19 : dspba_delay
    GENERIC MAP ( width => 16, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => d_u0_m0_wo0_mtree_mult1_0_q_18_q, xout => d_u0_m0_wo0_mtree_mult1_0_q_19_q, clk => clk, aclr => areset );

    -- u0_m0_wo0_accum_BitSelect_for_a_tessel2_1(BITSELECT,83)@19
    u0_m0_wo0_accum_BitSelect_for_a_tessel2_1_b <= STD_LOGIC_VECTOR(d_u0_m0_wo0_mtree_mult1_0_q_19_q(15 downto 15));

    -- u0_m0_wo0_accum_BitSelect_for_a_tessel2_0(BITSELECT,82)@19
    u0_m0_wo0_accum_BitSelect_for_a_tessel2_0_b <= STD_LOGIC_VECTOR(d_u0_m0_wo0_mtree_mult1_0_q_19_q(15 downto 12));

    -- u0_m0_wo0_accum_BitSelect_for_a_BitJoin_for_d(BITJOIN,85)@19
    u0_m0_wo0_accum_BitSelect_for_a_BitJoin_for_d_q <= u0_m0_wo0_accum_BitSelect_for_a_tessel2_1_b & u0_m0_wo0_accum_BitSelect_for_a_tessel2_1_b & u0_m0_wo0_accum_BitSelect_for_a_tessel2_0_b;

    -- u0_m0_wo0_accum_p3_of_4(ADD,65)@19 + 1
    u0_m0_wo0_accum_p3_of_4_cin <= u0_m0_wo0_accum_p2_of_4_c;
    u0_m0_wo0_accum_p3_of_4_a <= STD_LOGIC_VECTOR("0" & u0_m0_wo0_accum_BitSelect_for_a_BitJoin_for_d_q) & '1';
    u0_m0_wo0_accum_p3_of_4_b <= STD_LOGIC_VECTOR("0" & u0_m0_wo0_accum_p3_of_4_q) & u0_m0_wo0_accum_p3_of_4_cin(0);
    u0_m0_wo0_accum_p3_of_4_i <= u0_m0_wo0_accum_p3_of_4_a;
    u0_m0_wo0_accum_p3_of_4_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_accum_p3_of_4_o <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (d_u0_m0_wo0_compute_q_19_q = "1") THEN
                IF (d_u0_m0_wo0_aseq_q_19_q = "1") THEN
                    u0_m0_wo0_accum_p3_of_4_o <= u0_m0_wo0_accum_p3_of_4_i;
                ELSE
                    u0_m0_wo0_accum_p3_of_4_o <= STD_LOGIC_VECTOR(UNSIGNED(u0_m0_wo0_accum_p3_of_4_a) + UNSIGNED(u0_m0_wo0_accum_p3_of_4_b));
                END IF;
            END IF;
        END IF;
    END PROCESS;
    u0_m0_wo0_accum_p3_of_4_c(0) <= u0_m0_wo0_accum_p3_of_4_o(7);
    u0_m0_wo0_accum_p3_of_4_q <= u0_m0_wo0_accum_p3_of_4_o(6 downto 1);

    -- d_u0_m0_wo0_aseq_q_20(DELAY,127)@19 + 1
    d_u0_m0_wo0_aseq_q_20 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => d_u0_m0_wo0_aseq_q_19_q, xout => d_u0_m0_wo0_aseq_q_20_q, clk => clk, aclr => areset );

    -- d_u0_m0_wo0_compute_q_20(DELAY,121)@19 + 1
    d_u0_m0_wo0_compute_q_20 : dspba_delay
    GENERIC MAP ( width => 1, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => d_u0_m0_wo0_compute_q_19_q, xout => d_u0_m0_wo0_compute_q_20_q, clk => clk, aclr => areset );

    -- d_u0_m0_wo0_mtree_mult1_0_q_20(DELAY,124)@19 + 1
    d_u0_m0_wo0_mtree_mult1_0_q_20 : dspba_delay
    GENERIC MAP ( width => 16, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => d_u0_m0_wo0_mtree_mult1_0_q_19_q, xout => d_u0_m0_wo0_mtree_mult1_0_q_20_q, clk => clk, aclr => areset );

    -- u0_m0_wo0_accum_BitSelect_for_a_tessel3_0(BITSELECT,86)@20
    u0_m0_wo0_accum_BitSelect_for_a_tessel3_0_b <= STD_LOGIC_VECTOR(d_u0_m0_wo0_mtree_mult1_0_q_20_q(15 downto 15));

    -- u0_m0_wo0_accum_BitSelect_for_a_BitJoin_for_e(BITJOIN,90)@20
    u0_m0_wo0_accum_BitSelect_for_a_BitJoin_for_e_q <= u0_m0_wo0_accum_BitSelect_for_a_tessel3_0_b & u0_m0_wo0_accum_BitSelect_for_a_tessel3_0_b & u0_m0_wo0_accum_BitSelect_for_a_tessel3_0_b & u0_m0_wo0_accum_BitSelect_for_a_tessel3_0_b;

    -- u0_m0_wo0_accum_p4_of_4(ADD,66)@20 + 1
    u0_m0_wo0_accum_p4_of_4_cin <= u0_m0_wo0_accum_p3_of_4_c;
    u0_m0_wo0_accum_p4_of_4_a <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((4 downto 4 => u0_m0_wo0_accum_BitSelect_for_a_BitJoin_for_e_q(3)) & u0_m0_wo0_accum_BitSelect_for_a_BitJoin_for_e_q) & '1');
    u0_m0_wo0_accum_p4_of_4_b <= STD_LOGIC_VECTOR(STD_LOGIC_VECTOR((4 downto 4 => u0_m0_wo0_accum_p4_of_4_q(3)) & u0_m0_wo0_accum_p4_of_4_q) & u0_m0_wo0_accum_p4_of_4_cin(0));
    u0_m0_wo0_accum_p4_of_4_i <= u0_m0_wo0_accum_p4_of_4_a;
    u0_m0_wo0_accum_p4_of_4_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_accum_p4_of_4_o <= (others => '0');
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (d_u0_m0_wo0_compute_q_20_q = "1") THEN
                IF (d_u0_m0_wo0_aseq_q_20_q = "1") THEN
                    u0_m0_wo0_accum_p4_of_4_o <= u0_m0_wo0_accum_p4_of_4_i;
                ELSE
                    u0_m0_wo0_accum_p4_of_4_o <= STD_LOGIC_VECTOR(SIGNED(u0_m0_wo0_accum_p4_of_4_a) + SIGNED(u0_m0_wo0_accum_p4_of_4_b));
                END IF;
            END IF;
        END IF;
    END PROCESS;
    u0_m0_wo0_accum_p4_of_4_q <= u0_m0_wo0_accum_p4_of_4_o(4 downto 1);

    -- d_u0_m0_wo0_accum_p3_of_4_q_21(DELAY,131)@20 + 1
    d_u0_m0_wo0_accum_p3_of_4_q_21 : dspba_delay
    GENERIC MAP ( width => 6, depth => 1, reset_kind => "ASYNC" )
    PORT MAP ( xin => u0_m0_wo0_accum_p3_of_4_q, xout => d_u0_m0_wo0_accum_p3_of_4_q_21_q, clk => clk, aclr => areset );

    -- d_u0_m0_wo0_accum_p2_of_4_q_21(DELAY,130)@19 + 2
    d_u0_m0_wo0_accum_p2_of_4_q_21 : dspba_delay
    GENERIC MAP ( width => 6, depth => 2, reset_kind => "ASYNC" )
    PORT MAP ( xin => u0_m0_wo0_accum_p2_of_4_q, xout => d_u0_m0_wo0_accum_p2_of_4_q_21_q, clk => clk, aclr => areset );

    -- d_u0_m0_wo0_accum_p1_of_4_q_21(DELAY,129)@18 + 3
    d_u0_m0_wo0_accum_p1_of_4_q_21 : dspba_delay
    GENERIC MAP ( width => 6, depth => 3, reset_kind => "ASYNC" )
    PORT MAP ( xin => u0_m0_wo0_accum_p1_of_4_q, xout => d_u0_m0_wo0_accum_p1_of_4_q_21_q, clk => clk, aclr => areset );

    -- u0_m0_wo0_accum_BitJoin_for_q(BITJOIN,67)@21
    u0_m0_wo0_accum_BitJoin_for_q_q <= u0_m0_wo0_accum_p4_of_4_q & d_u0_m0_wo0_accum_p3_of_4_q_21_q & d_u0_m0_wo0_accum_p2_of_4_q_21_q & d_u0_m0_wo0_accum_p1_of_4_q_21_q;

    -- GND(CONSTANT,0)@0
    GND_q <= "0";

    -- u0_m0_wo0_oseq(SEQUENCE,37)@19 + 1
    u0_m0_wo0_oseq_clkproc: PROCESS (clk, areset)
        variable u0_m0_wo0_oseq_c : SIGNED(7 downto 0);
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_oseq_c := "00100000";
            u0_m0_wo0_oseq_q <= "0";
            u0_m0_wo0_oseq_eq <= '0';
        ELSIF (clk'EVENT AND clk = '1') THEN
            IF (d_u0_m0_wo0_compute_q_19_q = "1") THEN
                IF (u0_m0_wo0_oseq_c = "00000000") THEN
                    u0_m0_wo0_oseq_eq <= '1';
                ELSE
                    u0_m0_wo0_oseq_eq <= '0';
                END IF;
                IF (u0_m0_wo0_oseq_eq = '1') THEN
                    u0_m0_wo0_oseq_c := u0_m0_wo0_oseq_c + 32;
                ELSE
                    u0_m0_wo0_oseq_c := u0_m0_wo0_oseq_c - 1;
                END IF;
                u0_m0_wo0_oseq_q <= STD_LOGIC_VECTOR(u0_m0_wo0_oseq_c(7 downto 7));
            END IF;
        END IF;
    END PROCESS;

    -- u0_m0_wo0_oseq_gated(LOGICAL,38)@20
    u0_m0_wo0_oseq_gated_q <= u0_m0_wo0_oseq_q and d_u0_m0_wo0_compute_q_20_q;

    -- u0_m0_wo0_oseq_gated_reg(REG,39)@20 + 1
    u0_m0_wo0_oseq_gated_reg_clkproc: PROCESS (clk, areset)
    BEGIN
        IF (areset = '1') THEN
            u0_m0_wo0_oseq_gated_reg_q <= "0";
        ELSIF (clk'EVENT AND clk = '1') THEN
            u0_m0_wo0_oseq_gated_reg_q <= STD_LOGIC_VECTOR(u0_m0_wo0_oseq_gated_q);
        END IF;
    END PROCESS;

    -- out0_m0_wo0_lineup_select_delay_0(DELAY,41)@21
    out0_m0_wo0_lineup_select_delay_0_q <= STD_LOGIC_VECTOR(u0_m0_wo0_oseq_gated_reg_q);

    -- out0_m0_wo0_assign_id3(DELAY,43)@21
    out0_m0_wo0_assign_id3_q <= STD_LOGIC_VECTOR(out0_m0_wo0_lineup_select_delay_0_q);

    -- xOut(PORTOUT,44)@21 + 1
    xOut_v <= out0_m0_wo0_assign_id3_q;
    xOut_c <= STD_LOGIC_VECTOR("0000000" & GND_q);
    xOut_0 <= u0_m0_wo0_accum_BitJoin_for_q_q;

END normal;
