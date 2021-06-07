`timescale 1 ps / 1 ps
  module RS_dec_rs_decoder_dec_bm (
    input    [7:0] syn_in_numn,
    input    [5:0] syn_in_numcheck,
    input    [5:0] syn_in_eracnt,
    input  [255:0] syn_in_erapos,
    output [127:0] bm_out_locrootini,
    output [127:0] bm_out_evalrootini,
    output   [7:0] bm_out_numn,
    input          rst,
    input          syn_in_sop,
    output [127:0] bm_out_error_locator,
    input          syn_in_eop,
    output         syn_in_ready,
    input  [255:0] syn_in_synd,
    input          syn_in_valid,
    output         bm_out_sop,
    output   [4:0] bm_out_error_count,
    output [127:0] bm_out_error_evaluator,
    output         bm_out_eop,
    input          clk,
    input          bm_out_ready,
    output         bm_out_valid);

    parameter ERASURE          = 0;
    parameter CHANNEL          = 1;
    parameter BITSPERSYMBOL    = 8;
    parameter CHECK            = 32;
    parameter IRRPOL           = 285;
    parameter N                = 255;
    parameter GENSTART         = 4;
    parameter ROOTSPACE        = 1;
    parameter VARCHECK         = 0;
    parameter VARN             = 0;
    parameter OPTIMIZE_LATENCY = 0;
    parameter MIN_N            = 3;
    parameter USEROM           = 0;
    parameter BMFIXEDLATENCY   = 1;

altera_rs_ser_bm #(
    .ERASURE          (ERASURE),
    .CHANNEL          (CHANNEL),
    .BITSPERSYMBOL    (BITSPERSYMBOL),
    .CHECK            (CHECK),
    .IRRPOL           (IRRPOL),
    .N                (N),
    .GENSTART         (GENSTART),
    .ROOTSPACE        (ROOTSPACE),
    .VARCHECK         (VARCHECK),
    .VARN             (VARN),
    .OPTIMIZE_LATENCY (OPTIMIZE_LATENCY),
    .MIN_N            (MIN_N),
    .USEROM           (USEROM),
    .BMFIXEDLATENCY   (BMFIXEDLATENCY),
    .INV_FILE_NAME    ("RS_dec_rs_decoder_dec_bm_inverse.hex")
) altera_rs_ser_bm (
    .syn_in_numn            (syn_in_numn),
    .syn_in_numcheck        (syn_in_numcheck),
    .syn_in_eracnt          (syn_in_eracnt),
    .syn_in_erapos          (syn_in_erapos),
    .bm_out_locrootini      (bm_out_locrootini),
    .bm_out_evalrootini     (bm_out_evalrootini),
    .bm_out_numn            (bm_out_numn),
    .rst                    (rst),
    .syn_in_sop             (syn_in_sop),
    .bm_out_error_locator   (bm_out_error_locator),
    .syn_in_eop             (syn_in_eop),
    .syn_in_ready           (syn_in_ready),
    .syn_in_synd            (syn_in_synd),
    .syn_in_valid           (syn_in_valid),
    .bm_out_sop             (bm_out_sop),
    .bm_out_error_count     (bm_out_error_count),
    .bm_out_error_evaluator (bm_out_error_evaluator),
    .bm_out_eop             (bm_out_eop),
    .clk                    (clk),
    .bm_out_ready           (bm_out_ready),
    .bm_out_valid           (bm_out_valid)
);

endmodule
