
module RSdecoder (
	clk_clk,
	reset_reset_n,
	in_valid,
	in_symbols_in,
	out_valid,
	out_errors_out,
	out_decfail,
	out_symbols_out);	

	input		clk_clk;
	input		reset_reset_n;
	input		in_valid;
	input	[79:0]	in_symbols_in;
	output		out_valid;
	output	[4:0]	out_errors_out;
	output	[0:0]	out_decfail;
	output	[79:0]	out_symbols_out;
endmodule
