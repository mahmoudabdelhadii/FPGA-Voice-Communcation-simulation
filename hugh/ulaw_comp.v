// u-law compression (14-bit -> 8-bit)
module ulaw_comp(clk, in, enc_out);
	input clk;
	input signed [13:0] in;							// 14-bit audio input
	
	output reg signed [7:0] enc_out;				// 8-bit encoded output
	
	wire s;												// Sign bit
	assign s = in[13];
	
	wire [13:0] lin_in;								// Linear input value; produced by taking
															// two's complement of input, inverting all bits
															// after sign bit if negative, and adding 33
	wire [13:0] in_twos;
	assign in_twos = ~in + 1'b1;
	assign lin_in = {	in_twos[13],
							((in > 0) ? in_twos[12:0] : ~in_twos[12:0])}
							+ 6'b100001;
	
	// Encoding logic
	always @* begin : Encode
		casex (in)
			{s, 8'b00000001, in[4:1], 1'bx}:		enc_out <= {s, 3'b000, in[4:1]};
			{s, 7'b0000001, in[5:2], 2'bxx}:		enc_out <= {s, 3'b001, in[5:2]};
			{s, 6'b000001, in[6:3], 3'bxxx}:		enc_out <= {s, 3'b010, in[6:3]};
			{s, 5'b00001, in[7:4], 4'bxxxx}:		enc_out <= {s, 3'b011, in[7:4]};
			{s, 4'b0001, in[8:5], 5'bxxxxx}:		enc_out <= {s, 3'b100, in[8:5]};
			{s, 3'b001, in[9:6], 6'bxxxxxx}:		enc_out <= {s, 3'b101, in[9:6]};
			{s, 2'b01, in[10:7], 7'bxxxxxxx}:	enc_out <= {s, 3'b110, in[10:7]};
			{s, 1'b1, in[11:8], 8'bxxxxxxxx}:	enc_out <= {s, 3'b111, in[11:8]};
			default:										enc_out <= {s, 7'b0000_000};
		endcase
	end
	
endmodule
