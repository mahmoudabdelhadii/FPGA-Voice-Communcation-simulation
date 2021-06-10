	BCH_example u0 (
		.clk        (<connected-to-clk>),        // clk.clk
		.reset      (<connected-to-reset>),      // rst.reset
		.load       (<connected-to-load>),       //  in.valid
		.ready      (<connected-to-ready>),      //    .ready
		.sop_in     (<connected-to-sop_in>),     //    .startofpacket
		.eop_in     (<connected-to-eop_in>),     //    .endofpacket
		.data_in    (<connected-to-data_in>),    //    .data_in
		.valid_out  (<connected-to-valid_out>),  // out.valid
		.sink_ready (<connected-to-sink_ready>), //    .ready
		.sop_out    (<connected-to-sop_out>),    //    .startofpacket
		.eop_out    (<connected-to-eop_out>),    //    .endofpacket
		.data_out   (<connected-to-data_out>)    //    .data_out
	);

