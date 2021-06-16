// - Phase states using Binary constellation ordering:
//		(000)	->	0 deg		= 0 rad			->	(1, 0)
//		(001)	->	45 deg	= pi/4 rad		->	(1/sqrt(2), 1/sqrt(2))		~=	(0.7071068, 0.7071068)
//		(010)	->	90 deg	= pi/2 rad		->	(0, 1)
//		(011)	->	135 deg	= 3*pi/4 rad	->	(-1/sqrt(2), 1/sqrt(2))		~=	(-0.7071068, 0.7071068)
//		(100)	->	180 deg	= pi rad			->	(-1, 0)
//		(101)	->	225 deg	= 5*pi/4 rad	->	(-1/sqrt(2), -1/sqrt(2))	~=	(-0.7071068, -0.7071068)
//		(110)	->	270 deg	= 3*pi/2 rad	->	(0, -1)
//		(111)	->	315 deg	= 7*pi/4 rad	->	(1/sqrt(2), -1/sqrt(2))		~=	(0.7071068, -0.7071068)
// Note: floating point values are approximated to 7 decimal digits of precision

// Single precision fixed point (IEEE-754) format:
// {sign[0], exponent[7:0], mantissa[22:0]} => 32 bits in total
`define POS_ONE		32'b0_01111111_00000000000000000000000		// 1
`define NEG_ONE		32'b1_01111111_00000000000000000000000		// -1
`define ZERO			32'b0_00000000_00000000000000000000000		// 0
`define POS_0_7071	32'b0_01111110_01101010000010011110100		// 0.7071068
`define NEG_0_7071	32'b1_01111110_01101010000010011110100		// -0.7071068

// Note: Euclidean distance of 8PSK, d_8 ~= 1/sqrt(2) ~= 0.7071068
// 		-> error tolerance should be (d_8 / 2) ~= 0.3535534
// Lower bounds:
`define POS_ONE_LOW		32'b0_01111110_01001010111110110000110	// 1 - (d_8 / 2)				= 0.6464466
`define NEG_ONE_LOW		32'b1_01111111_01011010100000100111101	// -1 - (d_8 / 2)				= -1.3535534
`define ZERO_LOW			32'b1_01111101_01101010000010011110100	// 0 - (d_8 / 2)				= -0.3535534
`define POS_0_7071_LOW	32'b0_01111101_01101010000010011110100	// 0.7071068 - (d_8 / 2)	= 0.3535534
`define NEG_0_7071_LOW	32'b1_01111111_00001111100001110110111	// -0.7071068 - (d_8 / 2)	= -1.0606602
// Higher bounds:
`define POS_ONE_HIGH		32'b0_01111111_01011010100000100111101	// 1 + (d_8 / 2)				= 1.3535534
`define NEG_ONE_HIGH		32'b1_01111110_01001010111110110000110	// -1 + (d_8 / 2)				= -0.6464466
`define ZERO_HIGH			32'b0_01111101_01101010000010011110100	// 0 + (d_8 / 2)				= 0.3535534
`define POS_0_7071_HIGH	32'b0_01111111_00001111100001110110111	// 0.7071068 + (d_8 / 2)	= 1.0606602
`define NEG_0_7071_HIGH	32'b1_01111101_01101010000010011110100	// -0.7071068 + (d_8 / 2)	= -0.3535534

module eight_psk_tb();
	reg clk;
	
	reg signed [2:0] in;
	wire signed [31:0] re_ph, im_ph;
	wire signed [2:0] out;
	
	reg [3:0] test_num;
	
	eight_psk_mod DUT1 (	.clk(clk),
								.in(in),
								.re_out(re_ph),
								.im_out(im_ph));
	
	eight_psk_demod DUT2 (	.clk(clk),
									.re_in(re_ph),
									.im_in(im_ph),
									.out(out));
	
	initial forever begin
		clk = 0; #5;
		clk = 1; #5;
	end
	
	initial begin
		test_num = 0;
		in = 3'bxxx;
		#10;
		
		/* ============================== TEST #1 ============================== */
		test_num = 1;
		in = 3'b000;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #2 ============================== */
		test_num = 2;
		in = 3'b001;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #3 ============================== */
		test_num = 3;
		in = 3'b010;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #4 ============================== */
		test_num = 4;
		in = 3'b011;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #5 ============================== */
		test_num = 5;
		in = 3'b100;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #6 ============================== */
		test_num = 6;
		in = 3'b101;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #7 ============================== */
		test_num = 7;
		in = 3'b110;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #8 ============================== */
		test_num = 8;
		in = 3'b111;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		$stop;
	end
endmodule
