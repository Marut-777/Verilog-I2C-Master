# Verilog I²C Master

A beginner-level Verilog project implementing and simulating an I²C master that writes one byte to a 7-bit slave address.

## Features

- Generates an I²C START and STOP condition.
- Sends a 7-bit slave address with the write bit.
- Transmits one 8-bit data byte.
- Checks for slave ACK/NACK.
- Includes a testbench for simulation.

## Example transaction

- Slave address: `0x50`
- Write bit: `0`
- Data byte: `0xA5`
- Expected result: ACKs received, `done = 1`, `error = 0`

## Files

- `design.sv` — I²C master RTL.
- `testbench.sv` — simulation testbench.

## Simulation

Developed and simulated using Icarus Verilog and EPWave on EDA Playground.

The testbench uses a simple simulated slave ACK model. This project demonstrates a basic single-byte write transaction; it is not a complete, hardware-validated I²C controller.

## Future improvements

- Add configurable SCL timing.
- Support multiple-byte transfers.
- Develop a more independent slave test model.
- Test with an actual I²C peripheral.
