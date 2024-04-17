/*
 * Copyright (c) 2024 Andrew Dona-Couch
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module decoder (
    input  wire        en,
    input  wire [15:0] inst,
    input  wire [7:0]  data,
    output wire [15:0] rhs,
    output wire        inst_nop,
    output wire        inst_load,
    output wire        inst_store,
    output wire        inst_add,
    output wire        inst_sub,
    output wire        inst_and,
    output wire        inst_or,
    output wire        inst_xor,
    output wire        inst_branch,
    output wire        inst_if,
    output wire        inst_out_lo,
    output wire        source_imm,
    output wire        source_ram,
    output wire        if_zero,
    output wire        if_not_zero,
    output wire        if_else,
    output wire        if_not_else
);

  wire zero_arg = en & ((inst & 16'h8000) == 16'h0000);

  assign inst_nop = en & ((inst >> 8) == 0);
  assign inst_out_lo = en & ((inst >> 8) == 8);

  wire one_arg = en & ((inst & 16'hC000) == 16'h8000);

  assign inst_load = en & ((inst & 16'hF800) == 16'h8000);
  assign inst_store = en & ((inst & 16'hF800) == 16'h9000);
  assign inst_add  = en & ((inst & 16'hF800) == 16'h8800);
  assign inst_sub  = en & ((inst & 16'hF800) == 16'h9800);
  assign inst_and  = en & ((inst & 16'hF800) == 16'hA000);
  assign inst_or   = en & ((inst & 16'hF800) == 16'hA800);
  assign inst_xor  = en & ((inst & 16'hF800) == 16'hB000);

  assign inst_branch = en & ((inst & 16'hF800) == 16'hC000);
  assign inst_if = en & ((inst & 16'hF800) == 16'hF000);

  wire source_const = !one_arg ? 0 : (inst & 16'h0600) == 16'h0000;
  wire source_data  = !one_arg ? 0 : (inst & 16'h0600) == 16'h0200;

  assign source_imm = source_const | source_data;
  assign source_ram = !one_arg ? 0 : (inst & 16'h0400) == 16'h0400;

  assign rhs = !en ? 0
    : inst_branch ? {{5{inst[10]}}, inst[10:0]}
    : (inst & 16'h0700) == 16'h0000 ? {8'h00, inst[7:0]}
    : (inst & 16'h0700) == 16'h0100 ? {inst[7:0], 8'h00}
    : (inst & 16'h0700) == 16'h0200 ? {8'h00, data}
    : (inst & 16'h0700) == 16'h0300 ? {data, 8'h00}
    : (inst & 16'h0700) == 16'h0400 ? {8'h00, inst[7:0]}
    : 0;

  assign if_zero = !inst_if ? 0
    : (inst & 16'h07FF) == 16'h0000;
  assign if_not_zero = !inst_if ? 0
    : (inst & 16'h07FF) == 16'h0001;
  assign if_else = !inst_if ? 0
    : (inst & 16'h07FF) == 16'h0010;
  assign if_not_else = !inst_if ? 0
    : (inst & 16'h07FF) == 16'h0011;

endmodule
