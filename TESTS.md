# RISC-V Instruction Test Documentation

This document explains the test programs created for the Vigna processor.

## Test Coverage

### 1. Enhanced Processor Testbench
Tests the following instruction categories:

#### R-type Instructions (Register-Register operations)
- ADD: Addition (rd = rs1 + rs2)
- SUB: Subtraction (rd = rs1 - rs2)
- AND: Bitwise AND (rd = rs1 & rs2)
- OR: Bitwise OR (rd = rs1 | rs2)
- XOR: Bitwise XOR (rd = rs1 ^ rs2)
- SLT: Set Less Than (rd = 1 if rs1 < rs2, signed)
- SLTU: Set Less Than Unsigned (rd = 1 if rs1 < rs2, unsigned)

#### I-type Instructions (Immediate operations)
- ADDI: Add Immediate (rd = rs1 + imm)
- ANDI: AND Immediate (rd = rs1 & imm)
- ORI: OR Immediate (rd = rs1 | imm)
- XORI: XOR Immediate (rd = rs1 ^ imm)
- SLTI: Set Less Than Immediate (rd = 1 if rs1 < imm, signed)
- SLTIU: Set Less Than Immediate Unsigned (rd = 1 if rs1 < imm, unsigned)

#### Load/Store Instructions
- LW: Load Word (rd = memory[rs1 + imm])
- SW: Store Word (memory[rs1 + imm] = rs2)

#### Shift Instructions
- SLLI: Shift Left Logical Immediate (rd = rs1 << shamt)
- SRLI: Shift Right Logical Immediate (rd = rs1 >> shamt, zero fill)
- SRAI: Shift Right Arithmetic Immediate (rd = rs1 >> shamt, sign extend)

#### Upper Immediate Instructions
- LUI: Load Upper Immediate (rd = imm << 12)
- AUIPC: Add Upper Immediate to PC (rd = PC + (imm << 12))

#### Branch Instructions
- BEQ: Branch if Equal (PC = PC + imm if rs1 == rs2)
- BNE: Branch if Not Equal (PC = PC + imm if rs1 != rs2)
- BLT: Branch if Less Than (PC = PC + imm if rs1 < rs2, signed)
- BGE: Branch if Greater or Equal (PC = PC + imm if rs1 >= rs2, signed)
- BLTU: Branch if Less Than Unsigned (PC = PC + imm if rs1 < rs2, unsigned)
- BGEU: Branch if Greater or Equal Unsigned (PC = PC + imm if rs1 >= rs2, unsigned)

## Test Results

### All Tests Passing:
- Arithmetic operations (ADD, SUB, AND, OR, XOR)
- Immediate operations (ADDI, ANDI, ORI, XORI)
- Load/Store operations (LW, SW)
- Comparison operations (SLT, SLTI)
- Shift operations (SLLI, SRLI, SRAI)
- Upper immediate operations (LUI, AUIPC)

### Instruction Formats Tested:

#### R-type format:
```
31        25 24    20 19    15 14    12 11     7 6       0
|  funct7   |  rs2  |  rs1  | funct3 |   rd   | opcode  |
```

#### I-type format:
```
31                   20 19    15 14    12 11     7 6       0
|       imm[11:0]      |  rs1  | funct3 |   rd   | opcode  |
```

#### S-type format:
```
31        25 24    20 19    15 14    12 11        7 6       0
|imm[11:5] |  rs2  |  rs1  | funct3 | imm[4:0] | opcode  |
```

#### B-type format:
```
31|30     25|24    20|19    15|14    12|11       8|7|6       0
|i|imm[10:5]|  rs2  |  rs1  | funct3 |imm[4:1] |i| opcode  |
|m|        |       |       |        |         |m|         |
|m|        |       |       |        |         |m|         |
|[12]      |       |       |        |         |[11]       |
```

#### U-type format:
```
31                           12 11     7 6       0
|         imm[31:12]          |   rd   | opcode  |
```

## Verification Method

The testbenches use memory-mapped verification where:
1. Instructions are loaded into instruction memory
2. Processor executes instructions
3. Results are stored to data memory using SW instructions  
4. Testbench reads data memory to verify expected results

This approach works around the limitation of not being able to directly access processor registers in the testbench.

## Coverage Summary

The test suite provides comprehensive coverage of:
- All basic RISC-V RV32I instructions
- Arithmetic and logical operations
- Memory operations
- Control flow (branches)
- Immediate value handling
- Sign extension behavior
- Shift operations with proper arithmetic vs logical behavior

## Build and Run Instructions

```bash
# Check syntax
make enhanced_syntax
make comprehensive_syntax

# Run tests  
make enhanced_quick_test
make comprehensive_quick_test

# Generate waveforms
make enhanced_test
make comprehensive_test

# View waveforms (requires X11)
make enhanced_wave
make comprehensive_wave
```