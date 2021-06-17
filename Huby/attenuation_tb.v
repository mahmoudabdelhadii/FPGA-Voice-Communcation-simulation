

`timescale 10 ps / 1 ps

module attenuation_tb;


reg signed [7:0] in;
wire signed [7:0] out;

 
multpathandattenuation attentest (.in(in), .out(out));


initial begin //initialize signals

	in = 0; 
	

end

initial begin

#15 in = 8'b01000000;
	 
end



initial begin

#15 in = 8'b01000011;

#15 in = 8'b00000110;
end

initial 
#30;
endmodule