/*
 * Copyright (c) 2024 Andrew Dona-Couch
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module alu (
    input  wire [15:0] accum,
    input  wire [15:0] rhs,
    output wire [15:0] result,
    output wire        zero,
    output wire        neg,
    output wire        carry,
    output wire        is_alu_inst,
    input  wire        inst_add,
    input  wire        inst_sub,
    input  wire        inst_test,
    input  wire        inst_and,
    input  wire        inst_or,
    input  wire        inst_xor,
    input  wire        inst_not,
    input  wire        inst_shl,
    input  wire        inst_shr
);

  assign is_alu_inst = inst_add | inst_sub | inst_test
    | inst_and | inst_or | inst_xor | inst_not | inst_shl | inst_shr;

  assign result = inst_add ? (accum + rhs)
    : inst_sub ? (accum - rhs)
    : inst_test ? accum
    : inst_and ? (accum & rhs)
    : inst_or ? (accum | rhs)
    : inst_xor ? (accum ^ rhs)
    : inst_not ? (~accum)
    : inst_shl ? (accum << rhs)
    : inst_shr ? (accum >> rhs)
    : 0;

  assign carry = inst_add ? ((accum[15] & rhs[15]) | (rhs[15] & ~result[15]) | (~result[15] & accum[15]))
    : inst_sub ? ((~accum[15] & rhs[15]) | (rhs[15] & result[15]) | (result[15] & ~accum[15]))
    : inst_not ? 1
    : inst_shl ? accum[16 - rhs]
    : inst_shr ? accum[rhs - 1]
    : 0;

  assign zero = is_alu_inst & (result == 0);
  assign neg = is_alu_inst & result[15];

endmodule
