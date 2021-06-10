`timescale 1 ps / 1 ps
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


            BCH_204_128_10_enc DUT (
                .clk        (clk),        // clk.clk
                .reset      (reset),      // rst.reset
                .load       (load),       //  in.valid
                .ready      (ready),      //    .ready
                .sop_in     (sop_in),     //    .startofpacket
                .eop_in     (eop_in),     //    .endofpacket
                .data_in    (data_in),    //    .data_in
                .valid_out  (valid_out),  // out.valid
                .sink_ready (sink_ready), //    .ready
                .sop_out    (sop_out),    //    .startofpacket
                .eop_out    (eop_out),    //    .endofpacket
                .data_out   (data_out)    //    .data_out
            );
            /*
            input  wire       sop_in,     //    .startofpacket
            input  wire       eop_in,     //    .endofpacket
            input  wire [7:0] data_in,    //    .data_in
            input  wire       load,       //  in.valid
            input  wire       sink_ready, //    .ready
            input  wire       reset       // rst.reset
            */
        always begin 
        #20    clk = ~clk;
        end
always begin 
        #20    load = ~load;
        end
            initial begin
assert(std::randomize(data_in));
                clk = 1'b0;
                reset =1'b1;
                sop_in =1'b0;
                eop_in =1'b0;
                load =1'b0;
                sink_ready =1'b1;
                #20
                sop_in =1'b1;
                #40
                sop_in =1'b0;
		#320
                eop_in =1'b1;
                #20
                eop_in =1'b0;
            end
endmodule
                
