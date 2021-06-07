	component RSdecoder is
		port (
			clk_clk         : in  std_logic                     := 'X';             -- clk
			reset_reset_n   : in  std_logic                     := 'X';             -- reset_n
			in_valid        : in  std_logic                     := 'X';             -- valid
			in_symbols_in   : in  std_logic_vector(79 downto 0) := (others => 'X'); -- symbols_in
			out_valid       : out std_logic;                                        -- valid
			out_errors_out  : out std_logic_vector(4 downto 0);                     -- errors_out
			out_decfail     : out std_logic_vector(0 downto 0);                     -- decfail
			out_symbols_out : out std_logic_vector(79 downto 0)                     -- symbols_out
		);
	end component RSdecoder;

	u0 : component RSdecoder
		port map (
			clk_clk         => CONNECTED_TO_clk_clk,         --   clk.clk
			reset_reset_n   => CONNECTED_TO_reset_reset_n,   -- reset.reset_n
			in_valid        => CONNECTED_TO_in_valid,        --    in.valid
			in_symbols_in   => CONNECTED_TO_in_symbols_in,   --      .symbols_in
			out_valid       => CONNECTED_TO_out_valid,       --   out.valid
			out_errors_out  => CONNECTED_TO_out_errors_out,  --      .errors_out
			out_decfail     => CONNECTED_TO_out_decfail,     --      .decfail
			out_symbols_out => CONNECTED_TO_out_symbols_out  --      .symbols_out
		);

