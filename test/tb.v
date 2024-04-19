`default_nettype none `timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  wire spi_miso, spi_select, spi_clk, spi_mosi;
  assign uio_in[3] = spi_miso;
  assign spi_select = uio_out[1];
  assign spi_clk = uio_out[2];
  assign spi_mosi = uio_out[0];

  wire busy, halt, trap;
  assign busy = uio_out[5];
  assign halt = uio_out[6];
  assign trap = uio_out[7];

  tt_um_couchand_cora16 user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(1'b1),
      .VGND(1'b0),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

  reg enable_ops, enable_fault, enable_op_halt, enable_op_trap;
  reg enable_op_push, enable_op_pop, enable_op_drop;
  reg enable_op_test, enable_op_status;
  reg enable_op_add_carry, enable_op_sub_carry, enable_op_not_carry, enable_op_shift_carry;
  reg enable_fib_memo, enable_fib_framed, enable_fib_recursive;

  wire spi_select_ops = spi_select & enable_ops;
  wire spi_select_fault = spi_select & enable_fault;
  wire spi_select_op_halt = spi_select & enable_op_halt;
  wire spi_select_op_trap = spi_select & enable_op_trap;
  wire spi_select_op_push = spi_select & enable_op_push;
  wire spi_select_op_pop = spi_select & enable_op_pop;
  wire spi_select_op_drop = spi_select & enable_op_drop;
  wire spi_select_op_test = spi_select & enable_op_test;
  wire spi_select_op_status = spi_select & enable_op_status;
  wire spi_select_op_add_carry = spi_select & enable_op_add_carry;
  wire spi_select_op_sub_carry = spi_select & enable_op_sub_carry;
  wire spi_select_op_not_carry = spi_select & enable_op_not_carry;
  wire spi_select_op_shift_carry = spi_select & enable_op_shift_carry;
  wire spi_select_fib_memo = spi_select & enable_fib_memo;
  wire spi_select_fib_framed = spi_select & enable_fib_framed;
  wire spi_select_fib_recursive = spi_select & enable_fib_recursive;

  assign spi_miso = enable_ops ? spi_miso_ops
    : enable_fault ? spi_miso_fault
    : enable_op_halt ? spi_miso_op_halt
    : enable_op_trap ? spi_miso_op_trap
    : enable_op_push ? spi_miso_op_push
    : enable_op_pop ? spi_miso_op_pop
    : enable_op_drop ? spi_miso_op_drop
    : enable_op_test ? spi_miso_op_test
    : enable_op_status ? spi_miso_op_status
    : enable_op_add_carry ? spi_miso_op_add_carry
    : enable_op_sub_carry ? spi_miso_op_sub_carry
    : enable_op_not_carry ? spi_miso_op_not_carry
    : enable_op_shift_carry ? spi_miso_op_shift_carry
    : enable_fib_memo ? spi_miso_fib_memo
    : enable_fib_framed ? spi_miso_fib_framed
    : enable_fib_recursive ? spi_miso_fib_recursive
    : 0;

  reg debug_clk;
  reg [23:0] debug_addr;

  wire [31:0] debug_data_ops;
  wire spi_miso_ops;
  sim_spi_ram #(
    .INIT_FILE("mem/ops.mem")
  ) spi_ram_ops (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_ops),
    .spi_miso(spi_miso_ops),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_ops)
  );

  wire [31:0] debug_data_fault;
  wire spi_miso_fault;
  sim_spi_ram #(
    .INIT_FILE("mem/fault.mem")
  ) spi_ram_fault (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_fault),
    .spi_miso(spi_miso_fault),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_fault)
  );

  wire [31:0] debug_data_op_halt;
  wire spi_miso_op_halt;
  sim_spi_ram #(
    .INIT_FILE("mem/op_halt.mem")
  ) spi_ram_op_halt (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_op_halt),
    .spi_miso(spi_miso_op_halt),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_op_halt)
  );

  wire [31:0] debug_data_op_trap;
  wire spi_miso_op_trap;
  sim_spi_ram #(
    .INIT_FILE("mem/op_trap.mem")
  ) spi_ram_op_trap (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_op_trap),
    .spi_miso(spi_miso_op_trap),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_op_trap)
  );

  wire [31:0] debug_data_op_push;
  wire spi_miso_op_push;
  sim_spi_ram #(
    .INIT_FILE("mem/op_push.mem")
  ) spi_ram_op_push (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_op_push),
    .spi_miso(spi_miso_op_push),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_op_push)
  );

  wire [31:0] debug_data_op_pop;
  wire spi_miso_op_pop;
  sim_spi_ram #(
    .INIT_FILE("mem/op_pop.mem")
  ) spi_ram_op_pop (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_op_pop),
    .spi_miso(spi_miso_op_pop),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_op_pop)
  );

  wire [31:0] debug_data_op_drop;
  wire spi_miso_op_drop;
  sim_spi_ram #(
    .INIT_FILE("mem/op_drop.mem")
  ) spi_ram_op_drop (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_op_drop),
    .spi_miso(spi_miso_op_drop),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_op_drop)
  );

  wire [31:0] debug_data_op_test;
  wire spi_miso_op_test;
  sim_spi_ram #(
    .INIT_FILE("mem/op_test.mem")
  ) spi_ram_op_test (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_op_test),
    .spi_miso(spi_miso_op_test),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_op_test)
  );

  wire [31:0] debug_data_op_status;
  wire spi_miso_op_status;
  sim_spi_ram #(
    .INIT_FILE("mem/op_status.mem")
  ) spi_ram_op_status (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_op_status),
    .spi_miso(spi_miso_op_status),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_op_status)
  );

  wire [31:0] debug_data_op_add_carry;
  wire spi_miso_op_add_carry;
  sim_spi_ram #(
    .INIT_FILE("mem/op_add_carry.mem")
  ) spi_ram_op_add_carry (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_op_add_carry),
    .spi_miso(spi_miso_op_add_carry),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_op_add_carry)
  );

  wire [31:0] debug_data_op_sub_carry;
  wire spi_miso_op_sub_carry;
  sim_spi_ram #(
    .INIT_FILE("mem/op_sub_carry.mem")
  ) spi_ram_op_sub_carry (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_op_sub_carry),
    .spi_miso(spi_miso_op_sub_carry),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_op_sub_carry)
  );

  wire [31:0] debug_data_op_not_carry;
  wire spi_miso_op_not_carry;
  sim_spi_ram #(
    .INIT_FILE("mem/op_not_carry.mem")
  ) spi_ram_op_not_carry (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_op_not_carry),
    .spi_miso(spi_miso_op_not_carry),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_op_not_carry)
  );

  wire [31:0] debug_data_op_shift_carry;
  wire spi_miso_op_shift_carry;
  sim_spi_ram #(
    .INIT_FILE("mem/op_shift_carry.mem")
  ) spi_ram_op_shift_carry (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_op_shift_carry),
    .spi_miso(spi_miso_op_shift_carry),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_op_shift_carry)
  );

  wire [31:0] debug_data_fib_memo;
  wire spi_miso_fib_memo;
  sim_spi_ram #(
    .INIT_FILE("mem/fib_memo.mem")
  ) spi_ram_fib_memo (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_fib_memo),
    .spi_miso(spi_miso_fib_memo),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_fib_memo)
  );

  wire [31:0] debug_data_fib_framed;
  wire spi_miso_fib_framed;
  sim_spi_ram #(
    .INIT_FILE("mem/fib_framed.mem")
  ) spi_ram_fib_framed (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_fib_framed),
    .spi_miso(spi_miso_fib_framed),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_fib_framed)
  );

  wire [31:0] debug_data_fib_recursive;
  wire spi_miso_fib_recursive;
  sim_spi_ram #(
    .INIT_FILE("mem/fib_recursive.mem")
  ) spi_ram_fib_recursive (
    .spi_clk(spi_clk),
    .spi_mosi(spi_mosi),
    .spi_select(spi_select_fib_recursive),
    .spi_miso(spi_miso_fib_recursive),
    .debug_clk(debug_clk),
    .debug_addr(debug_addr),
    .debug_data(debug_data_fib_recursive)
  );

  always @(posedge clk) begin
    if (!rst_n) begin
      enable_ops <= 0;
      enable_fault <= 0;
      enable_op_halt <= 0;
      enable_op_trap <= 0;
      enable_op_push <= 0;
      enable_op_pop <= 0;
      enable_op_drop <= 0;
      enable_op_test <= 0;
      enable_op_status <= 0;
      enable_op_add_carry <= 0;
      enable_op_sub_carry <= 0;
      enable_op_not_carry <= 0;
      enable_op_shift_carry <= 0;
      enable_fib_memo <= 0;
      enable_fib_framed <= 0;
      enable_fib_recursive <= 0;
    end
  end

endmodule
