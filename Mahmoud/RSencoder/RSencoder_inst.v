	RSencoder u0 (
		.clk_clk           (<connected-to-clk_clk>),           //   clk.clk
		.reset_reset_n     (<connected-to-reset_reset_n>),     // reset.reset_n
		.in_startofpacket  (<connected-to-in_startofpacket>),  //    in.startofpacket
		.in_endofpacket    (<connected-to-in_endofpacket>),    //      .endofpacket
		.in_valid          (<connected-to-in_valid>),          //      .valid
		.in_ready          (<connected-to-in_ready>),          //      .ready
		.in_data           (<connected-to-in_data>),           //      .data
		.out_startofpacket (<connected-to-out_startofpacket>), //   out.startofpacket
		.out_endofpacket   (<connected-to-out_endofpacket>),   //      .endofpacket
		.out_valid         (<connected-to-out_valid>),         //      .valid
		.out_data          (<connected-to-out_data>)           //      .data
	);

