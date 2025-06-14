# Vigna Processor Test Suite

This directory contains comprehensive test suites for the Vigna RISC-V processor core.

## Test Files

### `sim/processor_testbench.v`
Basic testbench that exercises various instruction types and monitors execution.

### `sim/enhanced_processor_testbench.v` 
Enhanced testbench with result verification through memory stores. Tests:
- Arithmetic operations (ADD, SUB, AND, OR, XOR)
- Immediate operations (ADDI, ANDI, ORI, XORI)  
- Load/Store operations (LW, SW)
- Comparison operations (SLT, SLTI)

### `sim/comprehensive_processor_testbench.v`
Comprehensive testbench that adds:
- Shift operations (SLLI, SRLI, SRAI)
- Upper immediate operations (LUI, AUIPC)
- Branch operations (BEQ, BNE, etc.)

### `sim/mem_sim.v`
Memory simulator module that provides instruction and data memory interfaces.

## Build System

The included `Makefile` provides several targets:

### Syntax Checking
```bash
make syntax                    # Check basic testbench
make enhanced_syntax          # Check enhanced testbench  
make comprehensive_syntax     # Check comprehensive testbench
```

### Running Tests
```bash
make test                     # Run basic testbench
make enhanced_test           # Run enhanced testbench
make comprehensive_test      # Run comprehensive testbench

# Quick tests (no waveform generation)
make quick_test
make enhanced_quick_test
make comprehensive_quick_test
```

### Viewing Results
```bash
make wave                    # View basic test waveforms
make enhanced_wave          # View enhanced test waveforms  
make comprehensive_wave     # View comprehensive test waveforms
```

## Test Results

When run successfully, all tests should PASS. Example output:

```
Starting Enhanced Vigna Processor Tests
======================================
Setting up arithmetic test...
Running test: Arithmetic Operations
  PASS: ADD result = 15 (expected 15)
  PASS: SUB result = 5 (expected 5)
  PASS: AND result = 0 (expected 0)
  PASS: OR result = 15 (expected 15)
  PASS: XOR result = 15 (expected 15)

Test Summary:
=============
Tests Passed: 13
Tests Failed: 0
Total Tests: 13
All tests PASSED!
```

## Understanding the Tests

### Verification Strategy
Since we cannot directly access processor registers in the testbench, we use a store-and-verify approach:

1. Load test instructions into instruction memory
2. Execute instructions on the processor
3. Use SW (Store Word) instructions to write register values to data memory
4. Read data memory in testbench to verify expected results

### Test Patterns
Each test follows this pattern:
1. Initialize registers with known values using ADDI
2. Perform operations to test
3. Store results to memory using SW
4. Verify memory contents match expected values

### Instruction Encoding
The testbench includes helper functions to generate properly encoded RISC-V instructions:
- `make_r_type()` - R-type instructions (register-register)
- `make_i_type()` - I-type instructions (immediate)
- `make_s_type()` - S-type instructions (store)
- `make_b_type()` - B-type instructions (branch)
- `make_u_type()` - U-type instructions (upper immediate)

## Requirements

- Icarus Verilog (iverilog) for simulation
- GTKWave for waveform viewing (optional)
- Make for build automation

## Installation

On Ubuntu/Debian:
```bash
sudo apt update
sudo apt install iverilog gtkwave make
```

## Running the Tests

1. Navigate to the project root directory
2. Run the desired test:
   ```bash
   make comprehensive_quick_test
   ```
3. Check the output for PASS/FAIL results

## Adding New Tests

To add new test cases:

1. Create test instructions using the helper functions
2. Store instruction sequence in instruction_memory array
3. Add result verification by storing to data_memory and checking values
4. Follow the existing pattern of setup -> run -> verify

Example:
```verilog
// Test new instruction
instruction_memory[0] = make_i_type(12'd42, 5'd0, 3'b000, 5'd1, 7'b0010011); // ADDI x1, x0, 42
instruction_memory[1] = make_s_type(12'd0, 5'd1, 5'd0, 3'b010, 7'b0100011);  // SW x1, 0(x0)
instruction_memory[2] = make_i_type(-12'd4, 5'd0, 3'b000, 5'd0, 7'b1100111); // Halt

// Verify result
if (data_memory[0] == 32'd42) begin
    $display("  PASS: New test = %d (expected 42)", data_memory[0]);
    test_pass_count = test_pass_count + 1;
end
```

This test infrastructure provides comprehensive verification of the Vigna processor's instruction execution capabilities.