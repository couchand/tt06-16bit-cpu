# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: MIT

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

async def do_write(dut, addr_hi, addr_lo, data):
  dut._log.info(f'Writing 0x{data:02x} to 0x{addr_hi:02x}{addr_lo:02x}')
  dut.uio_in.value = 0x10
  dut.ui_in.value = addr_lo
  await ClockCycles(dut.clk, 1)
  dut.uio_in.value = 0x00
  dut.ui_in.value = addr_hi
  await ClockCycles(dut.clk, 1)
  dut.ui_in.value = data
  await ClockCycles(dut.clk, 1)
  dut.ui_in.value = 0

  while dut.uio_out.value & 0b10000000 != 0:
    await ClockCycles(dut.clk, 1)

async def do_read(dut, addr_hi, addr_lo, data):
  dut._log.info(f'Reading from 0x{addr_hi:02x}{addr_lo:02x}')

  dut.uio_in.value = 0x20
  dut.ui_in.value = addr_lo
  await ClockCycles(dut.clk, 1)
  dut.uio_in.value = 0x00
  dut.ui_in.value = addr_hi
  await ClockCycles(dut.clk, 1)
  dut.ui_in.value = 0

  while dut.uio_out.value & 0b10000000 != 0:
    await ClockCycles(dut.clk, 1)

  assert dut.uo_out.value == data

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

  dut._log.info("Test")
  dut.uio_in.value = 0x10
  dut.ui_in.value = 0x00
  await ClockCycles(dut.clk, 1)
  dut.uio_in.value = 0x00
  dut.ui_in.value = 0x01
  await ClockCycles(dut.clk, 1)
  dut.ui_in.value = 50
  await ClockCycles(dut.clk, 1)

  while dut.uio_out.value & 0b10000000 != 0:
    await ClockCycles(dut.clk, 10)

  dut.uio_in.value = 0x20
  dut.ui_in.value = 0x00
  await ClockCycles(dut.clk, 1)
  dut.uio_in.value = 0x00
  dut.ui_in.value = 0x01
  await ClockCycles(dut.clk, 1)

  while dut.uio_out.value & 0b10000000 != 0:
    await ClockCycles(dut.clk, 1)

  assert dut.uo_out.value == 50

  await do_write(dut, 1, 2, 3)
  await do_write(dut, 2, 1, 5)
  await do_write(dut, 0, 0, 1)
  await do_write(dut, 0, 1, 2)
  await do_write(dut, 0, 2, 3)
  await do_write(dut, 0, 1, 4)
  await do_read(dut, 1, 2, 3)
  await do_read(dut, 2, 1, 5)
  await do_read(dut, 0, 0, 1)
  await do_read(dut, 0, 1, 4)
  await do_read(dut, 0, 2, 3)
