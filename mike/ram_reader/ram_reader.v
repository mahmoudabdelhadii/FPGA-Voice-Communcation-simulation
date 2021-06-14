module ram_reader(input clk, output reg done, output reg [7:0]out);
 //file handler
 integer file;

 //defining NULL
 `define NULL 0    

 initial begin
   $display("Reading Message from RAM");
   //opening file for reading.
   file = $fopen("test.txt", "r");
   //file error checking
   if (file == `NULL)
     begin
       $display("Data handle was NULL");
       $finish;
     end
   $display("File was opened successfully");
 end

 always @(posedge clk) begin
   //while we have not reached the end of the text file (feof).
   if (!$feof(file))
     begin
       //read one character at a time and output 8 bit ascii.
       out <= $fgetc(file);
       //displays the character read.
       $display("%0s", out);  
       //finished flag unraised
       done <= `NULL;
     end
   //when we've reached the end of the message.
   else 
     begin
       //output is set to 0 and the done flag is asserted.
       out <= `NULL;
       done <= 1'b1;
     end 
  end

endmodule
