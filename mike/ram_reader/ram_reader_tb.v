
//Simple clock cycle test bench. 
module ram_reader_tb;
 reg clk;
   ram_reader U0( .clk (clk), .done (done), .out ());
   
   initial begin
     clk = 0;	
   end

   always 
     #5
     clk = !clk;	
endmodule
