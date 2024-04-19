/*
 * Copyright (c) 2024 Andrew Dona-Couch
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module cpu (
    input  wire       clk,
    input  wire       rst_n,

    output wire       spi_mosi,
    output wire       spi_select,
    output wire       spi_clk,
    input  wire       spi_miso,

    input  wire       step,
    output wire       busy,
    output wire       halt,
    output wire       trap,

    input  wire [7:0] data_in,
    output reg [7:0] data_out
);

  reg [15:0] pc;
  reg [15:0] inst;
  reg [15:0] accum;
  reg [15:0] dp;
  reg [15:0] sp;
  reg zero;
  reg neg;
  reg carry;
  reg skip;
  reg skipped;

  wire [15:0] alu_rhs = (state == ST_INST_EXEC0) ? rhs : ram_data_out;
  wire [15:0] alu_result;
  wire alu_zero, alu_neg, alu_carry, is_alu_inst;

  alu alu_instance(
    .accum(accum),
    .rhs(alu_rhs),
    .result(alu_result),
    .zero(alu_zero),
    .neg(alu_neg),
    .carry(alu_carry),
    .is_alu_inst(is_alu_inst),
    .inst_add(inst_add),
    .inst_sub(inst_sub),
    .inst_test(inst_test),
    .inst_and(inst_and),
    .inst_or(inst_or),
    .inst_xor(inst_xor),
    .inst_not(inst_not),
    .inst_shl(inst_shl),
    .inst_shr(inst_shr)
  );

  wire [15:0] rhs;
  wire [1:0] inst_bytes_raw;
  wire [15:0] inst_bytes = {14'b0, inst_bytes_raw};
  wire inst_load, inst_store, inst_add, inst_sub, inst_test, inst_status;
  wire inst_and, inst_or, inst_xor, inst_not, inst_shl, inst_shr;
  wire inst_branch, inst_call, inst_if, inst_push, inst_pop, inst_drop, inst_return;
  wire inst_nop, inst_out_lo, inst_out_hi, inst_halt, inst_trap, inst_set_dp;
  wire inst_call_word, inst_load_word;
  wire source_imm, source_ram, source_indirect;
  wire relative_stack, relative_data;
  wire if_zero, if_not_zero, if_else, if_not_else, if_neg, if_not_neg, if_carry, if_not_carry;
  wire decoding = (state == ST_INST_EXEC0) | (state == ST_INST_EXEC1)
    | (state == ST_INST_EXEC2) | (state == ST_INST_EXEC3);
  decoder inst_decoder(
    .en(decoding),
    .inst(inst),
    .accum(accum),
    .data(data_in),
    .rhs(rhs),
    .bytes(inst_bytes_raw),
    .inst_nop(inst_nop),
    .inst_halt(inst_halt),
    .inst_trap(inst_trap),
    .inst_load(inst_load),
    .inst_store(inst_store),
    .inst_add(inst_add),
    .inst_sub(inst_sub),
    .inst_and(inst_and),
    .inst_or(inst_or),
    .inst_xor(inst_xor),
    .inst_shl(inst_shl),
    .inst_shr(inst_shr),
    .inst_not(inst_not),
    .inst_branch(inst_branch),
    .inst_call(inst_call),
    .inst_if(inst_if),
    .inst_push(inst_push),
    .inst_pop(inst_pop),
    .inst_drop(inst_drop),
    .inst_return(inst_return),
    .inst_out_lo(inst_out_lo),
    .inst_out_hi(inst_out_hi),
    .inst_set_dp(inst_set_dp),
    .inst_test(inst_test),
    .inst_status(inst_status),
    .inst_call_word(inst_call_word),
    .inst_load_word(inst_load_word),
    .source_imm(source_imm),
    .source_ram(source_ram),
    .source_indirect(source_indirect),
    .relative_stack(relative_stack),
    .relative_data(relative_data),
    .if_zero(if_zero),
    .if_not_zero(if_not_zero),
    .if_else(if_else),
    .if_not_else(if_not_else),
    .if_neg(if_neg),
    .if_not_neg(if_not_neg),
    .if_carry(if_carry),
    .if_not_carry(if_not_carry)
  );

  reg [8:0] state;

  localparam ST_INIT = 0;
  localparam ST_HALT = 1;
  localparam ST_TRAP = 2;
  localparam ST_LOAD_INST0 = 3;
  localparam ST_LOAD_INST1 = 4;
  localparam ST_INST_EXEC0 = 5;
  localparam ST_INST_EXEC1 = 6;
  localparam ST_INST_EXEC2 = 7;
  localparam ST_INST_EXEC3 = 8;
  localparam ST_UNTRAP = 9;
  localparam ST_FAULT = 10;

  assign busy = state != ST_INIT & state != ST_HALT & state != ST_TRAP & state != ST_FAULT;
  assign halt = (state == ST_HALT) | (state == ST_FAULT);
  assign trap = (state == ST_TRAP) | (state == ST_FAULT);

  wire [15:0] sp_minus_two = sp - 2;

  wire [15:0] ram_addr = (state == ST_LOAD_INST0) ? pc
    : ((state == ST_INST_EXEC0) & (inst_push | inst_call | inst_call_word)) ? sp_minus_two
    : ((state == ST_INST_EXEC0) & (inst_pop | inst_return)) ? sp
    : ((state == ST_INST_EXEC0) & inst_load_word) ? (pc + inst_bytes)
    : ((state == ST_INST_EXEC0) & (source_ram | source_indirect))
      ? ((relative_stack ? sp : relative_data ? dp : 0) + rhs)
    : ((state == ST_INST_EXEC2) & inst_call_word) ? (pc + inst_bytes)
    : ((state == ST_INST_EXEC2) & source_indirect) ? ram_data_out
    : 0;
  wire ram_start_read = (state == ST_LOAD_INST0) ? 1
    : ((state == ST_INST_EXEC0) & ((source_ram & ~inst_store) | source_indirect)) ? ~skip
    : ((state == ST_INST_EXEC0) & (inst_pop | inst_return)) ? ~skip
    : ((state == ST_INST_EXEC0) & inst_load_word) ? ~skip
    : ((state == ST_INST_EXEC2) & inst_call_word) ? ~skip
    : ((state == ST_INST_EXEC2) & source_indirect) ? ~skip
    : 0;
  wire [15:0] ram_data_in = ((state == ST_INST_EXEC0) & source_ram & inst_store) ? accum
    : ((state == ST_INST_EXEC0) & inst_push) ? accum
    : ((state == ST_INST_EXEC0) & inst_call) ? (pc + inst_bytes)
    : ((state == ST_INST_EXEC0) & inst_call_word) ? (pc + inst_bytes + 2)
    : ((state == ST_INST_EXEC2) & source_indirect & inst_store) ? accum
    : 0;
  wire ram_start_write = ((state == ST_INST_EXEC0) & source_ram & inst_store) ? ~skip
    : ((state == ST_INST_EXEC0) & (inst_push | inst_call | inst_call_word)) ? ~skip
    : ((state == ST_INST_EXEC2) & source_indirect & inst_store) ? ~skip
    : 0;
  wire [15:0] ram_data_out;
  wire ram_busy;

  spi_ram_controller #(
    .DATA_WIDTH_BYTES(2),
    .ADDR_BITS(16)
  ) spi_ram (
    .clk(clk),
    .rstn(rst_n),
    .spi_miso(spi_miso),
    .spi_select(spi_select),
    .spi_clk_out(spi_clk),
    .spi_mosi(spi_mosi),
    .addr_in(ram_addr),
    .data_in(ram_data_in),
    .start_read(ram_start_read),
    .start_write(ram_start_write),
    .data_out(ram_data_out),
    .busy(ram_busy)
  );

  always @(posedge clk) begin
    if (!rst_n) begin
      state <= ST_INIT;
      pc <= 0;
      inst <= 0;
      accum <= 0;
      dp <= 0;
      sp <= 0;
      zero <= 0;
      neg <= 0;
      carry <= 0;
      skip <= 0;
      skipped <= 0;
      data_out <= 0;
    end else if (~halt) begin
      if (state == ST_INIT) begin
        if (step) begin
          state <= ST_LOAD_INST0;
        end
      end else if (state == ST_TRAP) begin
        if (step) begin
          state <= ST_UNTRAP;
        end
      end else if (state == ST_UNTRAP) begin
        if (~step) begin
          state <= ST_INIT;
        end
      end else if (state == ST_LOAD_INST0) begin
        state <= ST_LOAD_INST1;
      end else if (state == ST_LOAD_INST1) begin
        if (!ram_busy) begin
          inst <= ram_data_out;
          state <= ST_INST_EXEC0;
        end
      end else if (state == ST_INST_EXEC0) begin
        if (inst_nop) begin
          pc <= pc + inst_bytes;
          state <= ST_INIT;
        end else if (inst_halt) begin
          pc <= pc + inst_bytes;
          if (skip) begin
            state <= ST_INIT;
          end else begin
            state <= ST_HALT;
          end
        end else if (inst_trap) begin
          pc <= pc + inst_bytes;
          if (skip) begin
            state <= ST_INIT;
          end else begin
            state <= ST_TRAP;
          end
        end else if (inst_set_dp) begin
          pc <= pc + inst_bytes;
          state <= ST_INIT;
          if (~skip) begin
            dp <= accum;
          end
        end else if (inst_status) begin
          accum <= {2'b0, skipped, 2'b0, carry, neg, zero};
          pc <= pc + inst_bytes;
          state <= ST_INIT;
        end else if (inst_drop) begin
          pc <= pc + inst_bytes;
          state <= ST_INIT;
          if (~skip) begin
            sp <= sp + 2;
          end
        end else if (inst_push | inst_pop) begin
          if (skip) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_call_word | inst_load_word) begin
          if (skip) begin
            pc <= pc + inst_bytes + 2;
            state <= ST_INIT;
          end else begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_load) begin
          if (skip) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_imm) begin
            accum <= rhs;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_ram | source_indirect) begin
            state <= ST_INST_EXEC1;
          end else begin
            state <= ST_FAULT;
          end
        end else if (inst_store) begin
          if (skip) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_imm) begin
            state <= ST_FAULT;
          end else if (source_ram | source_indirect) begin
            state <= ST_INST_EXEC1;
          end else begin
            state <= ST_FAULT;
          end
        end else if (is_alu_inst) begin
          if (skip) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_imm) begin
            accum <= alu_result;
            zero <= alu_zero;
            neg <= alu_neg;
            carry <= alu_carry;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_ram | source_indirect) begin
            state <= ST_INST_EXEC1;
          end else begin
            state <= ST_FAULT;
          end
        end else if (inst_branch) begin
          state <= ST_INIT;
          if (skip) begin
            pc <= pc + inst_bytes;
          end else begin
            pc <= pc + inst_bytes + rhs;
          end
        end else if (inst_call) begin
          if (skip) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_return) begin
          if (skip) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_if) begin
          pc <= pc + inst_bytes;
          state <= ST_INIT;
        end else if (inst_out_lo) begin
          pc <= pc + inst_bytes;
          state <= ST_INIT;
          if (~skip) begin
            data_out <= accum[7:0];
          end
        end else if (inst_out_hi) begin
          pc <= pc + inst_bytes;
          state <= ST_INIT;
          if (~skip) begin
            data_out <= accum[15:8];
          end
        end else begin
          state <= ST_FAULT;
        end

        if (inst_if) begin
          if (if_zero) begin
            skip <= ~zero;
          end else if (if_not_zero) begin
            skip <= zero;
          end else if (if_else) begin
            skip <= ~skipped;
          end else if (if_not_else) begin
            skip <= skipped;
          end else if (if_neg) begin
            skip <= ~neg;
          end else if (if_not_neg) begin
            skip <= neg;
          end else if (if_carry) begin
            skip <= ~carry;
          end else if (if_not_carry) begin
            skip <= carry;
          end else begin
            state <= ST_FAULT;
          end
        end else begin
          skip <= 0;
        end

        skipped <= skip;

      end else if (state == ST_INST_EXEC1) begin
        if (!ram_busy) begin
          if (inst_push) begin
            sp <= sp_minus_two;
            state <= ST_INIT;
            pc <= pc + inst_bytes;
          end else if (inst_pop) begin
            sp <= sp + 2;
            accum <= ram_data_out;
            state <= ST_INIT;
            pc <= pc + inst_bytes;
          end else if (inst_call) begin
            sp <= sp_minus_two;
            state <= ST_INIT;
            pc <= rhs;
          end else if (inst_return) begin
            sp <= sp + 2;
            state <= ST_INIT;
            pc <= ram_data_out;
          end else if (inst_call_word) begin
            sp <= sp_minus_two;
            state <= ST_INST_EXEC2;
          end else if (inst_load_word) begin
            accum <= ram_data_out;
            pc <= pc + inst_bytes + 2;
            state <= ST_INIT;
          end else if (source_ram) begin
            if (inst_load) begin
              accum <= ram_data_out;
              pc <= pc + inst_bytes;
              state <= ST_INIT;
            end else if (is_alu_inst) begin
              accum <= alu_result;
              zero <= alu_zero;
              neg <= alu_neg;
              carry <= alu_carry;
              pc <= pc + inst_bytes;
              state <= ST_INIT;
            end else if (inst_store) begin
              pc <= pc + inst_bytes;
              state <= ST_INIT;
            end else begin
              state <= ST_FAULT;
            end
          end else if (source_indirect) begin
            if (!ram_busy) begin
              state <= ST_INST_EXEC2;
            end
          end else begin
            state <= ST_FAULT;
          end
        end
      end else if (state == ST_INST_EXEC2) begin
        state <= ST_INST_EXEC3;
      end else if (state == ST_INST_EXEC3) begin
        if (!ram_busy) begin
          if (inst_load) begin
            accum <= ram_data_out;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (is_alu_inst) begin
            accum <= alu_result;
            zero <= alu_zero;
            neg <= alu_neg;
            carry <= alu_carry;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (inst_store) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (inst_call_word) begin
            pc <= ram_data_out;
            state <= ST_INIT;
          end else begin
            state <= ST_FAULT;
          end
        end
      end else begin
        state <= ST_FAULT;
      end
    end
  end

endmodule
