	RSdecoder u0 (
		.clk_clk         (<connected-to-clk_clk>),         //   clk.clk
		.reset_reset_n   (<connected-to-reset_reset_n>),   // reset.reset_n
		.in_valid        (<connected-to-in_valid>),        //    in.valid
		.in_symbols_in   (<connected-to-in_symbols_in>),   //      .symbols_in
		.out_valid       (<connected-to-out_valid>),       //   out.valid
		.out_errors_out  (<connected-to-out_errors_out>),  //      .errors_out
		.out_decfail     (<connected-to-out_decfail>),     //      .decfail
		.out_symbols_out (<connected-to-out_symbols_out>)  //      .symbols_out
	);

