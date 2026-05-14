# UART with APB Interface - Digital Design Project

## Overview

This project implements a complete UART (Universal Asynchronous Receiver-Transmitter) communication system with an APB (Advanced Peripheral Bus) interface. The design includes separate transmitter (TX) and receiver (RX) modules that can be controlled through an APB slave interface, enabling integration with microcontroller or SoC designs.

The system operates at 9600 baud rate with 8 data bits, 1 start bit, and 1 stop bit (8N1 format). It supports full-duplex communication and includes error detection for frame errors.

## Features

- **APB Interface**: Full APB slave implementation for register access
- **UART TX**: Asynchronous serial data transmission
- **UART RX**: Asynchronous serial data reception with frame error detection
- **Configurable Baud Rate**: Default 9600 baud, programmable via APB registers
- **Reset Support**: Both synchronous and asynchronous reset capabilities
- **Status Monitoring**: Real-time status registers for TX/RX busy states and errors
- **Loopback Testing**: Built-in loopback capability for testing

## Architecture

### Top-Level Block Diagram

```
APB Master <-> APB Slave <-> UART TX Module
                    |
                    v
               UART RX Module
```

### Module Hierarchy

```
APB/
├── APB.v              - APB slave interface with UART integration
└── APB_TB.v           - APB testbench with loopback testing

UART_TX/
├── Top_module_TX.v    - TX top module
├── baud_counter_TX.v  - Baud rate generator for TX
├── bit_select.v       - Bit transmission sequencer
├── frame.v            - Frame formatter (start/stop bits)
├── Mux10x1.v          - 10:1 multiplexer for bit selection
└── Tx_TB.v            - TX standalone testbench

UART_RX/
├── Top_module_RX.v    - RX top module
├── baud_counter_RX.v  - Baud rate generator for RX
├── edge_detector.v    - Start bit edge detection
├── FSM.v              - RX state machine controller
├── SIPO_shift_register.v - Serial-to-parallel converter
└── Rx_TB.v           - RX standalone testbench
```

## APB Register Map

| Address | Register | Access | Description |
|---------|----------|--------|-------------|
| 0x00 | CTRL | R/W | Control register: [31:4] Reserved, [3] RX Reset, [2] TX Reset, [1] RX Enable, [0] TX Enable |
| 0x04 | STATUS | R | Status register: [31:5] Reserved, [4] RX Frame Error, [3] RX Data Valid, [2] TX Complete, [1] RX Busy, [0] TX Busy |
| 0x08 | TXDATA | W | Transmit data register (8-bit) |
| 0x0C | RXDATA | R | Receive data register (8-bit) - Reading clears RX Data Valid flag |
| 0x10 | BAUDDIV | R/W | Baud rate divider (16-bit) |

## Interface Signals

### APB Slave Interface
- `PCLK`: APB clock (100 MHz typical)
- `PRESETn`: APB reset (active low)
- `PADDR[31:0]`: APB address
- `PSEL`: APB select
- `PENABLE`: APB enable
- `PWRITE`: APB write enable
- `PWDATA[31:0]`: APB write data
- `PRDATA[31:0]`: APB read data
- `PREADY`: APB ready signal

### UART Interface
- `uart_tx`: Serial transmit output
- `uart_rx`: Serial receive input

## Baud Rate Configuration

The baud rate is determined by the formula:
```
Baud Rate = PCLK / (BAUDDIV * 16)
```

Where:
- `PCLK` = APB clock frequency (100 MHz)
- `BAUDDIV` = Baud divider register value (default: 10417)
- 16 = Oversampling factor

Default configuration: 100,000,000 / (10417 * 16) ≈ 9600 baud

## UART TX Module

### Features
- 8N1 format (8 data bits, no parity, 1 stop bit)
- Programmable baud rate
- Busy/done status signals
- Synchronous and asynchronous reset support
- Prevents overlapping transmissions

### Operation
1. Load 8-bit data into TXDATA register
2. Set TX Enable bit in CTRL register
3. Monitor TX Busy bit in STATUS register
4. Wait for TX Complete flag in STATUS register

## UART RX Module

### Features
- 8N1 format reception
- Start bit detection with edge triggering
- Frame error detection (invalid stop bit)
- 16x oversampling for reliable reception
- Data valid indication
- Synchronous and asynchronous reset support

