# RISC-V F Extension Implementation

This document describes the implementation of the RISC-V F (Single-Precision Floating Point) extension in the Vigna processor.

## Overview

The RISC-V F extension provides single-precision (32-bit) IEEE 754 floating point operations. This implementation adds support for floating point load/store instructions and basic floating point operations through a dedicated floating point register file and coprocessor integration.

## Configuration

The F extension is controlled by the `VIGNA_CORE_F_EXTENSION` macro in the configuration files:

```systemverilog
// F extension ENABLED for RV32IF
`define VIGNA_CORE_F_EXTENSION
```

Available configurations that include F extension:
- `vigna_conf_rv32if.vh` - RV32I base + F extension
- `vigna_conf_rv32imf.vh` - RV32I base + M extension + F extension

## Implementation Architecture

### Floating Point Register File

The implementation includes a dedicated 32-entry floating point register file:

```systemverilog
reg [31:0] fp_regs[31:0];  // 32 floating point registers (f0-f31)
```

Each register stores a 32-bit IEEE 754 single-precision floating point value.

### Instruction Detection

Floating point instructions are detected by their opcode fields:

- **FLW (Floating Point Load Word)**: `opcode = 7'b0000111` (0x07), `funct3 = 3'b010`
- **FSW (Floating Point Store Word)**: `opcode = 7'b0100111` (0x27), `funct3 = 3'b010`
- **FP Computational**: `opcode = 7'b1010011` (0x53) - Framework ready

### Pipeline Integration

The F extension integrates seamlessly with the existing pipeline:

1. **Instruction Type Recognition**: FLW instructions extend I-type, FSW instructions extend S-type
2. **Address Calculation**: Uses existing ALU for address computation (base + offset)
3. **Memory Interface**: Uses existing memory interface with proper handshaking
4. **Register File Access**: Dedicated FP register file with proper timing

## Supported Instructions

The implementation currently supports the following F extension instructions:

### Load/Store Instructions

| Instruction | Opcode | funct3 | Description | Status |
|-------------|---------|---------|-------------|---------|
| `FLW fd, offset(rs1)` | `0x07` | `010` | Load 32-bit FP value from memory | ✅ Fully implemented |
| `FSW fs2, offset(rs1)` | `0x27` | `010` | Store 32-bit FP value to memory | ✅ Fully implemented |

### Computational Instructions (Framework Ready)

| Instruction | Opcode | funct7 | Description | Status |
|-------------|---------|---------|-------------|---------|
| `FADD.S fd, fs1, fs2` | `0x53` | `0x00` | Single-precision add | 🔧 Framework ready |
| `FSUB.S fd, fs1, fs2` | `0x53` | `0x04` | Single-precision subtract | 🔧 Framework ready |
| `FMUL.S fd, fs1, fs2` | `0x53` | `0x08` | Single-precision multiply | 🔧 Framework ready |
| `FMV.W.X fd, rs1` | `0x53` | `0x78` | Move word from integer to FP | 🔧 Framework ready |
| `FMV.X.W rd, fs1` | `0x53` | `0x70` | Move word from FP to integer | 🔧 Framework ready |

## Implementation Details

### Memory Access

FP load and store operations follow the same memory interface as integer operations:

- **Address Calculation**: `base_address + sign_extended_offset`
- **Data Width**: Always 32-bit (4 bytes) with `d_wstrb = 4'b1111`
- **Alignment**: Word-aligned access (addresses must be multiples of 4)

### Register File Management

- **Register Count**: 32 registers (f0-f31)
- **Reset Value**: All registers initialized to `0x00000000` (positive zero)
- **Access Pattern**: Single-cycle read, single-cycle write
- **Bypass Logic**: Proper hazard handling with state flags

### State Machine Integration

The F extension uses dedicated state tracking:

```systemverilog
reg is_fp_load;           // Flag for FP load in progress
reg [4:0] fp_wb_reg;      // FP destination register for loads
```

This ensures proper timing and avoids conflicts with integer operations.

## Resource Usage

The F extension implementation adds:

- **32 x 32-bit FP registers**: ~1KB additional register file
- **FP coprocessor module**: Combinational logic for basic operations
- **State tracking logic**: Minimal additional control logic
- **Modified decode logic**: Extensions to existing instruction decode

The resource overhead is minimal when disabled and modest when enabled.

## Testing

Comprehensive tests verify F extension functionality:

- **FLW Test**: Verified loading of IEEE 754 values (1.0f, 2.0f) into FP registers
- **FSW Test**: Verified storing of FP register values to correct memory addresses
- **Integration Test**: Verified seamless operation with existing instruction pipeline
- **Regression Test**: Verified no impact on existing processor functionality

Example test results:
```
✅ FLW f1, 0(x0) loads 0x3F800000 (1.0f) correctly
✅ FLW f2, 4(x0) loads 0x40000000 (2.0f) correctly  
✅ FSW f1, 16(x0) stores to address 0x10 with data 0x3F800000
✅ All existing tests pass with F extension enabled
```

## Compliance

The F extension implementation provides:

- ✅ **IEEE 754 single-precision format support**
- ✅ **Standard RISC-V F extension instruction formats**  
- ✅ **Proper integration with base integer instruction set**
- ✅ **Backward compatibility when disabled**

## Future Enhancements

Potential improvements include:

- **Full arithmetic operations**: Complete implementation of FADD.S, FSUB.S, FMUL.S, FDIV.S
- **Comparison operations**: FEQ.S, FLT.S, FLE.S, FCLASS.S
- **Conversion operations**: FCVT.W.S, FCVT.S.W with proper rounding
- **Fused multiply-add**: FMADD.S, FMSUB.S, FNMADD.S, FNMSUB.S
- **Exception handling**: Proper IEEE 754 exception flags and handling

## Conclusion

This implementation provides a solid foundation for RISC-V F extension support in the Vigna processor, with working load/store operations and framework ready for additional floating point arithmetic instructions.