/*
 * Copyright (c) 2024 Andrew Dona-Couch
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module decoder (
    input  wire [15:0] inst,
    input  wire [7:0]  data,
    output wire [15:0] rhs,
    output wire        inst_nop,
    output wire        inst_load,
    output wire        inst_add,
    output wire        inst_out_lo,
    output wire        inst_unknown,
    output wire        source_imm,
    output wire        source_ram
);

  wire zero_arg = (inst & 16'h8000) == 16'h0000;

  assign inst_nop = (inst >> 8) == 0;
  assign inst_out_lo = (inst >> 8) == 8;

  wire one_arg = (inst & 16'h8000) == 16'h8000;

  assign inst_load = (inst & 16'hF800) == 16'h8000;
  assign inst_add  = (inst & 16'hF800) == 16'h8800;

  assign inst_unknown = ~inst_nop & ~inst_load & ~inst_add & ~inst_out_lo;

  wire source_const = !one_arg ? 0 : (inst & 16'h0600) == 16'h0000;
  wire source_data  = !one_arg ? 0 : (inst & 16'h0600) == 16'h0200;

  assign source_imm = source_const | source_data;
  assign source_ram = !one_arg ? 0 : (inst & 16'h0600) == 16'h0400;

  assign rhs = !one_arg ? 0
    : (inst & 16'h0700) == 16'h0000 ? {8'h00, inst[7:0]}
    : (inst & 16'h0700) == 16'h0100 ? {inst[7:0], 8'h00}
    : (inst & 16'h0700) == 16'h0200 ? {8'h00, data}
    : (inst & 16'h0700) == 16'h0300 ? {data, 8'h00}
    : 0;

endmodule
