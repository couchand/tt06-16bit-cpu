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
  reg skip;
  reg skipped;

  wire [15:0] rhs;
  wire [1:0] inst_bytes_raw;
  wire [15:0] inst_bytes = {14'b0, inst_bytes_raw};
  wire inst_nop, inst_load, inst_store, inst_add, inst_sub, inst_and, inst_or, inst_xor;
  wire inst_branch, inst_call, inst_if, inst_push, inst_pop, inst_drop, inst_return, inst_not;
  wire inst_out_lo, inst_out_hi, inst_halt, inst_set_dp;
  wire source_imm, source_ram, source_indirect;
  wire relative_stack, relative_data;
  wire if_zero, if_not_zero, if_else, if_not_else;
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
    .inst_load(inst_load),
    .inst_store(inst_store),
    .inst_add(inst_add),
    .inst_sub(inst_sub),
    .inst_and(inst_and),
    .inst_or(inst_or),
    .inst_xor(inst_xor),
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
    .source_imm(source_imm),
    .source_ram(source_ram),
    .source_indirect(source_indirect),
    .relative_stack(relative_stack),
    .relative_data(relative_data),
    .if_zero(if_zero),
    .if_not_zero(if_not_zero),
    .if_else(if_else),
    .if_not_else(if_not_else)
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

  assign busy = state != ST_INIT & state != ST_HALT & state != ST_TRAP;
  assign halt = state == ST_HALT;
  assign trap = state == ST_TRAP;

  wire [15:0] sp_minus_two = sp - 2;

  wire [15:0] ram_addr = (state == ST_LOAD_INST0) ? pc
    : ((state == ST_INST_EXEC0) & (inst_push | inst_call)) ? sp_minus_two
    : ((state == ST_INST_EXEC0) & (inst_pop | inst_return)) ? sp
    : ((state == ST_INST_EXEC0) & (source_ram | source_indirect))
      ? ((relative_stack ? sp : relative_data ? dp : 0) + rhs)
    : ((state == ST_INST_EXEC2) & source_indirect) ? ram_data_out
    : 0;
  wire ram_start_read = (state == ST_LOAD_INST0) ? 1
    : ((state == ST_INST_EXEC0) & ((source_ram & ~inst_store) | source_indirect)) ? ~skip
    : ((state == ST_INST_EXEC0) & (inst_pop | inst_return)) ? ~skip
    : ((state == ST_INST_EXEC2) & source_indirect) ? ~skip
    : 0;
  wire [15:0] ram_data_in = ((state == ST_INST_EXEC0) & source_ram & inst_store) ? accum
    : ((state == ST_INST_EXEC0) & inst_push) ? accum
    : ((state == ST_INST_EXEC0) & inst_call) ? pc
    : ((state == ST_INST_EXEC2) & source_indirect & inst_store) ? accum
    : 0;
  wire ram_start_write = ((state == ST_INST_EXEC0) & source_ram & inst_store) ? ~skip
    : ((state == ST_INST_EXEC0) & (inst_push | inst_call)) ? ~skip
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
      skip <= 0;
      skipped <= 0;
      data_out <= 0;
    end else if (~halt & ~trap) begin
      if (state == ST_INIT) begin
        if (step) begin
          state <= ST_LOAD_INST0;
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
        end else if (inst_set_dp) begin
          pc <= pc + inst_bytes;
          state <= ST_INIT;
          if (~skip) begin
            dp <= accum;
          end
        end else if (inst_drop) begin
          sp <= sp + 2;
          pc <= pc + inst_bytes;
          state <= ST_INIT;
        end else if (inst_push | inst_pop) begin
          if (skip) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_not) begin
          pc <= pc + inst_bytes;
          state <= ST_INIT;
          if (~skip) begin
            accum <= ~accum;
            zero <= (~accum) == 0;
          end
        end else if (inst_load) begin
          if (skip) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_imm) begin
            accum <= rhs;
            zero <= rhs == 0;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_ram | source_indirect) begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_store) begin
          if (skip) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_imm) begin
            state <= ST_TRAP;
          end else if (source_ram | source_indirect) begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_add) begin
          if (skip) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_imm) begin
            accum <= accum + rhs;
            zero <= (accum + rhs) == 0;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_ram | source_indirect) begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_sub) begin
          if (skip) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_imm) begin
            accum <= accum - rhs;
            zero <= (accum - rhs) == 0;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_ram | source_indirect) begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_and) begin
          if (skip) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_imm) begin
            accum <= accum & rhs;
            zero <= (accum & rhs) == 0;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_ram | source_indirect) begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_or) begin
          if (skip) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_imm) begin
            accum <= accum | rhs;
            zero <= (accum | rhs) == 0;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_ram | source_indirect) begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_xor) begin
          if (skip) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_imm) begin
            accum <= accum ^ rhs;
            zero <= (accum ^ rhs) == 0;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (source_ram | source_indirect) begin
            state <= ST_INST_EXEC1;
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
          state <= ST_TRAP;
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
            zero <= ram_data_out == 0;
            state <= ST_INIT;
            pc <= pc + inst_bytes;
          end else if (inst_call) begin
            sp <= sp_minus_two;
            state <= ST_INIT;
            pc <= rhs;
          end else if (inst_return) begin
            sp <= sp + 2;
            state <= ST_INIT;
            pc <= ram_data_out + 2;
          end else if (source_ram) begin
            if (inst_load) begin
              accum <= ram_data_out;
              zero <= ram_data_out == 0;
              pc <= pc + inst_bytes;
              state <= ST_INIT;
            end else if (inst_add) begin
              accum <= accum + ram_data_out;
              zero <= (accum + ram_data_out) == 0;
              pc <= pc + inst_bytes;
              state <= ST_INIT;
            end else if (inst_sub) begin
              accum <= accum - ram_data_out;
              zero <= (accum - ram_data_out) == 0;
              pc <= pc + inst_bytes;
              state <= ST_INIT;
            end else if (inst_and) begin
              accum <= accum & ram_data_out;
              zero <= (accum & ram_data_out) == 0;
              pc <= pc + inst_bytes;
              state <= ST_INIT;
            end else if (inst_or) begin
              accum <= accum | ram_data_out;
              zero <= (accum | ram_data_out) == 0;
              pc <= pc + inst_bytes;
              state <= ST_INIT;
            end else if (inst_xor) begin
              accum <= accum ^ ram_data_out;
              zero <= (accum ^ ram_data_out) == 0;
              pc <= pc + inst_bytes;
              state <= ST_INIT;
            end else if (inst_store) begin
              pc <= pc + inst_bytes;
              state <= ST_INIT;
            end else begin
              state <= ST_TRAP;
            end
          end else if (source_indirect) begin
            if (!ram_busy) begin
              state <= ST_INST_EXEC2;
            end
          end else begin
            state <= ST_TRAP;
          end
        end
      end else if (state == ST_INST_EXEC2) begin
        state <= ST_INST_EXEC3;
      end else if (state == ST_INST_EXEC3) begin
        if (!ram_busy) begin
          if (inst_load) begin
            accum <= ram_data_out;
            zero <= ram_data_out == 0;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (inst_add) begin
            accum <= accum + ram_data_out;
            zero <= (accum + ram_data_out) == 0;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (inst_sub) begin
            accum <= accum - ram_data_out;
            zero <= (accum - ram_data_out) == 0;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (inst_and) begin
            accum <= accum & ram_data_out;
            zero <= (accum & ram_data_out) == 0;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (inst_or) begin
            accum <= accum | ram_data_out;
            zero <= (accum | ram_data_out) == 0;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (inst_xor) begin
            accum <= accum ^ ram_data_out;
            zero <= (accum ^ ram_data_out) == 0;
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else if (inst_store) begin
            pc <= pc + inst_bytes;
            state <= ST_INIT;
          end else begin
            state <= ST_TRAP;
          end
        end
      end else begin
        state <= ST_TRAP;
      end
    end
  end

endmodule
