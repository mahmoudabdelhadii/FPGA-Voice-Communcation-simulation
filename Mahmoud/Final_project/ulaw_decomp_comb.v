// u-law decompression (8-bit > 14-bit)
module ulaw_decomp(clk, enc_in, dec_out);
	input clk;
	input signed [7:0] enc_in;						// 8-bit encoded input
	
	output reg signed [13:0] dec_out;			// 14-bit decoded output
	
	wire s;												// Sign bit
	assign s = enc_in[7];
	
	wire [13:0] lin_out;							// Linear output value; signed magnitude
															// representation, final result produced by
															// decreasing magnitude of this value by 33
	assign lin_out = ((dec_out > 0) ? dec_out : -dec_out) - 6'b100001;
		
	// Decoding logic
	always_comb begin : Decode
		case (enc_in[6:4])
			{3'b000}:	dec_out <= {s, 8'b00000001, enc_in[3:0], 1'b1};
			{3'b001}:	dec_out <= {s, 7'b0000001, enc_in[3:0], 2'b10};
			{3'b010}:	dec_out <= {s, 6'b000001, enc_in[3:0], 3'b100};
			{3'b011}:	dec_out <= {s, 5'b00001, enc_in[3:0], 4'b1000};
			{3'b100}:	dec_out <= {s, 4'b0001, enc_in[3:0], 5'b10000};
			{3'b101}:	dec_out <= {s, 3'b001, enc_in[3:0], 6'b100000};
			{3'b110}:	dec_out <= {s, 2'b01, enc_in[3:0], 7'b1000000};
			{3'b111}:	dec_out <= {s, 1'b1, enc_in[3:0], 8'b10000000};
			default:		dec_out <= {s, 13'b0000_0000_0000_0};
		endcase
	end
endmodule
