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

module eight_psk_mod(clk, in, re_out, im_out);
	input clk;
	input signed [2:0] in;
	output reg signed [31:0] re_out, im_out;
	
	// Break inbound message down into 3-bit segments, then map each segment as complex (Re, Im) 
	always @* begin : Modulate
		case (in)
			{3'b000}:	{re_out, im_out} <= {`POS_ONE, `ZERO};				// (1, 0)
			{3'b001}:	{re_out, im_out} <= {`POS_0_7071, `POS_0_7071};	// (0.7071068, 0.7071068)
			{3'b010}:	{re_out, im_out} <= {`ZERO, `POS_ONE};				// (0, 1)
			{3'b011}:	{re_out, im_out} <= {`NEG_0_7071, `POS_0_7071};	// (-0.7071068, 0.7071068)
			{3'b100}:	{re_out, im_out} <= {`NEG_ONE, `ZERO};				// (-1, 0)
			{3'b101}:	{re_out, im_out} <= {`NEG_0_7071, `NEG_0_7071};	// (-0.7071068, -0.7071068)
			{3'b110}:	{re_out, im_out} <= {`ZERO, `NEG_ONE};				// (0, -1)
			{3'b111}:	{re_out, im_out} <= {`POS_0_7071, `NEG_0_7071};	// (0.7071068, -0.7071068)
			default:		{re_out, im_out} <= {32'bx, 32'bx};
		endcase
	end
endmodule

module eight_psk_demod(clk, re_in, im_in, out);
	input clk;
	input signed [31:0] re_in, im_in;
	output reg signed [2:0] out;
	
	/*
	// Check if inbound values fall within expected bounds, demodulate accordingly
	*/
	always @* begin : Demodulate
		// (1, 0)
		/*
		if (((re_in <= `POS_ONE_HIGH) && (re_in >= `POS_ONE_LOW))
				&& ((im_in <= `ZERO_HIGH) && (im_in >= `ZERO_LOW))) begin
		*/
		if ({re_in, im_in} == {`POS_ONE, `ZERO}) begin
			out <= 3'b000;
		end
		
		// (0, 1)
		/*
		else if (((re_in <= `ZERO_HIGH) && (re_in >= `ZERO_LOW))
					&& ((im_in <= `POS_ONE_HIGH) && (im_in >= `POS_ONE_LOW))) begin
		*/
		else if ({re_in, im_in} == {`ZERO, `POS_ONE}) begin
			out <= 3'b010;
		end
		
		// (-1, 0)
		/*
		else if (((re_in <= `NEG_ONE_HIGH) && (re_in >= `NEG_ONE_LOW))
					&& ((im_in <= `ZERO_HIGH) && (im_in >= `ZERO_LOW))) begin
		*/
		else if ({re_in, im_in} == {`NEG_ONE, `ZERO}) begin
			out <= 3'b100;
		end
		
		// (0, -1)
		/*
		else if (((re_in <= `ZERO_HIGH) && (re_in >= `ZERO_LOW))
					&& ((im_in <= `NEG_ONE_HIGH) && (im_in >= `NEG_ONE_LOW))) begin
		*/
		else if ({re_in, im_in} == {`ZERO, `NEG_ONE}) begin
			out <= 3'b110;
		end
		
		// (0.7071068, 0.7071068)
		/*
		else if ((re_in <= `POS_0_7071_HIGH) && (re_in >= `POS_0_7071_LOW)
					&& ((im_in <= `POS_0_7071_HIGH) && (im_in >= `POS_0_7071_LOW))) begin
		*/
		else if ({re_in, im_in} == {`POS_0_7071, `POS_0_7071}) begin
			out <= 3'b001;
		end
			
		// (0.7071068, -0.7071068)
		/*
		else if (((re_in <= `POS_0_7071_HIGH) && (re_in >= `POS_0_7071_LOW))
					&& ((im_in <= `NEG_0_7071_HIGH) && (im_in >= `NEG_0_7071_LOW))) begin
		*/
		else if ({re_in, im_in} == {`POS_0_7071, `NEG_0_7071}) begin
			out <= 3'b111;
		end
			
		// (-0.7071068, 0.7071068)
		/*
		else if (((re_in <= `NEG_0_7071_HIGH) && (re_in >= `NEG_0_7071_LOW))
					&& ((im_in <= `POS_0_7071_HIGH) && (im_in >= `POS_0_7071_LOW))) begin
		*/
		else if ({re_in, im_in} == {`NEG_0_7071, `POS_0_7071}) begin
			out <= 3'b011;
		end
		
		// (-0.7071068, -0.7071068)
		/*
		else if (((re_in <= `NEG_0_7071_HIGH) && (re_in >= `NEG_0_7071_LOW))
					&& ((im_in <= `NEG_0_7071_HIGH) && (im_in >= `NEG_0_7071_LOW))) begin
		*/
		else if ({re_in, im_in} == {`NEG_0_7071, `NEG_0_7071}) begin
			out <= 3'b101;
		end
				
		else begin
			out <= 3'bxxx;
		end
	end
endmodule
