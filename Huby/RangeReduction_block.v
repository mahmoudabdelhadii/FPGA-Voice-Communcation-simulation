// -------------------------------------------------------------
// 
// File Name: C:\Users\huber\Downloads\hdlsrc\HDLAWGNGenerator\HDLAWGNGenerator\RangeReduction_block.v
// Created: 2021-06-06 18:19:43
// 
// Generated by MATLAB 9.10 and HDL Coder 3.18
// 
// -------------------------------------------------------------


// -------------------------------------------------------------
// 
// Module: RangeReduction_block
// Source Path: HDLAWGNGenerator/AWGNGenerator/GaussianNoiseWithUnitVar/logImplementation/log/RangeReduction
// Hierarchy Level: 4
// 
// -------------------------------------------------------------

`timescale 1 ns / 1 ns

module RangeReduction_block
          (clk,
           reset,
           enb,
           x,
           x_e,
           exp_e);


  input   clk;
  input   reset;
  input   enb;
  input   [47:0] x;  // ufix48_En48
  output  [48:0] x_e;  // ufix49_En48
  output  [7:0] exp_e;  // uint8


  reg [47:0] Delay_reg [0:2];  // ufix48 [3]
  wire [47:0] Delay_reg_next [0:2];  // ufix48_En48 [3]
  wire [47:0] Delay_out1;  // ufix48_En48
  reg [47:0] Delay1_out1;  // ufix48_En48
  wire [7:0] exp_e_1;  // uint8
  reg [7:0] Delay2_reg [0:1];  // ufix8 [2]
  wire [7:0] Delay2_reg_next [0:1];  // ufix8 [2]
  wire [7:0] Delay2_out1;  // uint8
  wire [47:0] x_e_1;  // ufix48_En48
  wire [7:0] Constant_out1;  // uint8
  wire [55:0] Add_add_cast;  // ufix56_En48
  wire [55:0] Add_add_cast_1;  // ufix56_En48
  wire [55:0] Add_add_temp;  // ufix56_En48
  wire [48:0] Add_out1;  // ufix49_En48

  // Range of x_e=[1,2)


  always @(posedge clk or posedge reset)
    begin : Delay_process
      if (reset == 1'b1) begin
        Delay_reg[0] <= 48'h000000000000;
        Delay_reg[1] <= 48'h000000000000;
        Delay_reg[2] <= 48'h000000000000;
      end
      else begin
        if (enb) begin
          Delay_reg[0] <= Delay_reg_next[0];
          Delay_reg[1] <= Delay_reg_next[1];
          Delay_reg[2] <= Delay_reg_next[2];
        end
      end
    end

  assign Delay_out1 = Delay_reg[2];
  assign Delay_reg_next[0] = x;
  assign Delay_reg_next[1] = Delay_reg[0];
  assign Delay_reg_next[2] = Delay_reg[1];



  always @(posedge clk or posedge reset)
    begin : Delay1_process
      if (reset == 1'b1) begin
        Delay1_out1 <= 48'h000000000000;
      end
      else begin
        if (enb) begin
          Delay1_out1 <= x;
        end
      end
    end



  MATLAB_Function_block u_MATLAB_Function (.x(Delay1_out1),  // ufix48_En48
                                           .exp_e(exp_e_1)  // uint8
                                           );

  always @(posedge clk or posedge reset)
    begin : Delay2_process
      if (reset == 1'b1) begin
        Delay2_reg[0] <= 8'b00000000;
        Delay2_reg[1] <= 8'b00000000;
      end
      else begin
        if (enb) begin
          Delay2_reg[0] <= Delay2_reg_next[0];
          Delay2_reg[1] <= Delay2_reg_next[1];
        end
      end
    end

  assign Delay2_out1 = Delay2_reg[1];
  assign Delay2_reg_next[0] = exp_e_1;
  assign Delay2_reg_next[1] = Delay2_reg[0];



  assign x_e_1 = Delay_out1 <<< Delay2_out1;



  assign Constant_out1 = 8'b00000001;



  assign Add_add_cast = {8'b0, x_e_1};
  assign Add_add_cast_1 = {Constant_out1, 48'b000000000000000000000000000000000000000000000000};
  assign Add_add_temp = Add_add_cast + Add_add_cast_1;
  assign Add_out1 = Add_add_temp[48:0];



  assign x_e = Add_out1;

  assign exp_e = Delay2_out1;

endmodule  // RangeReduction_block

