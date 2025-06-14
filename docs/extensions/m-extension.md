# RISC-V M Extension Implementation

This document describes the implementation of the RISC-V M (Multiply/Divide) extension in the Vigna processor.

## Overview

The RISC-V M extension provides integer multiplication and division instructions. This implementation adds support for all standard M extension instructions through a dedicated coprocessor module while maintaining compatibility with the base RV32I instruction set.

## Configuration

The M extension is controlled by the `VIGNA_CORE_M_EXTENSION` macro in the configuration files:

```systemverilog
// M extension ENABLED for RV32IM
`define VIGNA_CORE_M_EXTENSION
```

Available configurations that include M extension:
- `vigna_conf_rv32im.vh` - RV32I base + M extension
- `vigna_conf_rv32im_zicsr.vh` - RV32I base + M extension + Zicsr extension  
- `vigna_conf_rv32imc.vh` - RV32I base + M extension + C extension
- `vigna_conf_rv32imc_zicsr.vh` - RV32I base + M extension + C extension + Zicsr extension

## Implementation Architecture

### Coprocessor Design

The M extension is implemented as a separate coprocessor module (`vigna_m_ext`) in `vigna_coproc.v`:

```systemverilog
module vigna_m_ext(
    input clk,
    input resetn,
    input         valid,
    output reg    ready,
    input  [2:0]  func,
    input  [2:0]  id,
    input  [31:0] op1,
    input  [31:0] op2,
    output [31:0] result
);
```

This design allows the M extension operations to run independently while the main processor waits for completion.

### Instruction Detection

M extension instructions are detected by the following pattern:
- **Opcode**: `7'b0110011` (R-type)
- **funct7**: `7'b0000001` (M extension identifier)
- **funct3**: Determines the specific operation

### Pipeline Integration

When an M extension instruction is detected:
1. The main processor transitions to execution state `4'b1001`
2. Operands and function code are passed to the coprocessor
3. The processor waits for the coprocessor to signal completion via `m_ready`
4. The result is written back to the destination register

## Supported Instructions

The implementation supports all standard RV32M instructions:

### Multiplication Instructions

| Instruction | funct3 | Description | Operation |
|-------------|---------|-------------|-----------|
| `MUL rd, rs1, rs2` | `3'b000` | Multiply | `rd = (rs1 × rs2)[31:0]` |
| `MULH rd, rs1, rs2` | `3'b001` | Multiply High Signed | `rd = (rs1 × rs2)[63:32]` (signed × signed) |
| `MULHSU rd, rs1, rs2` | `3'b010` | Multiply High Signed-Unsigned | `rd = (rs1 × rs2)[63:32]` (signed × unsigned) |
| `MULHU rd, rs1, rs2` | `3'b011` | Multiply High Unsigned | `rd = (rs1 × rs2)[63:32]` (unsigned × unsigned) |

### Division Instructions

| Instruction | funct3 | Description | Operation |
|-------------|---------|-------------|-----------|
| `DIV rd, rs1, rs2` | `3'b100` | Divide Signed | `rd = rs1 ÷ rs2` (signed) |
| `DIVU rd, rs1, rs2` | `3'b101` | Divide Unsigned | `rd = rs1 ÷ rs2` (unsigned) |
| `REM rd, rs1, rs2` | `3'b110` | Remainder Signed | `rd = rs1 mod rs2` (signed) |
| `REMU rd, rs1, rs2` | `3'b111` | Remainder Unsigned | `rd = rs1 mod rs2` (unsigned) |

## Implementation Details

### Sign Handling

The coprocessor correctly handles signed and unsigned operations:
- `MULH`: Both operands treated as signed
- `MULHSU`: First operand signed, second operand unsigned  
- `MULHU`: Both operands treated as unsigned
- `DIV/REM`: Signed division with proper sign extension
- `DIVU/REMU`: Unsigned division

### Division by Zero

Following RISC-V specification:
- Division by zero returns all 1's (`0xFFFFFFFF`)
- Remainder by zero returns the dividend unchanged

### Performance Characteristics

The M extension coprocessor implements:
- **Multi-cycle execution**: Operations typically require multiple clock cycles
- **Handshake protocol**: Uses `valid`/`ready` signals for synchronization
- **Non-blocking**: The main processor pipeline is stalled only during M extension operations

## Resource Usage

When enabled, the M extension adds:
- Dedicated multiplication and division logic
- State machine for multi-cycle operations
- Additional control signals and data paths
- Coprocessor interface logic

The resource overhead is negligible when disabled and moderate when enabled.

## Configuration Examples

### Basic RV32IM Configuration
```systemverilog
`define VIGNA_CORE_M_EXTENSION  // Enable M extension
// Other base configurations...
```

### RV32IM with CSR Support
```systemverilog 
`define VIGNA_CORE_M_EXTENSION       // Enable M extension
`define VIGNA_CORE_ZICSR_EXTENSION   // Enable CSR support
// Other configurations...
```

## Testing

The M extension is thoroughly tested through:
- Individual instruction verification
- Edge case testing (division by zero, overflow conditions)
- Integration testing with other extensions
- Performance validation

## Compatibility

The M extension implementation:
- ✅ Fully compliant with RISC-V M extension specification
- ✅ Compatible with all base instruction sets
- ✅ Works seamlessly with C and Zicsr extensions
- ✅ Maintains backward compatibility when disabled

## Performance Notes

- Multiplication operations typically complete in several clock cycles
- Division operations require more cycles than multiplication
- The coprocessor design allows for future optimization
- Pipeline stalls only occur during M extension instruction execution

This implementation provides a solid foundation for RISC-V M extension support in the Vigna processor.