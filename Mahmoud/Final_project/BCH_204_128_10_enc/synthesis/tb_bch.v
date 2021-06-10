
module tb_BCH;


            logic       clk;       // clk.clk
		    logic       load;       //  in.valid
			logic      ready;     //    .ready
			logic        sop_in;     //    .startofpacket
			logic        eop_in;     //    .endofpacket
			logic  [7:0] data_in;    //    .data_in
			logic        valid_out;  // out.valid
			logic        sink_ready; //    .ready
			logic        sop_out;    //    .startofpacket
			logic        eop_out;    //    .endofpacket
			logic  [7:0] data_out;   //    .data_out
			logic        reset;       // rst.reset


