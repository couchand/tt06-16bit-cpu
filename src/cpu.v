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
    output wire [7:0] data_out
);

  reg [1:0] state;

  localparam ST_INIT = 0;
  localparam ST_HALT = 1;
  localparam ST_TRAP = 2;

  assign halt = state == ST_HALT;
  assign trap = state == ST_TRAP;

  assign data_out = data_in;

  reg [15:0] ram_addr;
  reg [15:0] ram_data_in;
  reg ram_start_read, ram_start_write;
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
      ram_addr <= 0;
      ram_data_in <= 0;
      ram_start_read <= 0;
      ram_start_write <= 0;
    end
  end

endmodule
