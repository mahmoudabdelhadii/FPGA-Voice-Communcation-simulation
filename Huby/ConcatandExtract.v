// -------------------------------------------------------------
// 
// File Name: C:\Users\huber\Downloads\hdlsrc\HDLAWGNGenerator\HDLAWGNGenerator\ConcatandExtract.v
// Created: 2021-06-06 18:19:42
// 
// Generated by MATLAB 9.10 and HDL Coder 3.18
// 
// -------------------------------------------------------------


// -------------------------------------------------------------
// 
// Module: ConcatandExtract
// Source Path: HDLAWGNGenerator/AWGNGenerator/GaussianNoiseWithUnitVar/TausUniformRandGen/ConcatandExtract
// Hierarchy Level: 3
// 
// -------------------------------------------------------------

`timescale 1 ns / 1 ns

module ConcatandExtract
          (a,
           b,
           u0_48_48,
           u1_16_16);


  input   [31:0] a;  // uint32
  input   [31:0] b;  // uint32
  output  [47:0] u0_48_48;  // ufix48_En48
  output  [15:0] u1_16_16;  // ufix16_En16


  wire [31:0] Shift_Arithmetic2_out1;  // uint32
  wire [15:0] Data_Type_Conversion_out1;  // uint16
  wire [47:0] u0_48_0;  // ufix48
  wire [31:0] bitMask_for_Bitwise_Operator;  // uint32
  wire [31:0] Bitwise_Operator_out1;  // uint32
  wire [15:0] Data_Type_Conversion2_out1;  // uint16
  wire [15:0] u0_16_16;  // ufix16_En16


  assign Shift_Arithmetic2_out1 = b >>> 8'd16;



  assign Data_Type_Conversion_out1 = Shift_Arithmetic2_out1[15:0];



  assign u0_48_0 = {a, Data_Type_Conversion_out1};



  assign u0_48_48 = u0_48_0;



  assign bitMask_for_Bitwise_Operator = 32'b00000000000000001111111111111111;



  assign Bitwise_Operator_out1 = b & bitMask_for_Bitwise_Operator;



  assign Data_Type_Conversion2_out1 = Bitwise_Operator_out1[15:0];



  assign u0_16_16 = Data_Type_Conversion2_out1;



  assign u1_16_16 = u0_16_16;

endmodule  // ConcatandExtract

