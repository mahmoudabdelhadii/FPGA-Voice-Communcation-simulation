	component BCH_204_128_10_dec is
		port (
			clk           : in  std_logic                    := 'X';             -- clk
			reset         : in  std_logic                    := 'X';             -- reset
			load          : in  std_logic                    := 'X';             -- valid
			ready         : out std_logic;                                       -- ready
			sop_in        : in  std_logic                    := 'X';             -- startofpacket
			eop_in        : in  std_logic                    := 'X';             -- endofpacket
			data_in       : in  std_logic_vector(7 downto 0) := (others => 'X'); -- data_in
			valid_out     : out std_logic;                                       -- valid
			sink_ready    : in  std_logic                    := 'X';             -- ready
			sop_out       : out std_logic;                                       -- startofpacket
			eop_out       : out std_logic;                                       -- endofpacket
			data_out      : out std_logic_vector(7 downto 0);                    -- data_out
			number_errors : out std_logic_vector(7 downto 0)                     -- number_errors
		);
	end component BCH_204_128_10_dec;

	u0 : component BCH_204_128_10_dec
		port map (
			clk           => CONNECTED_TO_clk,           -- clk.clk
			reset         => CONNECTED_TO_reset,         -- rst.reset
			load          => CONNECTED_TO_load,          --  in.valid
			ready         => CONNECTED_TO_ready,         --    .ready
			sop_in        => CONNECTED_TO_sop_in,        --    .startofpacket
			eop_in        => CONNECTED_TO_eop_in,        --    .endofpacket
			data_in       => CONNECTED_TO_data_in,       --    .data_in
			valid_out     => CONNECTED_TO_valid_out,     -- out.valid
			sink_ready    => CONNECTED_TO_sink_ready,    --    .ready
			sop_out       => CONNECTED_TO_sop_out,       --    .startofpacket
			eop_out       => CONNECTED_TO_eop_out,       --    .endofpacket
			data_out      => CONNECTED_TO_data_out,      --    .data_out
			number_errors => CONNECTED_TO_number_errors  --    .number_errors
		);

