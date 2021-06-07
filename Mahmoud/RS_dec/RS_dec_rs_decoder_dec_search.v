`timescale 1 ps / 1 ps
  module RS_dec_rs_decoder_dec_search (
    input  [127:0] bm_in_locrootini,
    input  [127:0] bm_in_evalrootini,
    input    [7:0] bm_in_numn,
    output         sch_out_eop,
    input          sch_out_ready,
    input          rst,
    input  [127:0] bm_in_error_locator,
    output   [7:0] sch_out_error_magnitude,
    output         sch_out_valid,
    output         sch_out_channel,
    output         sch_out_error,
    input          bm_in_sop,
    input    [4:0] bm_in_error_count,
    input          bm_in_eop,
    input  [127:0] bm_in_error_evaluator,
    output         bm_in_ready,
    input          clk,
    input          bm_in_valid,
    output         sch_out_error_location,
    output   [4:0] sch_out_error_count,
    output         sch_out_sop);

    parameter ERASURE          = 0;
    parameter CHANNEL          = 1;
    parameter BITSPERSYMBOL    = 8;
    parameter CHECK            = 32;
    parameter IRRPOL           = 285;
    parameter N                = 255;
    parameter GENSTART         = 4;
    parameter ROOTSPACE        = 1;
    parameter VARN             = 0;
    parameter OPTIMIZE_LATENCY = 0;
    parameter USEDUALBASIS     = 0;

altera_rs_ser_search #(
    .ERASURE          (ERASURE),
    .CHANNEL          (CHANNEL),
    .BITSPERSYMBOL    (BITSPERSYMBOL),
    .CHECK            (CHECK),
    .IRRPOL           (IRRPOL),
    .N                (N),
    .GENSTART         (GENSTART),
    .ROOTSPACE        (ROOTSPACE),
    .VARN             (VARN),
    .OPTIMIZE_LATENCY (OPTIMIZE_LATENCY),
    .USEDUALBASIS     (USEDUALBASIS),
    .ALPHA_FILE_NAME  ("RS_dec_rs_decoder_dec_search_alphas.hex"),
    .INV_FILE_NAME    ("RS_dec_rs_decoder_dec_search_inverse.hex")
) altera_rs_ser_search (
    .bm_in_locrootini        (bm_in_locrootini),
    .bm_in_evalrootini       (bm_in_evalrootini),
    .bm_in_numn              (bm_in_numn),
    .sch_out_eop             (sch_out_eop),
    .sch_out_ready           (sch_out_ready),
    .rst                     (rst),
    .bm_in_error_locator     (bm_in_error_locator),
    .sch_out_error_magnitude (sch_out_error_magnitude),
    .sch_out_valid           (sch_out_valid),
    .sch_out_channel         (sch_out_channel),
    .sch_out_error           (sch_out_error),
    .bm_in_sop               (bm_in_sop),
    .bm_in_error_count       (bm_in_error_count),
    .bm_in_eop               (bm_in_eop),
    .bm_in_error_evaluator   (bm_in_error_evaluator),
    .bm_in_ready             (bm_in_ready),
    .clk                     (clk),
    .bm_in_valid             (bm_in_valid),
    .sch_out_error_location  (sch_out_error_location),
    .sch_out_error_count     (sch_out_error_count),
    .sch_out_sop             (sch_out_sop)
);

endmodule
