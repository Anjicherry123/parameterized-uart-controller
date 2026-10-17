# Parameterized UART Controller Design and Verification

## Overview

This project implements a parameterized Universal Asynchronous Receiver/Transmitter (UART) controller using Verilog HDL. It includes UART transmission and reception, FIFO buffering, baud-rate generation, and functional loopback verification using Xilinx Vivado Simulator.

The design was synthesized and implemented for the AMD/Xilinx Artix-7 FPGA target `xc7a35tcpg236-1`. No physical FPGA board was used for hardware validation.

## Features

- Parameterized UART transmitter and receiver
- Configurable clock frequency and baud rate
- 8-bit serial data transmission
- One start bit and one stop bit
- No parity
- 16-entry transmit FIFO
- 16-entry receive FIFO
- FIFO full and empty status flags
- Serial loopback testing
- Vivado synthesis and timing analysis

## Design Specifications

| Parameter | Value |
|---|---|
| Clock frequency | 100 MHz |
| Baud rate | 115200 |
| Data width | 8 bits |
| FIFO depth | 16 entries |
| Start bits | 1 |
| Stop bits | 1 |
| Parity | None |
| RTL language | Verilog HDL |
| Testbench language | Verilog / SystemVerilog |
| Simulation tool | Xilinx Vivado Simulator |
| FPGA target | `xc7a35tcpg236-1` |

## Project Structure

```text
UART_GitHub_Project/
├── rtl/
│   ├── baud_generator.v
│   ├── uart_fifo.v
│   ├── uart_rx.v
│   ├── uart_tx.v
│   └── uart_top.v
├── tb/
│   ├── tb_uart_fifo.v
│   ├── tb_uart_rx.v
│   ├── tb_uart_top.sv
│   ├── tb_uart_top_fifo.sv
│   └── tb_uart_tx.v
├── reports/
│   ├── simulation_pass.png
│   ├── utilization.png
│   └── timing_summary.png
└── README.md
```

## Functional Verification

The UART FIFO loopback test was run in Vivado XSim. Four test bytes were transmitted and received in sequence.

| Test case | Expected byte | Received byte | Result |
|---|---|---|---|
| 1 | `0x41` | `0x41` | PASS |
| 2 | `0x55` | `0x55` | PASS |
| 3 | `0xA5` | `0xA5` | PASS |
| 4 | `0x3C` | `0x3C` | PASS |

**Final simulation result:**
- Expected bytes: 4
- Received bytes: 4
- Errors: 0
- Status: PASS

## FPGA Resource Utilization

The following values were obtained from the Vivado utilization report.

| Resource | Used | Available |
|---|---:|---:|
| Slice LUTs | 180 | 20,800 |
| Slice registers | 174 | 41,600 |
| Bonded I/O | 29 | 106 |
| BUFGCTRL | 1 | 32 |

## Implementation Timing Analysis

The following results were obtained from the Vivado implemented-design timing summary.

| Timing metric | Result |
|---|---:|
| Worst Negative Slack (WNS) | +5.188 ns |
| Worst Hold Slack (WHS) | +0.035 ns |
| Total Negative Slack (TNS) | 0.000 ns |
| Total Hold Slack (THS) | 0.000 ns |
| Setup failing endpoints | 0 |
| Hold failing endpoints | 0 |

Vivado reported that all user-specified timing constraints were met. These results correspond to the constraints configured in the project.

## Tools Used

- Verilog HDL
- SystemVerilog
- AMD/Xilinx Vivado
- Vivado XSim
- FPGA synthesis and implementation reports

## Limitations

- Functional verification was performed in simulation.
- No physical FPGA board testing was performed.
- Power consumption has not been physically measured.
- The reported resource utilization and timing results are tool-generated estimates and analyses for the configured FPGA target.

## Future Improvements

- Add randomized UART transaction testing.
- Verify FIFO overflow and underflow protection.
- Add reset-during-transmission tests.
- Test framing-error detection.
- Expand verification with SystemVerilog assertions.
- Perform physical FPGA validation when hardware is available.

## Author

Developed as a digital design and verification portfolio project using Verilog HDL and Xilinx Vivado.
