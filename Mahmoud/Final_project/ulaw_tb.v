module ulaw_tb();
	
	reg clk;
	
	reg signed [13:0] in;
	wire signed [7:0] enc_out;
	wire signed [13:0] dec_out;
	wire signed [14:0] err;
	
	reg [3:0] test_num;
	reg [7:0] enc_exp;
	reg [13:0] dec_exp;
	
	wire [13:0] lin_in;								// Linear input value; produced by taking
															// two's complement of input, inverting all bits
															// after sign bit if negative, and adding 33
	wire [13:0] in_twos;
	assign in_twos = ~in + 1'b1;
	assign lin_in = {	in_twos[13],
							((in > 0) ? in_twos[12:0] : ~in_twos[12:0])}
							+ 6'b100001;
	
	wire [13:0] lin_out;								// Linear output value; signed magnitude
															// representation, final result produced by
															// decreasing magnitude of this value by 33
	assign lin_out = ((dec_out > 0) ? dec_out : -dec_out) - 6'b100001;
	
	ulaw_comp DUT1(	.clk(clk),
							.in(in),
							.enc_out(enc_out));
	
	ulaw_decomp DUT2(	.clk(clk),
							.enc_in(enc_out),
							.dec_out(dec_out));
	
	initial forever begin
		clk = 0; #5;
		clk = 1; #5;
	end
	
	initial begin
		test_num = 0;
		in = 14'bx;
		enc_exp = 7'bx;
		dec_exp = 14'bx;
		#10;
		
		/* ============================== TEST #1 ============================== */
		test_num = 1;
		in = 14'b0_00000001_0001_0;
		#0;
		enc_exp = {in[14-1], 3'b000, in[4:1]};
		dec_exp = {in[14-1], 8'b00000001, in[4:1], 1'b1};
		#10;
		
		$display("[TEST #%dA - %s] Compressed output is	%b, expected %b.",
					test_num, (enc_out == enc_exp) ? "SUCCESS" : "FAIL", enc_out, enc_exp);
		$display("[TEST #%dB - %s] Decompressed output is %b, expected %b.",
					test_num, (dec_out == dec_exp) ? "SUCCESS" : "FAIL", dec_out, dec_exp);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #2 ============================== */
		test_num = 2;
		in = 14'b1_0000001_0010_10;
		#0;
		enc_exp = {in[14-1], 3'b001, in[5:2]};
		dec_exp = {in[14-1], 7'b0000001, in[5:2], 2'b10};
		#10;
		
		$display("[TEST #%dA - %s] Compressed output is %b, expected %b.",
					test_num, (enc_out == enc_exp) ? "SUCCESS" : "FAIL", enc_out, enc_exp);
		$display("[TEST #%dB - %s] Decompressed output is %b, expected %b.",
					test_num, (dec_out == dec_exp) ? "SUCCESS" : "FAIL", dec_out, dec_exp);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #3 ============================== */
		test_num = 3;
		in = 14'b0_000001_0011_010;
		#0;
		enc_exp = {in[14-1], 3'b010, in[6:3]};
		dec_exp = {in[14-1], 6'b000001, in[6:3], 3'b100};
		#10;
		
		$display("[TEST #%dA - %s] Compressed output is %b, expected %b.",
					test_num, (enc_out == enc_exp) ? "SUCCESS" : "FAIL", enc_out, enc_exp);
		$display("[TEST #%dB - %s] Decompressed output is %b, expected %b.",
					test_num, (dec_out == dec_exp) ? "SUCCESS" : "FAIL", dec_out, dec_exp);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #4 ============================== */
		test_num = 4;
		in = 14'b1_00001_0100_1010;
		#0;
		enc_exp = {in[14-1], 3'b011, in[7:4]};
		dec_exp = {in[14-1], 5'b00001, in[7:4], 4'b1000};
		#10;
		
		$display("[TEST #%dA - %s] Compressed output is %b, expected %b.",
					test_num, (enc_out == enc_exp) ? "SUCCESS" : "FAIL", enc_out, enc_exp);
		$display("[TEST #%dB - %s] Decompressed output is %b, expected %b.",
					test_num, (dec_out == dec_exp) ? "SUCCESS" : "FAIL", dec_out, dec_exp);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #5 ============================== */
		test_num = 5;
		in = 14'b0_0001_0101_01110;
		#0;
		enc_exp = {in[14-1], 3'b100, in[8:5]};
		dec_exp = {in[14-1], 4'b0001, in[8:5], 5'b10000};
		#10;
		
		$display("[TEST #%dA - %s] Compressed output is %b, expected %b.",
					test_num, (enc_out == enc_exp) ? "SUCCESS" : "FAIL", enc_out, enc_exp);
		$display("[TEST #%dB - %s] Decompressed output is %b, expected %b.",
					test_num, (dec_out == dec_exp) ? "SUCCESS" : "FAIL", dec_out, dec_exp);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #6 ============================== */
		test_num = 6;
		in = 14'b1_001_0110_101011;
		#0;
		enc_exp = {in[14-1], 3'b101, in[9:6]};
		dec_exp = {in[14-1], 3'b001, in[9:6], 6'b100000};
		#10;
		
		$display("[TEST #%dA - %s] Compressed output is %b, expected %b.",
					test_num, (enc_out == enc_exp) ? "SUCCESS" : "FAIL", enc_out, enc_exp);
		$display("[TEST #%dB - %s] Decompressed output is %b, expected %b.",
					test_num, (dec_out == dec_exp) ? "SUCCESS" : "FAIL", dec_out, dec_exp);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #7 ============================== */
		test_num = 7;
		in = 14'b0_01_0111_1100001;
		#0;
		enc_exp = {in[14-1], 3'b110, in[10:7]};
		dec_exp = {in[14-1], 2'b01, in[10:7], 7'b1000000};
		#10;
		
		$display("[TEST #%dA - %s] Compressed output is %b, expected %b.",
					test_num, (enc_out == enc_exp) ? "SUCCESS" : "FAIL", enc_out, enc_exp);
		$display("[TEST #%dB - %s] Decompressed output is %b, expected %b.",
					test_num, (dec_out == dec_exp) ? "SUCCESS" : "FAIL", dec_out, dec_exp);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #8 ============================== */
		test_num = 8;
		in = 14'b1_1_1000_11111111;
		#0;
		enc_exp = {in[14-1], 3'b111, in[11:8]};
		dec_exp = {in[14-1], 1'b1, in[11:8], 8'b10000000};
		#10;
		
		$display("[TEST #%dA - %s] Compressed output is %b, expected %b.",
					test_num, (enc_out == enc_exp) ? "SUCCESS" : "FAIL", enc_out, enc_exp);
		$display("[TEST #%dB - %s] Decompressed output is %b, expected %b.",
					test_num, (dec_out == dec_exp) ? "SUCCESS" : "FAIL", dec_out, dec_exp);
		#10;
		/* ===================================================================== */
		
		$stop;
	end
endmodule
