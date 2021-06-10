`timescale 1 ns / 1 ps
`default_nettype none
module addressfsm (
    clock, 
    reset, 
	 start,
	 pause,
    fetchaddressenable,
    address_out, 
    addressready
    );
   // input logic new_phoneme_select;
    input logic clock; 
    input logic reset;
    input logic fetchaddressenable;
	 input logic start;
	  input logic pause;
    output logic[23:0] address_out;
    output logic addressready;
    

   
        
        logic [1:0] state=2'b0;
        logic [23:0] nextaddress = 24'h0;
        logic send, next;
        //max and min address definitions
        parameter MAXADDRESS = 24'h7FFFF;
        parameter STARTADDRESS = 24'h0;
        //state parameters, simple so I did not do outputs from states
        parameter idle = 2'b00;
        parameter send_address = 2'b01;
        parameter next1 = 2'b10;
        parameter ready = 2'b11;
        
        
    
        always_ff @(posedge clock, posedge reset) begin
            if(reset)
                state = idle;                        
            else
                case (state)                         
                    idle: begin
                            send <=1'b0; 
                            next <=1'b0; 
                            addressready <=1'b0; 
                            if (fetchaddressenable)
                            state <= send_address;   
                                else
                            state <= idle;
                    end
                send_address :begin state <= next1;       
                                    send <=1'b1;
                end
                next1: begin state <= ready;               
                            send <= 1'b0;
                            next <= 1'b1;
                end
                ready:begin state <= idle;  
                            addressready<= 1'b1;
                            next <=1'b0;              
                end
            endcase                                  
        end                                          


        always_ff @(posedge send)  //asserted in the send state of fsm
        address_out <= nextaddress;

    
    always_ff @(posedge next, posedge reset) begin  //asserted in the next state in fsm
      if (reset)
            nextaddress <= STARTADDRESS;

            else                        
            begin
                 if (address_out == MAXADDRESS)
                     nextaddress <= STARTADDRESS;   //if address reaches the end, wrap around to the start

                 else
                      nextaddress <= nextaddress + 24'h1;  // adds one to current address
            end
  
         
      end    
endmodule 
