// - Phase states using Binary constellation ordering:
//		(0000)	->	0 deg		= 0 rad			->	(1, 0)
//		(0001)	-> 22.5 deg	= pi/8			-> (0.9238795, 0.3826834)
//		(0010)	->	45 deg	= pi/4 rad		->	(0.7071068, 0.7071068)
//		(0011)	-> 67.5 deg	= 3*pi/8 rad	-> (0.3826834, 0.9238795)
//		(0100)	->	90 deg	= pi/2 rad		->	(0, 1)
//		(0101)	-> 112.5 deg= 5*pi/8 rad	-> (-0.3826834, 0.9238795)
//		(0110)	->	135 deg	= 3*pi/4 rad	->	(-0.7071068, 0.7071068)
//		(0111)	-> 157.5 deg= 7*pi/8 rad	-> (-0.9238795, 0.3826834)
//		(1000)	->	180 deg	= pi rad			->	(-1, 0)
//		(1001)	-> 202.5 deg= 9*pi/8 rad	-> (-0.9238795, -0.3826834)
//		(1010)	->	225 deg	= 5*pi/4 rad	->	(-0.7071068, -0.7071068)
//		(1011)	-> 247.5 deg= 11*pi/8 rad	-> (-0.3826834, -0.9238795)
//		(1100)	->	270 deg	= 3*pi/2 rad	->	(0, -1)
//		(1101)	-> 292.5 deg= 13*pi/8 rad	-> (0.3826834, -0.9238795)
//		(1110)	->	315 deg	= 7*pi/4 rad	->	(0.7071068, -0.7071068)
//		(1111)	-> 337.5 deg= 15*pi/8 rad	-> (0.9238795, -0.3826834)
// Note: floating point values are approximated to 7 decimal digits of precision

// Single precision fixed point (IEEE-754) format:
// {sign[0], exponent[7:0], mantissa[22:0]} => 32 bits in total
`define POS_ONE		32'b0_01111111_00000000000000000000000		// 1
`define NEG_ONE		32'b1_01111111_00000000000000000000000		// -1
`define ZERO			32'b0_00000000_00000000000000000000000		// 0
`define POS_0_3827	32'b0_01111101_10000111110111100010100		// 0.3826834
`define NEG_0_3827	32'b1_01111101_10000111110111100010100		// -0.3826834
`define POS_0_7071	32'b0_01111110_01101010000010011110100		// 0.7071068
`define NEG_0_7071	32'b1_01111110_01101010000010011110100		// -0.7071068
`define POS_0_9239	32'b0_01111110_11011001000001101011110		// 0.9238795
`define NEG_0_9239	32'b1_01111110_11011001000001101011110		// -0.9238795

module sixteen_psk_tb();
	reg clk;
	
	reg signed [3:0] in;
	wire signed [31:0] re_ph, im_ph;
	wire signed [3:0] out;
	
	reg [4:0] test_num;
	
	sixteen_psk_mod DUT1 (	.clk(clk),
								.in(in),
								.re_out(re_ph),
								.im_out(im_ph));
	
	sixteen_psk_demod DUT2 (	.clk(clk),
									.re_in(re_ph),
									.im_in(im_ph),
									.out(out));
	
	initial forever begin
		clk = 0; #5;
		clk = 1; #5;
	end
	
	initial begin
		test_num = 0;
		in = 4'bxxx;
		#10;
		
		/* ============================== TEST #1 ============================== */
		test_num = 1;
		in = 4'b0000;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #2 ============================== */
		test_num = 2;
		in = 4'b0001;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #3 ============================== */
		test_num = 3;
		in = 4'b0010;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #4 ============================== */
		test_num = 4;
		in = 4'b0011;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #5 ============================== */
		test_num = 5;
		in = 4'b0100;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #6 ============================== */
		test_num = 6;
		in = 4'b0101;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #7 ============================== */
		test_num = 7;
		in = 4'b0110;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #8 ============================== */
		test_num = 8;
		in = 4'b0111;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		
		/* ============================== TEST #9 ============================== */
		test_num = 9;
		in = 4'b1000;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		
		/* ============================== TEST #10 ============================== */
		test_num = 10;
		in = 4'b1001;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		
		/* ============================== TEST #11 ============================== */
		test_num = 11;
		in = 4'b1010;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		
		/* ============================== TEST #12 ============================== */
		test_num = 12;
		in = 4'b1011;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		
		/* ============================== TEST #13 ============================== */
		test_num = 13;
		in = 4'b1100;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		
		/* ============================== TEST #14 ============================== */
		test_num = 14;
		in = 4'b1101;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		
		/* ============================== TEST #15 ============================== */
		test_num = 15;
		in = 4'b1110;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		
		/* ============================== TEST #16 ============================== */
		test_num = 16;
		in = 4'b1111;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		$stop;
	end
endmodule
