`timescale 10 ps/ 1 ps 

module multpathandattenuation (in, out);

input signed [7:0] in;
output signed [7:0] out;

wire signed [7:0] multipathout;

MISOmultipath multipath ( .pathone(in), .pathtwo(in), .out(multipathout));

assign out = multipathout >>> 2'b1; //attenuate overall multipath channel due to free space


endmodule



module MISOmultipath ( pathone, pathtwo, out);


input signed [7:0] pathone, pathtwo; //could be signed
output signed  [7:0] out; //could be signed
wire signed  [7:0] attenuatedpathone, attenuatedpathtwo; //could be signed
// specify block containing delay statements
specify 

( pathone => out ) = 1;   // delay from pathone to output
( pathtwo => out ) = 2;   // delay from pathtwo to output 

endspecify

// module definition
assign attenuatedpathone = pathone >>> 2'b1; //both paths attenuated by 0.5
assign attenuatedpathtwo = pathtwo >>> 2'b1;

assign out = attenuatedpathone  + attenuatedpathtwo;


endmodule
