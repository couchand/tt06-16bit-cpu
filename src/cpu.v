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
  reg zero;
  reg skip;
  reg skipped;

  wire [15:0] rhs;
  wire inst_nop, inst_load, inst_store, inst_add, inst_sub, inst_and, inst_or, inst_xor;
  wire inst_branch, inst_if, inst_out_lo, inst_not;
  wire source_imm, source_ram;
  wire if_zero, if_not_zero, if_else, if_not_else;
  wire decoding = (state == ST_INST_EXEC0) | (state == ST_INST_EXEC1);
  decoder inst_decoder(
    .en(decoding),
    .inst(inst),
    .data(data_in),
    .rhs(rhs),
    .inst_nop(inst_nop),
    .inst_load(inst_load),
    .inst_store(inst_store),
    .inst_add(inst_add),
    .inst_sub(inst_sub),
    .inst_and(inst_and),
    .inst_or(inst_or),
    .inst_xor(inst_xor),
    .inst_not(inst_not),
    .inst_branch(inst_branch),
    .inst_if(inst_if),
    .inst_out_lo(inst_out_lo),
    .source_imm(source_imm),
    .source_ram(source_ram),
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

  assign busy = state != ST_INIT & state != ST_HALT & state != ST_TRAP;
  assign halt = state == ST_HALT;
  assign trap = state == ST_TRAP;

  wire [15:0] ram_addr = (state == ST_LOAD_INST0) ? pc
    : ((state == ST_INST_EXEC0) & source_ram) ? rhs
    : 0;
  wire ram_start_read = (state == ST_LOAD_INST0) ? 1
    : ((state == ST_INST_EXEC0) & source_ram & ~inst_store) ? 1
    : 0;
  wire [15:0] ram_data_in = ((state == ST_INST_EXEC0) & source_ram & inst_store)
    ? accum
    : 0;
  wire ram_start_write = ((state == ST_INST_EXEC0) & source_ram & inst_store)
    ? 1
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
          pc <= pc + 1;
          state <= ST_INIT;
        end else if (inst_not) begin
          pc <= pc + 1;
          state <= ST_INIT;
          if (~skip) begin
            accum <= ~accum;
            zero <= (~accum) == 0;
          end
        end else if (inst_load) begin
          if (skip) begin
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (source_imm) begin
            accum <= rhs;
            zero <= rhs == 0;
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (source_ram) begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_store) begin
          if (skip) begin
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (source_imm) begin
            state <= ST_TRAP;
          end else if (source_ram) begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_add) begin
          if (skip) begin
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (source_imm) begin
            accum <= accum + rhs;
            zero <= (accum + rhs) == 0;
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (source_ram) begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_sub) begin
          if (skip) begin
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (source_imm) begin
            accum <= accum - rhs;
            zero <= (accum - rhs) == 0;
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (source_ram) begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_and) begin
          if (skip) begin
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (source_imm) begin
            accum <= accum & rhs;
            zero <= (accum & rhs) == 0;
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (source_ram) begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_or) begin
          if (skip) begin
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (source_imm) begin
            accum <= accum | rhs;
            zero <= (accum | rhs) == 0;
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (source_ram) begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_xor) begin
          if (skip) begin
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (source_imm) begin
            accum <= accum ^ rhs;
            zero <= (accum ^ rhs) == 0;
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (source_ram) begin
            state <= ST_INST_EXEC1;
          end
        end else if (inst_branch) begin
          state <= ST_INIT;
          if (skip) begin
            pc <= pc + 2;
          end else begin
            pc <= pc + 2 + rhs;
          end
        end else if (inst_if) begin
          pc <= pc + 2;
          state <= ST_INIT;
        end else if (inst_out_lo) begin
          pc <= pc + 1;
          state <= ST_INIT;
          if (~skip) begin
            data_out <= accum[7:0];
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
          if (inst_load) begin
            accum <= ram_data_out;
            zero <= ram_data_out == 0;
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (inst_add) begin
            accum <= accum + ram_data_out;
            zero <= (accum + ram_data_out) == 0;
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (inst_sub) begin
            accum <= accum - ram_data_out;
            zero <= (accum - ram_data_out) == 0;
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (inst_and) begin
            accum <= accum & ram_data_out;
            zero <= (accum & ram_data_out) == 0;
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (inst_or) begin
            accum <= accum | ram_data_out;
            zero <= (accum | ram_data_out) == 0;
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (inst_xor) begin
            accum <= accum ^ ram_data_out;
            zero <= (accum ^ ram_data_out) == 0;
            pc <= pc + 2;
            state <= ST_INIT;
          end else if (inst_store) begin
            pc <= pc + 2;
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
