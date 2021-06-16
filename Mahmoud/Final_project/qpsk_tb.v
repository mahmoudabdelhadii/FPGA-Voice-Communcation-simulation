// - Phase states using Binary constellation ordering:
//		(00)	->	45 deg	= pi/4 rad		->	(1/sqrt(2), 1/sqrt(2))		~=	(0.7071068, 0.7071068)
//		(01)	->	135 deg	= 3*pi/4 rad	->	(-1/sqrt(2), 1/sqrt(2))		~=	(-0.7071068, 0.7071068)
//		(10)	->	225 deg	= 5*pi/4 rad	->	(-1/sqrt(2), -1/sqrt(2))	~=	(-0.7071068, -0.7071068)
//		(11)	->	315 deg	= 7*pi/4 rad	->	(1/sqrt(2), -1/sqrt(2))		~=	(0.7071068, -0.7071068)
// Note: floating point values are approximated to 7 decimal digits of precision

// Single precision fixed point (IEEE-754) format:
// {sign[0], exponent[7:0], mantissa[22:0]} => 32 bits in total
`define POS_0_7071	32'b0_01111110_01101010000010010000001		// 0.7071068
`define NEG_0_7071	32'b1_01111110_01101010000010010000001		// -0.7071068

// Note: Euclidean distance of QPSK, d_4 ~= sqrt(2) ~= 1.4142136
// 		-> error tolerance should be (d_4 / 2) ~= 0.7071068
// Lower bounds:
`define POS_0_7071_LOW	32'b0_00000000_00000000000000000000000	// 0.7071068 - (d_4 / 2)	= 0.0000000
`define NEG_0_7071_LOW	32'b1_01111111_01101010000010011110100	// -0.7071068 - (d_4 / 2)	= -1.4142136
// Higher bounds:
`define POS_0_7071_HIGH	32'b0_01111111_01101010000010011110100	// 0.7071068 + (d_4 / 2)	= 1.4142136
`define NEG_0_7071_HIGH	32'b0_00000000_00000000000000000000000	// -0.7071068 + (d_4 / 2)	= 0.0000000

module qpsk_tb();
	reg clk;
	
	reg signed [1:0] in;
	wire signed [31:0] re_ph, im_ph;
	wire signed [1:0] out;
	
	reg [3:0] test_num;
	
	qpsk_mod DUT1 (	.clk(clk),
							.in(in),
							.re_out(re_ph),
							.im_out(im_ph));
	
	qpsk_demod DUT2 (	.clk(clk),
							.re_in(re_ph),
							.im_in(im_ph),
							.out(out));
	
	initial forever begin
		clk = 0; #5;
		clk = 1; #5;
	end
	
	initial begin
		test_num = 0;
		in = 2'bxx;
		#10;
		
		/* ============================== TEST #1 ============================== */
		test_num = 1;
		in = 2'b00;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #2 ============================== */
		test_num = 2;
		in = 2'b01;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #3 ============================== */
		test_num = 3;
		in = 2'b10;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
		
		/* ============================== TEST #4 ============================== */
		test_num = 4;
		in = 2'b11;
		#10;
		
		$display("[TEST #%d - %s] Modulated	%b, demodulated %b.",
					test_num, (out == in) ? "SUCCESS" : "FAIL", in, out);
		#10;
		/* ===================================================================== */
				
		$stop;
	end
endmodule
