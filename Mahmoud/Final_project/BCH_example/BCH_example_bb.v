
module BCH_example (
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
	data_out);	

	input		clk;
	input		reset;
	input		load;
	output		ready;
	input		sop_in;
	input		eop_in;
	input	[0:0]	data_in;
	output		valid_out;
	input		sink_ready;
	output		sop_out;
	output		eop_out;
	output	[0:0]	data_out;
endmodule
