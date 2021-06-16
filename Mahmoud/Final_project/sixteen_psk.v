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

module sixteen_psk_mod(clk, in, re_out, im_out);
	input clk;
	input signed [3:0] in;
	output reg signed [31:0] re_out, im_out;
	
	// Break inbound message down into 4-bit segments, then map each segment as complex (Re, Im) 
	always @* begin : Modulate
		case (in)
			{4'b0000}:	{re_out, im_out} <= {`POS_ONE, `ZERO};				// (1, 0)
			{4'b0001}:	{re_out, im_out} <= {`POS_0_9239, `POS_0_3827};	// (0.9238795, 0.3826834)
			{4'b0010}:	{re_out, im_out} <= {`POS_0_7071, `POS_0_7071};	// (0.7071068, 0.7071068)
			{4'b0011}:	{re_out, im_out} <= {`POS_0_3827, `POS_0_9239};	// (0.3826834, 0.9238795)
			{4'b0100}:	{re_out, im_out} <= {`ZERO, `POS_ONE};				// (0, 1)
			{4'b0101}:	{re_out, im_out} <= {`NEG_0_3827, `POS_0_9239};	// (-0.3826824, 0.9238795)
			{4'b0110}:	{re_out, im_out} <= {`NEG_0_7071, `POS_0_7071};	// (-0.7071068, 0.7071068)
			{4'b0111}:	{re_out, im_out} <= {`NEG_0_9239, `POS_0_3827};	// (-0.9238795, 0.3826834)
			{4'b1000}:	{re_out, im_out} <= {`NEG_ONE, `ZERO};				// (-1, 0)
			{4'b1001}:	{re_out, im_out} <= {`NEG_0_9239, `NEG_0_3827};	// (-0.9238795, -0.3826834)
			{4'b1010}:	{re_out, im_out} <= {`NEG_0_7071, `NEG_0_7071};	// (-0.7071068, -0.7071068)
			{4'b1011}:	{re_out, im_out} <= {`NEG_0_3827, `NEG_0_9239};	// (-0.3826834, -0.9238795)
			{4'b1100}:	{re_out, im_out} <= {`ZERO, `NEG_ONE};				// (0, -1)
			{4'b1101}:	{re_out, im_out} <= {`POS_0_3827, `NEG_0_9239};	// (0.3826834, -0.9238795)
			{4'b1110}:	{re_out, im_out} <= {`POS_0_7071, `NEG_0_7071};	// (0.7071068, -0.7071068)
			{4'b1111}:	{re_out, im_out} <= {`POS_0_9239, `NEG_0_3827};	// (0.9238795, -0.3826834)
			default:		{re_out, im_out} <= {32'bx, 32'bx};
		endcase
	end
endmodule

module sixteen_psk_demod(clk, re_in, im_in, out);
	input clk;
	input signed [31:0] re_in, im_in;
	output reg signed [3:0] out;
	
	always @* begin : Demodulate
		// (1, 0)
		if ({re_in, im_in} == {`POS_ONE, `ZERO}) begin
			out <= 4'b0000;
		end
		
		// (0.9238795, 0.3826834)
		else if({re_in, im_in} == {`POS_0_9239, `POS_0_3827}) begin
			out <= 4'b0001;
		end
		
		// (0.7071068, 0.7071068)
		else if({re_in, im_in} == {`POS_0_7071, `POS_0_7071}) begin
			out <= 4'b0010;
		end
		
		// (0.3826834, 0.9238795)
		else if({re_in, im_in} == {`POS_0_3827, `POS_0_9239}) begin
			out <= 4'b0011;
		end
		
		// (0, 1)
		else if({re_in, im_in} == {`ZERO, `POS_ONE}) begin
			out <= 4'b0100;
		end
		
		// (-0.3826834, 0.9238795)
		else if({re_in, im_in} == {`NEG_0_3827, `POS_0_9239}) begin
			out <= 4'b0101;
		end
		
		// (-0.7071068, 0.7071068)
		else if({re_in, im_in} == {`NEG_0_7071, `POS_0_7071}) begin
			out <= 4'b0110;
		end
		
		// (-0.9238795, 0.3826834)
		else if({re_in, im_in} == {`NEG_0_9239, `POS_0_3827}) begin
			out <= 4'b0111;
		end
		
		// (-1, 0)
		else if({re_in, im_in} == {`NEG_ONE, `ZERO}) begin
			out <= 4'b1000;
		end
		
		// (-0.9238795, -0.3826834)
		else if({re_in, im_in} == {`NEG_0_9239, `NEG_0_3827}) begin
			out <= 4'b1001;
		end
		
		// (-0.7071068, -0.7071068)
		else if({re_in, im_in} == {`NEG_0_7071, `NEG_0_7071}) begin
			out <= 4'b1010;
		end
		
		// (-0.3826834, -0.9238795)
		else if({re_in, im_in} == {`NEG_0_3827, `NEG_0_9239}) begin
			out <= 4'b1011;
		end
		
		// (0, -1)
		else if({re_in, im_in} == {`ZERO, `NEG_ONE}) begin
			out <= 4'b1100;
		end
		
		// (0.3826834, -0.9238795)
		else if({re_in, im_in} == {`POS_0_3827, `NEG_0_9239}) begin
			out <= 4'b1101;
		end
		
		// (0.7071068, -0.7071068)
		else if({re_in, im_in} == {`POS_0_7071, `NEG_0_7071}) begin
			out <= 4'b1110;
		end
		
		// (0.9238795, -0.3826834)
		else if({re_in, im_in} == {`POS_0_9239, `NEG_0_3827}) begin
			out <= 4'b1111;
		end
		
		else begin
			out <= 4'bxxxx;
		end
	end
endmodule
