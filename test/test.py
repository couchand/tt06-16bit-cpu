# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_ops(dut):
  dut.enable_ops.value = 1
  dut.enable_fib_memo.value = 0
  dut.enable_fib_framed.value = 0
  dut.enable_fib_recursive.value = 0

  dut._log.info("Start")

  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  debug_clock = Clock(dut.debug_clk, 10, units="us")
  cocotb.start_soon(debug_clock.start())

  # Reset
  dut._log.info("Reset")
  dut.ena.value = 1
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  dut.debug_clk.value = 0
  dut.debug_addr.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 10)

  dut._log.info("Test")

  # With immediates

  for i in range(0, 7):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 50
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # With input value

  dut.ui_in.value = 40

  for i in range(0, 4):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 70
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # With memory read

  for i in range(0, 4):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 50
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # Branch

  for i in range(0, 4):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 0xA5
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # Branch backwards

  for i in range(0, 6):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 0x5A
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # Conditionals

  for i in range(1, 10):
    dut.ui_in.value = i

    for step in range(0, 5):
      dut.uio_in.value = 0x10
      await ClockCycles(dut.clk, 10)
      dut.uio_in.value = 0x00
      await ClockCycles(dut.clk, 10)

      while dut.busy.value != 0:
        await ClockCycles(dut.clk, 10)

    await ClockCycles(dut.clk, 10)

    assert dut.uo_out.value == i
    assert dut.halt.value == 0
    assert dut.trap.value == 0

    await ClockCycles(dut.clk, 10)

  dut.ui_in.value = 0

  for i in range(0, 5):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

    assert dut.halt.value == 0
    assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 9
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # Memory Store

  for step in range(0, 7):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 39
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # Subtract

  for step in range(0, 7):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

    assert dut.halt.value == 0
    assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 0x11
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # And

  for step in range(0, 6):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

    assert dut.halt.value == 0
    assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 0x30
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # Or

  for step in range(0, 6):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

    assert dut.halt.value == 0
    assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 0xFC
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # Xor

  for step in range(0, 6):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

    assert dut.halt.value == 0
    assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 0xCC
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # Xor

  for step in range(0, 5):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

    assert dut.halt.value == 0
    assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 0x5A
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # Load Indirect

  for step in range(0, 4):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

    assert dut.halt.value == 0
    assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 9
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # Indirect Addressing Mode

  for step in range(0, 5):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

    assert dut.halt.value == 0
    assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 30
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # Push/Pop

  for step in range(0, 9):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

    assert dut.halt.value == 0
    assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 0x99
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  for step in range(0, 6):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

    assert dut.halt.value == 0
    assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 0xAA
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # Call/Return

  dut.debug_addr.value = 0x3FFF

  for step in range(0, 6):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

    assert dut.halt.value == 0
    assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 0x42
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # Hi/Lo Out

  for step in range(0, 7):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

    assert dut.halt.value == 0
    assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 0x22
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  dut.uio_in.value = 0x10
  await ClockCycles(dut.clk, 10)
  dut.uio_in.value = 0x00
  await ClockCycles(dut.clk, 10)

  while dut.busy.value != 0:
    await ClockCycles(dut.clk, 10)

  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 0x33
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  # Trap

  for step in range(0, 2):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy.value != 0:
      await ClockCycles(dut.clk, 10)

    assert dut.halt.value == 0
    assert dut.trap.value == 0

  dut.uio_in.value = 0x10
  await ClockCycles(dut.clk, 10)
  dut.uio_in.value = 0x00
  await ClockCycles(dut.clk, 10)

  while dut.busy.value != 0:
    await ClockCycles(dut.clk, 10)

  await ClockCycles(dut.clk, 10)

  assert dut.halt.value == 0
  assert dut.trap.value == 1

  await ClockCycles(dut.clk, 10)

  dut.uio_in.value = 0x10
  await ClockCycles(dut.clk, 10)
  dut.uio_in.value = 0x00
  await ClockCycles(dut.clk, 10)

  while dut.busy.value != 0:
    await ClockCycles(dut.clk, 10)

  await ClockCycles(dut.clk, 10)

  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

@cocotb.test()
async def test_fib_memo(dut):
  dut.enable_ops.value = 0
  dut.enable_fib_memo.value = 1
  dut.enable_fib_framed.value = 0
  dut.enable_fib_recursive.value = 0

  dut._log.info("Start")

  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  debug_clock = Clock(dut.debug_clk, 10, units="us")
  cocotb.start_soon(debug_clock.start())

  # Reset
  dut._log.info("Reset")
  dut.ena.value = 1
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  dut.debug_clk.value = 0
  dut.debug_addr.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 10)

  dut.debug_addr.value = 0x17

  dut._log.info("Test")
  dut.ui_in.value = 6
  dut.uio_in.value = 0x10
  await ClockCycles(dut.clk, 1)
  dut.uio_in.value = 0
  while dut.halt.value != 1:
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 0

    while dut.busy.value == 1:
      await ClockCycles(dut.clk, 1)

    await ClockCycles(dut.clk, 10)
    dut.ui_in.value = 0

    assert dut.trap.value == 0

  assert dut.halt.value == 1
  assert dut.uo_out.value == 0x0D

@cocotb.test()
async def test_fib_framed(dut):
  dut.enable_ops.value = 0
  dut.enable_fib_memo.value = 0
  dut.enable_fib_framed.value = 1
  dut.enable_fib_recursive.value = 0

  dut._log.info("Start")

  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  debug_clock = Clock(dut.debug_clk, 10, units="us")
  cocotb.start_soon(debug_clock.start())

  # Reset
  dut._log.info("Reset")
  dut.ena.value = 1
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  dut.debug_clk.value = 0
  dut.debug_addr.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 10)

  dut.debug_addr.value = 0x17

  dut._log.info("Test")
  dut.ui_in.value = 6
  dut.uio_in.value = 0x10
  await ClockCycles(dut.clk, 1)
  dut.uio_in.value = 0
  while dut.halt.value != 1:
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 0

    while dut.busy.value == 1:
      await ClockCycles(dut.clk, 1)

    await ClockCycles(dut.clk, 10)
    dut.ui_in.value = 0

    assert dut.trap.value == 0

  assert dut.halt.value == 1
  assert dut.uo_out.value == 0x0D

@cocotb.test()
async def test_fib_recursive(dut):
  dut.enable_ops.value = 0
  dut.enable_fib_memo.value = 0
  dut.enable_fib_framed.value = 0
  dut.enable_fib_recursive.value = 1

  dut._log.info("Start")

  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  debug_clock = Clock(dut.debug_clk, 10, units="us")
  cocotb.start_soon(debug_clock.start())

  # Reset
  dut._log.info("Reset")
  dut.ena.value = 1
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  dut.rst_n.value = 0
  dut.debug_clk.value = 0
  dut.debug_addr.value = 0
  await ClockCycles(dut.clk, 10)
  dut.rst_n.value = 1
  await ClockCycles(dut.clk, 10)

  dut.debug_addr.value = 0x3FFB

  dut._log.info("Test")
  dut.ui_in.value = 6
  dut.uio_in.value = 0x10
  await ClockCycles(dut.clk, 1)
  dut.uio_in.value = 0
  while dut.halt.value != 1:
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 0

    while dut.busy.value == 1:
      await ClockCycles(dut.clk, 1)

    await ClockCycles(dut.clk, 10)
    dut.ui_in.value = 0

    assert dut.trap.value == 0

  assert dut.halt.value == 1
  assert dut.uo_out.value == 0x0D
