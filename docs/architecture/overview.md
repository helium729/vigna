# Vigna Processor Architecture

## Overview

Vigna is a RISC-V processor core designed for embedded applications and FPGA integration. It implements a two-stage micro-controller style architecture with parallel state-machine design, optimized for size and simplicity.

## Key Architectural Features

### Core Design
- **Architecture**: Two-stage pipeline with parallel state-machine
- **Performance**: Approximate CPI of 3 with separated instruction and data buses  
- **Size Optimized**: Ultra-low resource usage for FPGA implementations
- **Extensible**: Simple, extensible bus interface for system integration

### RISC-V Compliance
- **Base ISA**: RV32I (32-bit integer instruction set)
- **Extensions**: 
  - RV32E (Embedded) - 16 registers instead of 32
  - M Extension - Multiply and divide instructions
  - C Extension - Compressed 16-bit instructions
  - Zicsr - Control and Status Register instructions

### Memory Interface
- **Harvard Architecture**: Separate instruction and data buses
- **Bus Interface**: Simple extensible bus for easy integration
- **Memory Mapping**: Supports memory-mapped I/O

## Resource Usage

### FPGA Implementation
- **Target**: Xilinx Artix-7 series
- **Logic Usage**: 582 LUTs, 285 Flip-Flops
- **Synthesis Tool**: Xilinx Vivado 2020.1 (default strategy)
- **Footprint**: Ultra-low size suitable for auxiliary core applications

## Configuration Options

The processor supports multiple configuration variants:
- **RV32I**: Base integer instruction set
- **RV32IM**: Base + multiply/divide extension
- **RV32IC**: Base + compressed instruction extension  
- **RV32IMC**: Base + multiply + compressed extensions
- **RV32E**: Embedded variant with 16 registers
- **Zicsr Support**: Control and status register access

## Design Philosophy

### Size Optimization
- Micro-controller style architecture prioritizes small size
- Parallel state-machine design reduces logic complexity
- Configurable extensions allow tailoring to specific needs

### Integration Focus
- Simple bus interface for easy system integration
- Designed as auxiliary core for larger FPGA systems
- Low logic payload enables multiple core instantiation

### Extensibility
- Modular design supports adding new instructions
- Bus interface designed for custom peripherals
- Configuration system enables feature selection

## Performance Characteristics

- **Pipeline**: Two-stage (Fetch/Decode + Execute)
- **CPI**: ~3 cycles per instruction (with separated buses)
- **Clock**: Synthesizable to moderate frequencies on FPGA
- **Throughput**: Optimized for embedded control applications

## Bus Interface

The processor features a simple, extensible bus interface:
- **Instruction Bus**: Fetches instructions from memory
- **Data Bus**: Handles load/store operations and memory-mapped I/O
- **Simple Protocol**: Easy to interface with standard memories and peripherals

For detailed implementation information, see the source code documentation and test suite examples.