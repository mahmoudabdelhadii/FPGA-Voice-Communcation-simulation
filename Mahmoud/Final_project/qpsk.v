// - Phase states using Binary constellation ordering:
//		(00)	->	45 deg	= pi/4 rad		->	(1/sqrt(2), 1/sqrt(2))		~=	(0.7071068, 0.7071068)
//		(01)	->	135 deg	= 3*pi/4 rad	->	(-1/sqrt(2), 1/sqrt(2))		~=	(-0.7071068, 0.7071068)
//		(10)	->	225 deg	= 5*pi/4 rad	->	(-1/sqrt(2), -1/sqrt(2))	~=	(-0.7071068, -0.7071068)
//		(11)	->	315 deg	= 7*pi/4 rad	->	(1/sqrt(2), -1/sqrt(2))		~=	(0.7071068, -0.7071068)
// Note: floating point values are approximated to 7 decimal digits of precision

// Single precision fixed point (IEEE-754) format:
// {sign[0], exponent[7:0], mantissa[22:0]} => 32 bits in total
`define POS_0_7071	32'b0_01111110_01101010000010011110100		// 0.7071068
`define NEG_0_7071	32'b1_01111110_01101010000010011110100		// -0.7071068

// Note: Euclidean distance of QPSK, d_4 ~= sqrt(2) ~= 1.4142136
// 		-> error tolerance should be (d_4 / 2) ~= 0.7071068
// Lower bounds:
`define POS_0_7071_LOW	32'b0_00000000_00000000000000000000000	// 0.7071068 - (d_4 / 2)	= 0.0000000
`define NEG_0_7071_LOW	32'b1_01111111_01101010000010011110100	// -0.7071068 - (d_4 / 2)	= -1.4142136
// Higher bounds:
`define POS_0_7071_HIGH	32'b0_01111111_01101010000010011110100	// 0.7071068 + (d_4 / 2)	= 1.4142136
`define NEG_0_7071_HIGH	32'b0_00000000_00000000000000000000000	// -0.7071068 + (d_4 / 2)	= 0.0000000

module qpsk_mod(clk, in, re_out, im_out);
	input clk;
	input signed [1:0] in;
	output reg signed [31:0] re_out, im_out;
	
	// Break inbound message down into 2-bit segments, then map each segment as complex (Re, Im) 
	always @* begin : Modulate
		case (in)
			{2'b00}:	{re_out, im_out} <= {`POS_0_7071, `POS_0_7071};	// (0.7071068, 0.7071068)
			{2'b01}:	{re_out, im_out} <= {`NEG_0_7071, `POS_0_7071};	// (-0.7071068, 0.7071068)
			{2'b10}:	{re_out, im_out} <= {`NEG_0_7071, `NEG_0_7071};	// (-0.7071068, -0.7071068)
			{2'b11}:	{re_out, im_out} <= {`POS_0_7071, `NEG_0_7071};	// (0.7071068, -0.7071068)
			default:	{re_out, im_out} <= {32'bx, 32'bx};
		endcase
	end
endmodule

module qpsk_demod(clk, re_in, im_in, out);
	input clk;
	input signed [31:0] re_in, im_in;
	output reg signed [1:0] out;
	
	/*
	// Check if inbound values fall within expected bounds, demodulate accordingly
	*/
	always @* begin : Demodulate
		// (0.7071068, 0.7071068)
		/*
		if ((re_in <= `POS_0_7071_HIGH) && (re_in >= `POS_0_7071_LOW)
					&& ((im_in <= `POS_0_7071_HIGH) && (im_in >= `POS_0_7071_LOW))) begin
		*/
		if ({re_in, im_in} == {`POS_0_7071, `POS_0_7071}) begin
			out <= 2'b00;
		end
			
		// (0.7071068, -0.7071068)
		/*
		else if (((re_in <= `POS_0_7071_HIGH) && (re_in >= `POS_0_7071_LOW))
					&& ((im_in <= `NEG_0_7071_HIGH) && (im_in >= `NEG_0_7071_LOW))) begin
		*/
		else if ({re_in, im_in} == {`POS_0_7071, `NEG_0_7071}) begin
			out <= 2'b11;
		end
			
		// (-0.7071068, 0.7071068)
		/*
		else if (((re_in <= `NEG_0_7071_HIGH) && (re_in >= `NEG_0_7071_LOW))
					&& ((im_in <= `POS_0_7071_HIGH) && (im_in >= `POS_0_7071_LOW))) begin
		*/
		else if ({re_in, im_in} == {`NEG_0_7071, `POS_0_7071}) begin
			out <= 2'b01;
		end
		
		// (-0.7071068, -0.7071068)
		/*
		else if (((re_in <= `NEG_0_7071_HIGH) && (re_in >= `NEG_0_7071_LOW))
					&& ((im_in <= `NEG_0_7071_HIGH) && (im_in >= `NEG_0_7071_LOW))) begin
		*/
		else if ({re_in, im_in} == {`NEG_0_7071, `NEG_0_7071}) begin
			out <= 2'b10;
		end
				
		else begin
			out <= 2'bxx;
		end
	end
endmodule
