`timescale 1 ps / 1 ps
  module Rs_enc_rs_encoder (
    input  [7:0] data,
    input  [5:0] numcheck,
    output [7:0] out_data,
    input        rst,
    input        in_endofpacket,
    output       in_ready,
    output       out_endofpacket,
    input        out_ready,
    input        in_valid,
    input        in_channel,
    output       out_valid,
    output       out_channel,
    input        in_startofpacket,
    input        clk,
    output       out_startofpacket);

    parameter CHANNEL       = 1;
    parameter BITSPERSYMBOL = 8;
    parameter CHECK         = 32;
    parameter IRRPOL        = 285;
    parameter USEDUALBASIS  = 0;
    parameter GENSTART      = 4;
    parameter ROOTSPACE     = 1;
    parameter VARCHECK      = 0;
    parameter MINCHECK      = 2;

altera_rs_ser_enc #(
    .CHANNEL         (CHANNEL),
    .BITSPERSYMBOL   (BITSPERSYMBOL),
    .CHECK           (CHECK),
    .IRRPOL          (IRRPOL),
    .USEDUALBASIS    (USEDUALBASIS),
    .GENSTART        (GENSTART),
    .ROOTSPACE       (ROOTSPACE),
    .VARCHECK        (VARCHECK),
    .MINCHECK        (MINCHECK),
    .ALPHA_FILE_NAME ("Rs_enc_rs_encoder_alphas.hex")
) altera_rs_ser_enc (
    .data              (data),
    .numcheck          (numcheck),
    .out_data          (out_data),
    .rst               (rst),
    .in_endofpacket    (in_endofpacket),
    .in_ready          (in_ready),
    .out_endofpacket   (out_endofpacket),
    .out_ready         (out_ready),
    .in_valid          (in_valid),
    .in_channel        (in_channel),
    .out_valid         (out_valid),
    .out_channel       (out_channel),
    .in_startofpacket  (in_startofpacket),
    .clk               (clk),
    .out_startofpacket (out_startofpacket)
);

endmodule
