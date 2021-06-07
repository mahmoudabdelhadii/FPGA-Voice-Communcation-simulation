`timescale 1 ps / 1 ps
  module RS_dec_rs_decoder_dec_syn (
    input    [7:0] cw_in_numn,
    input    [5:0] cw_in_numcheck,
    output   [7:0] syn_out_numn,
    output   [5:0] syn_out_numcheck,
    output   [5:0] syn_out_eracnt,
    output [255:0] syn_out_erapos,
    output         syn_out_valid,
    input          rst,
    input          cw_in_sop,
    input          cw_in_eop,
    output         cw_in_ready,
    output [255:0] syn_out_synd,
    input          cw_in_erasure,
    input          cw_in_valid,
    input          cw_in_channel,
    input    [7:0] cw_in_data,
    input          clk,
    output         syn_out_sop,
    output         syn_out_eop,
    input          syn_out_ready);

    parameter ERASURE       = 0;
    parameter CHANNEL       = 1;
    parameter BITSPERSYMBOL = 8;
    parameter CHECK         = 32;
    parameter IRRPOL        = 285;
    parameter N             = 255;
    parameter VARCHECK      = 0;
    parameter VARN          = 0;
    parameter GENSTART      = 4;
    parameter ROOTSPACE     = 1;
    parameter MIN_N         = 3;
    parameter USENUMN       = 0;
    parameter USEDUALBASIS  = 0;

altera_rs_ser_syn #(
    .ERASURE         (ERASURE),
    .CHANNEL         (CHANNEL),
    .BITSPERSYMBOL   (BITSPERSYMBOL),
    .CHECK           (CHECK),
    .IRRPOL          (IRRPOL),
    .N               (N),
    .VARCHECK        (VARCHECK),
    .VARN            (VARN),
    .GENSTART        (GENSTART),
    .ROOTSPACE       (ROOTSPACE),
    .MIN_N           (MIN_N),
    .USENUMN         (USENUMN),
    .USEDUALBASIS    (USEDUALBASIS),
    .ALPHA_FILE_NAME ("RS_dec_rs_decoder_dec_syn_alphas.hex")
) altera_rs_ser_syn (
    .cw_in_numn       (cw_in_numn),
    .cw_in_numcheck   (cw_in_numcheck),
    .syn_out_numn     (syn_out_numn),
    .syn_out_numcheck (syn_out_numcheck),
    .syn_out_eracnt   (syn_out_eracnt),
    .syn_out_erapos   (syn_out_erapos),
    .syn_out_valid    (syn_out_valid),
    .rst              (rst),
    .cw_in_sop        (cw_in_sop),
    .cw_in_eop        (cw_in_eop),
    .cw_in_ready      (cw_in_ready),
    .syn_out_synd     (syn_out_synd),
    .cw_in_erasure    (cw_in_erasure),
    .cw_in_valid      (cw_in_valid),
    .cw_in_channel    (cw_in_channel),
    .cw_in_data       (cw_in_data),
    .clk              (clk),
    .syn_out_sop      (syn_out_sop),
    .syn_out_eop      (syn_out_eop),
    .syn_out_ready    (syn_out_ready)
);

endmodule
