# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_project(dut):
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

  # With immediates

  for i in range(0, 7):
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 10)
    dut.uio_in.value = 0x00
    await ClockCycles(dut.clk, 10)

    while dut.busy != 0:
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

    while dut.busy != 0:
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

    while dut.busy != 0:
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

    while dut.busy != 0:
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

    while dut.busy != 0:
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

      while dut.busy != 0:
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

    while dut.busy != 0:
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

    while dut.busy != 0:
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

    while dut.busy != 0:
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

    while dut.busy != 0:
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

    while dut.busy != 0:
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

    while dut.busy != 0:
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

    while dut.busy != 0:
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

    while dut.busy != 0:
      await ClockCycles(dut.clk, 10)

    assert dut.halt.value == 0
    assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)

  assert dut.uo_out.value == 9
  assert dut.halt.value == 0
  assert dut.trap.value == 0

  await ClockCycles(dut.clk, 10)
