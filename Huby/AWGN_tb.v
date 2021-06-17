

`timescale 1 ps / 1 ps

module AWGN_tb;


reg  clk;
reg   reset;
reg  clk_enable;
reg   signed [15:0] snrdB;  // sfix16_En9
wire ce_out;
wire signed [37:0] awgn_re;  // sfix38_En29
wire signed [37:0] awgn_im;  // sfix38_En29
wire valid;

 

AWGNGenerator thenoisegen
          (.clk(clk),
           .reset(reset),
           .clk_enable(clk_enable),
           .snrdB(snrdB),
           .ce_out(ce_out),
           .awgn_re(awgn_re),
           .awgn_im(awgn_im),
           .valid(valid));


initial begin //initialize signals

	clk=0; 
	reset=1;
	clk_enable=0;
	snrdB = 16'b0;
end
initial begin
#15 reset=0;
	clk_enable=1;
end

//define clock
always
begin
#10 clk = !clk;
end

initial begin

#100 snrdB = 16'b0101001101101111;

#100 snrdB = 16'b1;

#100 snrdB = 16'b0111111111111111;

#100 snrdB = 16'b110101;

#100 snrdB = 16'b0;

end

initial 
#2000;
endmodule






