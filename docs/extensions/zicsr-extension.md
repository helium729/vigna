# RISC-V Zicsr Extension Implementation

This document describes the implementation of the RISC-V Zicsr (Control and Status Register) extension in the Vigna processor.

## Overview

The RISC-V Zicsr extension adds support for Control and Status Register (CSR) instructions, enabling system-level programming capabilities including interrupt handling, performance monitoring, and processor state management. This implementation provides access to CSRs through dedicated instructions while maintaining compatibility with the base instruction set.

## Configuration

The Zicsr extension is controlled by the `VIGNA_CORE_ZICSR_EXTENSION` macro in the configuration files:

```systemverilog
// ZICSR extension ENABLED
`define VIGNA_CORE_ZICSR_EXTENSION
```

Available configurations that include Zicsr extension:
- `vigna_conf_rv32im_zicsr.vh` - RV32I + M extension + Zicsr extension
- `vigna_conf_rv32imc_zicsr.vh` - RV32I + M extension + C extension + Zicsr extension

## Implementation Architecture

### CSR Address Space

The implementation provides a full 4096-entry CSR register file:

```systemverilog
reg [31:0] csr_regs[4095:0];  // Full CSR address space
```

CSR addresses are extracted from the immediate field of CSR instructions:
```systemverilog
wire [11:0] csr_addr;
assign csr_addr = imm[11:0];  // CSR address is in immediate field
```

### Instruction Detection

CSR instructions are detected as I-type system instructions with specific funct3 values:
- **Opcode**: `7'b1110011` (SYSTEM)
- **funct3**: Determines the CSR operation type

## Supported Instructions

The implementation supports all standard Zicsr instructions:

### Register-based CSR Instructions

| Instruction | funct3 | Description | Operation |
|-------------|---------|-------------|-----------|
| `CSRRW rd, csr, rs1` | `3'b001` | CSR Read/Write | `t = CSR[csr]; CSR[csr] = rs1; rd = t` |
| `CSRRS rd, csr, rs1` | `3'b010` | CSR Read/Set | `t = CSR[csr]; CSR[csr] = t \| rs1; rd = t` |
| `CSRRC rd, csr, rs1` | `3'b011` | CSR Read/Clear | `t = CSR[csr]; CSR[csr] = t & ~rs1; rd = t` |

### Immediate-based CSR Instructions

| Instruction | funct3 | Description | Operation |
|-------------|---------|-------------|-----------|
| `CSRRWI rd, csr, uimm` | `3'b101` | CSR Read/Write Immediate | `t = CSR[csr]; CSR[csr] = uimm; rd = t` |
| `CSRRSI rd, csr, uimm` | `3'b110` | CSR Read/Set Immediate | `t = CSR[csr]; CSR[csr] = t \| uimm; rd = t` |
| `CSRRCI rd, csr, uimm` | `3'b111` | CSR Read/Clear Immediate | `t = CSR[csr]; CSR[csr] = t & ~uimm; rd = t` |

Where `uimm` is a 5-bit zero-extended immediate value.

## Standard CSR Support

### Machine-Level CSRs

When interrupt support is enabled (`VIGNA_CORE_INTERRUPT`), the following standard CSRs are available:

| CSR Name | Address | Description |
|----------|---------|-------------|
| `MSTATUS` | `0x300` | Machine status register |
| `MIE` | `0x304` | Machine interrupt-enable register |
| `MTVEC` | `0x305` | Machine trap-handler base address |
| `MSCRATCH` | `0x340` | Machine scratch register |
| `MEPC` | `0x341` | Machine exception program counter |
| `MCAUSE` | `0x342` | Machine trap cause |
| `MTVAL` | `0x343` | Machine bad address or instruction |
| `MIP` | `0x344` | Machine interrupt pending |

### CSR Access Control

The implementation provides:
- **Read access**: All implemented CSRs can be read
- **Write access**: Follows RISC-V privilege model  
- **Side effects**: CSR writes may trigger hardware behaviors (e.g., interrupt enable)

## Implementation Details

### Instruction Execution Flow

1. **Decode**: CSR instruction detected by opcode and funct3
2. **Read**: Current CSR value is read from register file
3. **Compute**: New value computed based on operation type
4. **Write**: New value written to CSR (if applicable)
5. **Result**: Original CSR value written to destination register

### Operand Handling

```systemverilog
wire [31:0] op1, op2;
assign op1 = is_csr_op ? csr_rval : rs1_val;  // CSR read value for CSR ops
```

For immediate-based instructions, the 5-bit immediate is zero-extended to 32 bits.

### Pipeline Integration

CSR operations execute in execution state `4'b1010`:
- Single-cycle execution
- Atomic read-modify-write behavior
- No pipeline hazards

## CSR Operation Semantics

### CSRRW (Read/Write)
- Atomically swaps values between CSR and register
- If `rd = x0`, the instruction acts as a simple CSR write

### CSRRS (Read/Set)  
- Sets bits in CSR where corresponding `rs1` bits are 1
- If `rs1 = x0`, the instruction acts as a simple CSR read

### CSRRC (Read/Clear)
- Clears bits in CSR where corresponding `rs1` bits are 1  
- If `rs1 = x0`, the instruction acts as a simple CSR read

### Immediate Variants
- Use 5-bit immediate instead of register value
- Zero-extended to 32 bits for computation
- Useful for setting/clearing individual bits

## Integration with Interrupts

When used with interrupt support:
- CSR instructions can modify interrupt enable bits
- MRET instruction uses CSR state for return behavior
- Interrupt handlers use CSRs for context save/restore

## Resource Usage

The Zicsr extension adds:
- 4096 × 32-bit CSR register file
- CSR instruction decode logic
- Read/write access control
- Immediate value handling

Resource overhead is moderate due to the register file size.

## Configuration Examples

### Basic Zicsr Configuration
```systemverilog
`define VIGNA_CORE_ZICSR_EXTENSION  // Enable CSR support
// Base configuration...
```

### Zicsr with Interrupt Support
```systemverilog
`define VIGNA_CORE_ZICSR_EXTENSION  // Enable CSR support  
`define VIGNA_CORE_INTERRUPT        // Enable interrupt handling
// Other configurations...
```

## Testing

The Zicsr extension is verified through:
- Individual CSR instruction testing
- CSR read/write access validation
- Integration testing with interrupt handling
- Privilege level access control testing

## Compatibility

The Zicsr extension implementation:
- ✅ Fully compliant with RISC-V Zicsr specification
- ✅ Compatible with M and C extensions
- ✅ Supports standard machine-level CSRs
- ✅ Enables system-level programming capabilities

## Usage Examples

### Setting Machine Interrupt Enable
```assembly
li t0, 0x800        # External interrupt enable bit
csrrs zero, mie, t0 # Set MIE.MEIE = 1
```

### Reading Machine Status
```assembly
csrr t1, mstatus    # Read current MSTATUS into t1
```

### Atomic Bit Manipulation
```assembly
csrrci t2, mstatus, 0x8  # Clear MIE bit, read old value
```

This implementation provides comprehensive CSR support enabling system-level programming in the Vigna processor.