### Operation
1. Set RX Enable bit in CTRL register
2. Monitor RX Busy bit in STATUS register
3. Check RX Data Valid flag in STATUS register
4. Read received data from RXDATA register
5. Check for frame errors in STATUS register

## Simulation and Testing

### Prerequisites
- Verilog simulator (ModelSim, Vivado Simulator, or equivalent)
- Support for SystemVerilog constructs

### Running Simulations

#### APB Integration Test
```bash
# Compile and run APB testbench
vlog APB/APB.v APB/APB_TB.v UART_TX/*.v UART_RX/*.v
vsim APB_TB -do "run -all"
```

#### UART TX Standalone Test
```bash
# Compile and run TX testbench
vlog UART_TX/*.v UART_TX/Tx_TB.v
vsim Tx_TB -do "run -all"
```

#### UART RX Standalone Test
```bash
# Compile and run RX testbench
vlog UART_RX/*.v UART_RX/Rx_TB.v
vsim Rx_TB -do "run -all"
```

### Test Scenarios

#### APB Testbench
- Normal byte transmission and reception (loopback)
- Multiple byte sequences
- Overlapping transmissions
- Error-free communication verification

#### TX Testbench
- Normal byte transmission
- All zeros and all ones patterns
- Asynchronous reset during transmission
- Synchronous reset during transmission
- Overlapping transmission attempts

#### RX Testbench
- Normal byte reception
- Various data patterns
- Synchronous reset during reception
- Asynchronous reset during reception
- Frame error detection

## Timing Parameters

- **Clock Period**: 10ns (100 MHz system clock)
- **Bit Period**: ~104.17μs (9600 baud)
- **Oversampling**: 16x for RX reliability
- **Start Bit**: Logic 0
- **Stop Bit**: Logic 1
- **Data Format**: LSB first

## Reset Behavior

### Asynchronous Reset (arst, active low)
- Immediately resets all internal state
- Clears all registers and counters
- Forces UART TX/RX to idle state
- Synchronous to clock edges

### Synchronous Reset (rst, active high)
- Resets state on next clock edge
- Allows completion of current operations
- Controlled via APB CTRL register

## Error Handling

### Frame Error Detection
- Detected when stop bit is not logic 1
- Reported in STATUS register bit 4
- Cleared when RXDATA is read

### Overrun Protection
- TX module ignores new transmission requests while busy
- RX module uses data valid flag to prevent overwrites

## Synthesis Considerations

### Target Technology
- Designed for FPGA/ASIC implementation
- Synchronous design with registered outputs
- No combinational loops

### Resource Usage (Estimated)
- Flip-flops: ~100-150
- LUTs: ~200-300
- Block RAM: None required

### Timing Constraints
- Setup time: Standard for target technology
- Clock-to-output: < 10ns for 100MHz operation
- No false paths or multi-cycle paths

## File Descriptions

### APB Module
- `APB.v`: Main APB slave with UART integration
- `APB_TB.v`: Complete system testbench with loopback

### UART TX Module
- `Top_module_TX.v`: TX top-level integration
- `baud_counter_TX.v`: Baud rate generator
- `bit_select.v`: Transmission bit sequencer
- `frame.v`: Frame assembly (start/data/stop bits)
- `Mux10x1.v`: Bit multiplexer
- `Tx_TB.v`: TX functional testbench

### UART RX Module
- `Top_module_RX.v`: RX top-level integration
- `baud_counter_RX.v`: Baud rate generator with kick-start
- `edge_detector.v`: Start bit edge detection
- `FSM.v`: RX state machine (IDLE/START/DATA/STOP)
- `SIPO_shift_register.v`: Serial-to-parallel conversion
- `Rx_TB.v`: RX functional testbench

## Dependencies

- Verilog 2001 compliant simulator
- No external IP cores required
- Self-contained design

## Future Enhancements

- Parity bit support (even/odd/none)
- Configurable data bits (5-9 bits)
- Multiple stop bit options (1/1.5/2)
- FIFO buffers for TX/RX
- Interrupt generation
- Hardware flow control (RTS/CTS)
- DMA interface support

## Author

Mohammed Magdy Taher
