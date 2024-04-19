/*
 * Copyright (c) 2024 Andrew Dona-Couch
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module decoder (
    input  wire        en,
    input  wire [15:0] inst,
    input  wire [15:0] accum,
    input  wire [7:0]  data,
    output wire [15:0] rhs,
    output wire [1:0]  bytes,
    output wire        inst_nop,
    output wire        inst_halt,
    output wire        inst_trap,
    output wire        inst_load,
    output wire        inst_store,
    output wire        inst_add,
    output wire        inst_sub,
    output wire        inst_and,
    output wire        inst_or,
    output wire        inst_xor,
    output wire        inst_shl,
    output wire        inst_shr,
    output wire        inst_not,
    output wire        inst_branch,
    output wire        inst_call,
    output wire        inst_if,
    output wire        inst_push,
    output wire        inst_pop,
    output wire        inst_drop,
    output wire        inst_return,
    output wire        inst_out_lo,
    output wire        inst_out_hi,
    output wire        inst_set_dp,
    output wire        inst_test,
    output wire        inst_status,
    output wire        inst_call_word,
    output wire        inst_load_word,
    output wire        source_imm,
    output wire        source_ram,
    output wire        source_indirect,
    output wire        relative_data,
    output wire        relative_stack,
    output wire        if_zero,
    output wire        if_not_zero,
    output wire        if_else,
    output wire        if_not_else,
    output wire        if_neg,
    output wire        if_not_neg,
    output wire        if_carry,
    output wire        if_not_carry
);

  wire zero_arg = en & ((inst & 16'h8000) == 16'h0000);

  assign inst_nop = en & ((inst >> 8) == 16'h0000);
  assign inst_halt = en & ((inst >> 8) == 16'h0001);
  assign inst_trap = en & ((inst >> 8) == 16'h0002);
  assign inst_drop = en & ((inst >> 8) == 16'h0003);
  assign inst_push = en & ((inst >> 8) == 16'h0004);
  assign inst_pop = en & ((inst >> 8) == 16'h0005);
  assign inst_return = en & ((inst >> 8) == 16'h0006);
  assign inst_not = en & ((inst >> 8) == 16'h0007);
  assign inst_out_lo = en & ((inst >> 8) == 16'h0008);
  assign inst_out_hi = en & ((inst >> 8) == 16'h0009);
  assign inst_set_dp = en & ((inst >> 8) == 16'h000A);
  assign inst_test = en & ((inst >> 8) == 16'h000B);
  assign inst_status = en & ((inst >> 8) == 16'h0010);
  assign inst_call_word = en & ((inst >> 8) == 16'h003E);
  assign inst_load_word = en & ((inst >> 8) == 16'h003F);
  wire inst_load_indirect = en & ((inst >> 8) == 16'h0044);

  assign bytes = zero_arg ? 1 : 2;

  wire one_arg = en & ((inst & 16'hC000) == 16'h8000);

  wire inst_load_direct = en & ((inst & 16'hF800) == 16'h8000);
  assign inst_load = inst_load_direct | inst_load_indirect;
  assign inst_store = en & ((inst & 16'hF800) == 16'h9000);
  assign inst_add  = en & ((inst & 16'hF800) == 16'h8800);
  assign inst_sub  = en & ((inst & 16'hF800) == 16'h9800);
  assign inst_and  = en & ((inst & 16'hF800) == 16'hA000);
  assign inst_or   = en & ((inst & 16'hF800) == 16'hA800);
  assign inst_xor  = en & ((inst & 16'hF800) == 16'hB000);

  wire inst_sh   = en & ((inst & 16'hF800) == 16'hB800);
  assign inst_shl = ~inst_sh ? 0
    : source_ram ? ((inst & 16'h0001) == 16'h0000)
    : ((inst & 16'h0100) == 16'h0000);
  assign inst_shr = ~inst_sh ? 0
    : source_ram ? ((inst & 16'h0001) == 16'h0001)
    : ((inst & 16'h0100) == 16'h0100);

  wire inst_branch_direct = en & ((inst & 16'hF800) == 16'hC000);
  wire inst_branch_indirect = en & ((inst >> 8) == 16'h000C);
  assign inst_branch = inst_branch_direct | inst_branch_indirect;

  wire inst_call_direct = en & ((inst & 16'hF800) == 16'hD000);
  wire inst_call_indirect = en & ((inst >> 8) == 16'h000D);
  assign inst_call = inst_call_direct | inst_call_indirect;

  assign inst_if = en & ((inst & 16'hF800) == 16'hF000);

  wire source_const = !one_arg ? 0 : (inst & 16'h0600) == 16'h0000;
  wire source_data  = !one_arg ? 0 : (inst & 16'h0600) == 16'h0200;
  wire source_none  = inst_not | inst_test;

  assign source_imm = source_const | source_data | source_none;
  assign source_ram = one_arg ? (inst & 16'h0500) == 16'h0400
    : inst_load_indirect;
  assign source_indirect = one_arg & ((inst & 16'h0500) == 16'h0500);

  assign relative_data = (source_ram | source_indirect)
    ? (inst & 16'h0200) == 16'h0000
    : 0;
  assign relative_stack = (source_ram | source_indirect)
    ? (inst & 16'h0200) == 16'h0200
    : 0;

  assign rhs = !en ? 0
    : (inst_branch_direct | inst_call_direct) ? {{5{inst[10]}}, inst[10:0]}
    : (inst_load_indirect | inst_branch_indirect | inst_call_indirect) ? accum
    : (((inst & 16'h0600) == 16'h0000) & inst_sh) ? {8'h00, inst[7:0]}
    : (((inst & 16'h0600) == 16'h0200) & inst_sh) ? {8'h00, data}
    : (inst & 16'h0700) == 16'h0000 ? {8'h00, inst[7:0]}
    : (inst & 16'h0700) == 16'h0100 ? {inst[7:0], 8'h00}
    : (inst & 16'h0700) == 16'h0200 ? {8'h00, data}
    : (inst & 16'h0700) == 16'h0300 ? {data, 8'h00}
    : (((inst & 16'h0400) == 16'h0400) & inst_sh) ? {8'h00, inst[7:1], 1'b0}
    : (inst & 16'h0400) == 16'h0400 ? {8'h00, inst[7:0]}
    : 0;

  assign if_zero = !inst_if ? 0
    : (inst & 16'h07FF) == 16'h0000;
  assign if_not_zero = !inst_if ? 0
    : (inst & 16'h07FF) == 16'h0001;
  assign if_else = !inst_if ? 0
    : (inst & 16'h07FF) == 16'h0002;
  assign if_not_else = !inst_if ? 0
    : (inst & 16'h07FF) == 16'h0003;
  assign if_neg = !inst_if ? 0
    : (inst & 16'h07FF) == 16'h0004;
  assign if_not_neg = !inst_if ? 0
    : (inst & 16'h07FF) == 16'h0005;
  assign if_carry = !inst_if ? 0
    : (inst & 16'h07FF) == 16'h0006;
  assign if_not_carry = !inst_if ? 0
    : (inst & 16'h07FF) == 16'h0007;

endmodule
