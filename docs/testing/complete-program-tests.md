# Complete Program Tests for Vigna RISC-V Processor

This document describes the complete program testing framework that allows testing entire C programs compiled to RISC-V machine code on the Vigna processor.

## Overview

The complete program testing framework extends the existing instruction-level tests to support:
- C program compilation to RISC-V RV32I machine code
- Execution of complete programs on the processor
- Verification of program results through memory-mapped I/O
- Performance measurement through cycle counting

## Directory Structure

```
vigna/
├── programs/                    # C test programs
│   ├── Makefile                # Build system for C programs
│   ├── simple_test.c           # Basic arithmetic and control flow
│   ├── fibonacci_simple.c      # Fibonacci sequence calculation
│   ├── sorting_test.c          # Bubble sort algorithm
│   └── build/                  # Generated files
│       ├── *.elf              # Compiled ELF binaries
│       ├── *.bin              # Raw binary (text section)
│       ├── *.mem              # $readmemh format
│       └── *.vh               # Verilog include format
├── sim/
│   └── program_testbench.v     # Complete program testbench
└── tools/
    └── bin_to_verilog_mem.py   # Binary to Verilog converter
```

## Building Programs

The programs are automatically built using the RISC-V cross-compiler:

```bash
cd programs
make all        # Build all programs
make clean      # Clean generated files
make disasm     # Generate disassembly for debugging
```

### Compilation Settings

Programs are compiled with the following settings:
- Target: `rv32i` (RISC-V 32-bit base integer instruction set)
- ABI: `ilp32` (32-bit integers, longs, and pointers)
- No standard library (`-nostdlib -nostartfiles`)
- Optimization: `-O2`

## Test Programs

### 1. Simple Test (`simple_test.c`)
Tests basic processor functionality:
- Arithmetic operations (addition)
- Loop execution (for loop with accumulation) 
- Conditional execution (ternary operator)
- Memory writes

**Expected Results:**
- test_output[0] = 30 (10 + 20)
- test_output[1] = 15 (1+2+3+4+5)
- test_output[2] = 20 (max of 10, 20)
- test_output[3] = 0xDEADBEEF (completion marker)

### 2. Fibonacci Test (`fibonacci_simple.c`)
Tests iterative computation without arrays:
- Variable assignments and updates
- Loop-based calculation
- Sequential memory writes

**Expected Results:**
- test_output[0..7] = {0, 1, 1, 2, 3, 5, 8, 13} (Fibonacci sequence)
- test_output[8] = 0x12345678 (completion marker)

### 3. Sorting Test (`sorting_test.c`)
Tests more complex algorithms:
- Nested loops
- Array operations
- Conditional swapping

**Expected Results:**
- test_output[0..4] = {1, 2, 5, 8, 9} (sorted from {5, 2, 8, 1, 9})
- test_output[5] = 0xABCDEF00 (completion marker)

## Memory Mapping

Programs use memory-mapped I/O for result verification:
- **Test Output Base**: 0x1000
- **Memory Mapping**: Address 0x1000+N maps to `data_memory[N/4]` in testbench
- **Data Width**: 32-bit words

## Running Tests

```bash
# Quick test (no waveforms)
make program_quick_test

# Full test with waveforms
make program_test

# Syntax checking
make program_syntax

# View waveforms
make program_wave
```

## Test Results

The testbench provides detailed output showing:
- Program loading status
- Execution cycle count
- Memory contents after execution
- Pass/fail status for each test case

Example output:
```
Starting Complete Program Tests for Vigna Processor
=================================================
Loading simple_test program...
Simple test program loaded successfully
Running program:           Simple Arithmetic Test
Program halted at PC=0x00000034 after          54 cycles
Verifying simple test results...
  PASS: Arithmetic test result =         30 (expected 30)
  PASS: Loop test result =         15 (expected 15)
  PASS: Conditional test result =         20 (expected 20)
  PASS: Completion marker = 0xdeadbeef (expected 0xDEADBEEF)

Complete Program Test Summary:
=============================
Tests Passed:          13
Tests Failed:           0
Total Tests:           13
All complete program tests PASSED!
```

## Architecture Verification

The complete program tests verify that the Vigna processor correctly implements:

### Instruction Set Architecture
- **Load/Store Operations**: Memory access with proper addressing
- **Arithmetic Operations**: ADD, ADDI with correct results
- **Logical Operations**: Bitwise operations and comparisons
- **Control Flow**: Loops, branches, and program termination
- **Immediate Handling**: Proper sign extension and value loading

### System Behavior
- **Memory Interface**: Correct read/write operations
- **PC Management**: Sequential execution and branch targets
- **Register File**: Data storage and retrieval
- **Pipeline**: Instruction fetch, decode, and execute phases

### Performance Characteristics
- **Cycle Counts**: Actual vs. expected execution time
- **Memory Latency**: Data access timing
- **Branch Prediction**: Control flow efficiency

## Debugging

### Compilation Issues
- Use `make disasm` to view generated assembly
- Check that target architecture matches processor capabilities
- Verify that no unsupported instructions are generated

### Execution Issues
- Enable debug output in testbench for memory trace
- Check waveforms for signal timing
- Verify memory address mapping

### Result Verification
- Compare actual vs. expected memory contents
- Check completion markers to ensure full execution
- Verify cycle counts are reasonable

## Extending the Tests

To add new test programs:

1. Create new C file in `programs/` directory
2. Add program name to `PROGRAMS` variable in `programs/Makefile`
3. Add load task and verification task to `program_testbench.v`
4. Update test sequence in main initial block

### Guidelines for Test Programs
- Use memory-mapped I/O at base address 0x1000
- Include completion marker for reliable termination detection
- Avoid standard library functions
- Keep stack usage minimal
- Use volatile pointers for memory-mapped I/O

## Integration with Existing Tests

The complete program tests complement the existing instruction-level tests:
- **Instruction Tests**: Verify individual instruction behavior
- **Program Tests**: Verify complete software functionality
- **Combined Coverage**: Ensures both hardware correctness and software compatibility

This provides comprehensive verification from basic instruction execution to real-world software functionality.