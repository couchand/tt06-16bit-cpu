/*
 * Copyright (c) 2024 Andrew Dona-Couch
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_couchand_cora16 (
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
  assign uio_oe  = rst_n ? 8'b11100111 : 8'b11100000;

  assign uio_out[4:3] = 0;

  wire spi_miso, spi_select, spi_clk, spi_mosi;
  assign spi_miso = uio_in[3];
  assign uio_out[1] = spi_select;
  assign uio_out[2] = spi_clk;
  assign uio_out[0] = spi_mosi;

  wire step, busy, halt, trap;
  assign step = uio_in[4];
  assign uio_out[5] = busy;
  assign uio_out[6] = halt;
  assign uio_out[7] = trap;

  cpu cpu_instance(
    .clk(clk),
    .rst_n(rst_n),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select),
    .spi_clk(spi_clk),
    .spi_miso(spi_miso),
    .step(step),
    .busy(busy),
    .halt(halt),
    .trap(trap),
    .data_in(ui_in),
    .data_out(uo_out)
  );

endmodule
