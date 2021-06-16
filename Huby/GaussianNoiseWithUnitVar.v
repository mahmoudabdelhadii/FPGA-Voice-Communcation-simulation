// -------------------------------------------------------------
// 
// File Name: C:\Users\huber\Downloads\hdlsrc\HDLAWGNGenerator\HDLAWGNGenerator\GaussianNoiseWithUnitVar.v
// Created: 2021-06-06 18:19:43
// 
// Generated by MATLAB 9.10 and HDL Coder 3.18
// 
// -------------------------------------------------------------


// -------------------------------------------------------------
// 
// Module: GaussianNoiseWithUnitVar
// Source Path: HDLAWGNGenerator/AWGNGenerator/GaussianNoiseWithUnitVar
// Hierarchy Level: 1
// 
// -------------------------------------------------------------

`timescale 1 ns / 1 ns

module GaussianNoiseWithUnitVar
          (clk,
           reset,
           enb,
           x0,
           x1);


  input   clk;
  input   reset;
  input   enb;
  output  signed [15:0] x0;  // sfix16_En11
  output  signed [15:0] x1;  // sfix16_En11


  wire [47:0] u0_48_48;  // ufix48_En48
  wire [15:0] u0_16_16;  // ufix16_En16
  reg [47:0] Delay_out1;  // ufix48_En48
  wire [30:0] logImplementation_out1;  // ufix31_En24
  reg [30:0] Delay1_reg [0:4];  // ufix31 [5]
  wire [30:0] Delay1_reg_next [0:4];  // ufix31_En24 [5]
  wire [30:0] Delay1_out1;  // ufix31_En24
  wire [16:0] SqrtImplementation_out1;  // ufix17_En13
  reg [15:0] Delay2_out1;  // ufix16_En16
  wire signed [15:0] SinCos_out1;  // sfix16_En15
  wire signed [15:0] SinCos_out2;  // sfix16_En15
  reg signed [15:0] Delay31_reg [0:5];  // sfix16 [6]
  wire signed [15:0] Delay31_reg_next [0:5];  // sfix16_En15 [6]
  wire signed [15:0] Delay31_out1;  // sfix16_En15
  reg signed [15:0] Delay23_reg [0:1];  // sfix16 [2]
  wire signed [15:0] Delay23_reg_next [0:1];  // sfix16_En15 [2]
  wire signed [15:0] Delay23_out1;  // sfix16_En15
  wire signed [17:0] Product_cast;  // sfix18_En13
  wire signed [33:0] Product_mul_temp;  // sfix34_En28
  wire signed [32:0] x0_16_11;  // sfix33_En28
  wire signed [15:0] x0_16_11_1;  // sfix16_En11
  reg signed [15:0] Delay33_reg [0:5];  // sfix16 [6]
  wire signed [15:0] Delay33_reg_next [0:5];  // sfix16_En15 [6]
  wire signed [15:0] Delay33_out1;  // sfix16_En15
  reg signed [15:0] Delay24_reg [0:1];  // sfix16 [2]
  wire signed [15:0] Delay24_reg_next [0:1];  // sfix16_En15 [2]
  wire signed [15:0] Delay24_out1;  // sfix16_En15
  wire signed [17:0] Product1_cast;  // sfix18_En13
  wire signed [33:0] Product1_mul_temp;  // sfix34_En28
  wire signed [32:0] x1_16_11;  // sfix33_En28
  wire signed [15:0] x1_16_11_1;  // sfix16_En11


  TausUniformRandGen u_TausUniformRandGen (.clk(clk),
                                           .reset(reset),
                                           .enb(enb),
                                           .u0_16_16(u0_48_48),  // ufix48_En48
                                           .u1_16_16(u0_16_16)  // ufix16_En16
                                           );

  always @(posedge clk or posedge reset)
    begin : Delay_process
      if (reset == 1'b1) begin
        Delay_out1 <= 48'h000000000000;
      end
      else begin
        if (enb) begin
          Delay_out1 <= u0_48_48;
        end
      end
    end



  logImplementation u_logImplementation (.clk(clk),
                                         .reset(reset),
                                         .enb(enb),
                                         .u0_48_48(Delay_out1),  // ufix48_En48
                                         .e(logImplementation_out1)  // ufix31_En24
                                         );

  always @(posedge clk or posedge reset)
    begin : Delay1_process
      if (reset == 1'b1) begin
        Delay1_reg[0] <= 31'b0000000000000000000000000000000;
        Delay1_reg[1] <= 31'b0000000000000000000000000000000;
        Delay1_reg[2] <= 31'b0000000000000000000000000000000;
        Delay1_reg[3] <= 31'b0000000000000000000000000000000;
        Delay1_reg[4] <= 31'b0000000000000000000000000000000;
      end
      else begin
        if (enb) begin
          Delay1_reg[0] <= Delay1_reg_next[0];
          Delay1_reg[1] <= Delay1_reg_next[1];
          Delay1_reg[2] <= Delay1_reg_next[2];
          Delay1_reg[3] <= Delay1_reg_next[3];
          Delay1_reg[4] <= Delay1_reg_next[4];
        end
      end
    end

  assign Delay1_out1 = Delay1_reg[4];
  assign Delay1_reg_next[0] = logImplementation_out1;
  assign Delay1_reg_next[1] = Delay1_reg[0];
  assign Delay1_reg_next[2] = Delay1_reg[1];
  assign Delay1_reg_next[3] = Delay1_reg[2];
  assign Delay1_reg_next[4] = Delay1_reg[3];



  SqrtImplementation u_SqrtImplementation (.clk(clk),
                                           .reset(reset),
                                           .enb(enb),
                                           .u(Delay1_out1),  // ufix31_En24
                                           .f(SqrtImplementation_out1)  // ufix17_En13
                                           );

  always @(posedge clk or posedge reset)
    begin : Delay2_process
      if (reset == 1'b1) begin
        Delay2_out1 <= 16'b0000000000000000;
      end
      else begin
        if (enb) begin
          Delay2_out1 <= u0_16_16;
        end
      end
    end



  SinCos u_SinCos (.clk(clk),
                   .reset(reset),
                   .enb(enb),
                   .u1(Delay2_out1),  // ufix16_En16
                   .g0(SinCos_out1),  // sfix16_En15
                   .g1_16_15(SinCos_out2)  // sfix16_En15
                   );

  always @(posedge clk or posedge reset)
    begin : Delay31_process
      if (reset == 1'b1) begin
        Delay31_reg[0] <= 16'sb0000000000000000;
        Delay31_reg[1] <= 16'sb0000000000000000;
        Delay31_reg[2] <= 16'sb0000000000000000;
        Delay31_reg[3] <= 16'sb0000000000000000;
        Delay31_reg[4] <= 16'sb0000000000000000;
        Delay31_reg[5] <= 16'sb0000000000000000;
      end
      else begin
        if (enb) begin
          Delay31_reg[0] <= Delay31_reg_next[0];
          Delay31_reg[1] <= Delay31_reg_next[1];
          Delay31_reg[2] <= Delay31_reg_next[2];
          Delay31_reg[3] <= Delay31_reg_next[3];
          Delay31_reg[4] <= Delay31_reg_next[4];
          Delay31_reg[5] <= Delay31_reg_next[5];
        end
      end
    end

  assign Delay31_out1 = Delay31_reg[5];
  assign Delay31_reg_next[0] = SinCos_out1;
  assign Delay31_reg_next[1] = Delay31_reg[0];
  assign Delay31_reg_next[2] = Delay31_reg[1];
  assign Delay31_reg_next[3] = Delay31_reg[2];
  assign Delay31_reg_next[4] = Delay31_reg[3];
  assign Delay31_reg_next[5] = Delay31_reg[4];



  always @(posedge clk or posedge reset)
    begin : Delay23_process
      if (reset == 1'b1) begin
        Delay23_reg[0] <= 16'sb0000000000000000;
        Delay23_reg[1] <= 16'sb0000000000000000;
      end
      else begin
        if (enb) begin
          Delay23_reg[0] <= Delay23_reg_next[0];
          Delay23_reg[1] <= Delay23_reg_next[1];
        end
      end
    end

  assign Delay23_out1 = Delay23_reg[1];
  assign Delay23_reg_next[0] = Delay31_out1;
  assign Delay23_reg_next[1] = Delay23_reg[0];



  assign Product_cast = {1'b0, SqrtImplementation_out1};
  assign Product_mul_temp = Product_cast * Delay23_out1;
  assign x0_16_11 = Product_mul_temp[32:0];



  assign x0_16_11_1 = x0_16_11[32:17];



  assign x0 = x0_16_11_1;

  always @(posedge clk or posedge reset)
    begin : Delay33_process
      if (reset == 1'b1) begin
        Delay33_reg[0] <= 16'sb0000000000000000;
        Delay33_reg[1] <= 16'sb0000000000000000;
        Delay33_reg[2] <= 16'sb0000000000000000;
        Delay33_reg[3] <= 16'sb0000000000000000;
        Delay33_reg[4] <= 16'sb0000000000000000;
        Delay33_reg[5] <= 16'sb0000000000000000;
      end
      else begin
        if (enb) begin
          Delay33_reg[0] <= Delay33_reg_next[0];
          Delay33_reg[1] <= Delay33_reg_next[1];
          Delay33_reg[2] <= Delay33_reg_next[2];
          Delay33_reg[3] <= Delay33_reg_next[3];
          Delay33_reg[4] <= Delay33_reg_next[4];
          Delay33_reg[5] <= Delay33_reg_next[5];
        end
      end
    end

  assign Delay33_out1 = Delay33_reg[5];
  assign Delay33_reg_next[0] = SinCos_out2;
  assign Delay33_reg_next[1] = Delay33_reg[0];
  assign Delay33_reg_next[2] = Delay33_reg[1];
  assign Delay33_reg_next[3] = Delay33_reg[2];
  assign Delay33_reg_next[4] = Delay33_reg[3];
  assign Delay33_reg_next[5] = Delay33_reg[4];



  always @(posedge clk or posedge reset)
    begin : Delay24_process
      if (reset == 1'b1) begin
        Delay24_reg[0] <= 16'sb0000000000000000;
        Delay24_reg[1] <= 16'sb0000000000000000;
      end
      else begin
        if (enb) begin
          Delay24_reg[0] <= Delay24_reg_next[0];
          Delay24_reg[1] <= Delay24_reg_next[1];
        end
      end
    end

  assign Delay24_out1 = Delay24_reg[1];
  assign Delay24_reg_next[0] = Delay33_out1;
  assign Delay24_reg_next[1] = Delay24_reg[0];



  assign Product1_cast = {1'b0, SqrtImplementation_out1};
  assign Product1_mul_temp = Product1_cast * Delay24_out1;
  assign x1_16_11 = Product1_mul_temp[32:0];



  assign x1_16_11_1 = x1_16_11[32:17];



  assign x1 = x1_16_11_1;

endmodule  // GaussianNoiseWithUnitVar
