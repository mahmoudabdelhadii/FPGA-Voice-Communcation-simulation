
module BCH_204_128_10_dec (
	clk,
	reset,
	load,
	ready,
	sop_in,
	eop_in,
	data_in,
	valid_out,
	sink_ready,
	sop_out,
	eop_out,
	data_out,
	number_errors);	

	input		clk;
	input		reset;
	input		load;
	output		ready;
	input		sop_in;
	input		eop_in;
	input	[7:0]	data_in;
	output		valid_out;
	input		sink_ready;
	output		sop_out;
	output		eop_out;
	output	[7:0]	data_out;
	output	[7:0]	number_errors;
endmodule
