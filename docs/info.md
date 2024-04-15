<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The module provides an interface to an SPI RAM module, perhaps one emulated by the onboard Raspberry Pi.

## How to test

The input lines are used to clock in a 16-bit address in little-endian order, followed by the data byte in the case of a write command.

To write:

1. Put the low byte of the address on `Data/Address In`, and pull `Start Write` high for one cycle.
2. Clock in the high byte of the address on `Data/Address In`.
3. Clock in the data byte on `Data/Address In`.
4. Wait for `Busy` to go low before starting another command.

To read:

1. Put the low byte of the address on `Data/Address In`, and pull `Start Read` high for one cycle.
2. Clock in the high byte of the addres son `Data/Address In`.
3. Wait for `Busy` to go low.  The data byte is now available on `Data/Address Out`.

## External hardware

The module expects an SPI RAM attached to the relevant SPI pins.  The onboard Raspberry Pi emulation should work just fine.
