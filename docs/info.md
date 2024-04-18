<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

A little 16-bit CPU accumulator machine.

## How to test

1. Load the program to run into the external SPI RAM.
2. Reset the CPU.
3. Raise `step` high for a clock for each instruction to step.
4. Hold `step` high to run free (you are advised to handle `trap`).
5. Observe `halt` and `trap` for the module status.

## External hardware

The module expects an SPI RAM attached to the relevant SPI pins.  The onboard Raspberry Pi emulation should work just fine.
