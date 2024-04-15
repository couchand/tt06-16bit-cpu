/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`define default_netname none

module tt_um_couchand_spi_ram (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Allow external SPI RAM programming on reset
  assign uio_oe  = rst_n ? 8'b10000111 : 8'b10000000;

  assign uio_out[6:3] = 0;

  wire spi_miso, spi_select, spi_clk, spi_mosi;
  assign spi_miso = uio_in[3];
  assign uio_out[1] = spi_select;
  assign uio_out[2] = spi_clk;
  assign uio_out[0] = spi_mosi;

  wire start_read, start_write, busy;
  assign uio_out[7] = waiting;
  assign start_write = uio_in[4];
  assign start_read = uio_in[5];

  wire [7:0] ram_data;
  wire ram_start_read = state == ST_READ_START;
  wire ram_start_write = state == ST_WRITE_START;

  reg [15:0] addr;
  reg [7:0] data;
  reg waiting;

  reg [2:0] state;

  localparam ST_IDLE = 0;
  localparam ST_READ_ADDR0 = 1;
  localparam ST_READ_START = 2;
  localparam ST_WRITE_ADDR0 = 3;
  localparam ST_WRITE_ADDR1 = 4;
  localparam ST_WRITE_START = 5;

  assign uo_out = data;

  spi_ram_controller #(
    .DATA_WIDTH_BYTES(1),
    .ADDR_BITS(16)
  ) spi (
    .clk(clk),
    .rstn(rst_n),
    .spi_miso(spi_miso),
    .spi_select(spi_select),
    .spi_clk_out(spi_clk),
    .spi_mosi(spi_mosi),
    .addr_in(addr),
    .data_in(data),
    .start_read(ram_start_read),
    .start_write(ram_start_write),
    .data_out(ram_data),
    .busy(busy)
  );

  always @(posedge clk) begin
    if (!rst_n) begin
      addr <= 0;
      data <= 0;
      waiting <= 0;
      state <= ST_IDLE;
    end else if (waiting) begin
      if (state == ST_READ_ADDR0) begin
        addr[15:8] <= ui_in;
        state <= ST_READ_START;
      end else if (state == ST_READ_START) begin
        state <= ST_IDLE;
      end else if (state == ST_WRITE_ADDR0) begin
        addr[15:8] <= ui_in;
        state <= ST_WRITE_ADDR1;
      end else if (state == ST_WRITE_ADDR1) begin
        data <= ui_in;
        state <= ST_WRITE_START;
      end else if (state == ST_WRITE_START) begin
        state <= ST_IDLE;
      end else if (!busy) begin
        waiting <= 0;
        data <= ram_data;
      end
    end else if (start_write) begin
      waiting <= 1;
      addr[7:0] <= ui_in;
      state <= ST_WRITE_ADDR0;
    end else if (start_read) begin
      waiting <= 1;
      addr[7:0] <= ui_in;
      state <= ST_READ_ADDR0;
    end
  end

endmodule
