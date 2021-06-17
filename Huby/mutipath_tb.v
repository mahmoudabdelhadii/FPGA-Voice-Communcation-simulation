

`timescale 10 ps / 1 ps

module multipath_tb;


reg signed [7:0] pathone, pathtwo;
wire signed [7:0] out;

 

MISOmultipath multipathtest ( .pathone(pathone), .pathtwo(pathtwo), .out(out));


initial begin //initialize signals

	pathone = 0; 
	pathtwo = 0;

end

initial begin
#15 pathone =8'b01111111;
	 pathtwo =8'b01111111;
	 
end



initial begin

#15 pathone =8'b01010101;
	 pathtwo =8'b01010101;

#15 pathone =8'b01100011;
	 pathtwo =8'b01100011;
end

initial 
#30;
endmodule

