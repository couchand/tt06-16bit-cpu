/*
 * Copyright (c) 2024 Andrew Dona-Couch
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module decoder (
    input  wire [15:0] inst,
    output wire [15:0] constval,
    output wire        inst_nop,
    output wire        inst_load,
    output wire        inst_add,
    output wire        inst_out_lo,
    output wire        inst_unknown,
    output wire        source_const
);

  wire zero_arg = (inst & 16'h8000) == 16'h0000;

  assign inst_nop = (inst >> 8) == 0;
  assign inst_out_lo = (inst >> 8) == 8;

  wire one_arg = (inst & 16'h8000) == 16'h8000;

  assign inst_load = (inst & 16'hFC00) == 16'h8000;
  assign inst_add  = (inst & 16'hFC00) == 16'h8400;

  assign inst_unknown = ~inst_nop & ~inst_load & ~inst_add & ~inst_out_lo;

  assign source_const = !one_arg ? 0 : (inst & 16'h0200) == 0;
  assign constval = !source_const ? 0
    : (inst & 16'h0300) == 16'h0000 ? {8'h00, inst[7:0]}
    : (inst & 16'h0300) == 16'h0100 ? {inst[7:0], 8'h00}
    : 0;

endmodule
