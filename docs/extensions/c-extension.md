# RISC-V Compact (C) Extension Implementation

This document describes the implementation of optional RISC-V Compact (C) instruction extension support in the Vigna processor.

## Overview

The RISC-V C extension provides 16-bit compressed instructions that can be used alongside standard 32-bit instructions to reduce code size. This implementation adds optional support for the most common C extension instructions while maintaining full backward compatibility.

## Configuration

The C extension is controlled by the `VIGNA_CORE_C_EXTENSION` macro in `vigna_conf.vh`:

```systemverilog
/* C extension support
 * uncomment this line to enable RISC-V Compact instruction extension
 * this allows 16-bit compressed instructions to be used alongside 32-bit instructions */
 
//`define VIGNA_CORE_C_EXTENSION
```

By default, the C extension is **disabled** to maintain backward compatibility.

## Implementation Details

### Instruction Detection

Compressed instructions are detected by their opcode field:
- 16-bit compressed instructions have `inst[1:0] != 2'b11`
- 32-bit standard instructions have `inst[1:0] == 2'b11`

### Fetch Unit Modifications

The fetch unit has been modified to:
1. Detect whether the current instruction is 16-bit or 32-bit
2. Set the `inst_is_16bit` flag accordingly
3. Properly handle PC increment (2 bytes for 16-bit, 4 bytes for 32-bit instructions)

### Instruction Expansion

Compressed instructions are expanded to their 32-bit equivalents using combinational logic:

```systemverilog
wire [31:0] effective_inst;
assign effective_inst = (inst_is_16bit) ? expanded_inst : inst;
```

The expanded instruction is used by all subsequent decode and execute logic, ensuring compatibility with the existing pipeline.

### Supported Instructions

The implementation includes support for the following C extension instruction formats:

#### CI Format (Compressed Immediate)
- `C.LI rd, imm` → `ADDI rd, x0, imm`
- `C.ADDI rd, imm` → `ADDI rd, rd, imm`
- `C.SLLI rd, shamt` → `SLLI rd, rd, shamt`
- `C.LWSP rd, offset` → `LW rd, offset(x2)`

#### CR Format (Compressed Register)
- `C.MV rd, rs2` → `ADD rd, x0, rs2`
- `C.ADD rd, rs2` → `ADD rd, rd, rs2`
- `C.JR rs1` → `JALR x0, 0(rs1)`
- `C.JALR rs1` → `JALR x1, 0(rs1)`

#### CL Format (Compressed Load)
- `C.LW rd', offset(rs1')` → `LW rd', offset(rs1')`

#### CS Format (Compressed Store)
- `C.SW rs2', offset(rs1')` → `SW rs2', offset(rs1')`

#### CSS Format (Compressed Stack-relative Store)
- `C.SWSP rs2, offset` → `SW rs2, offset(x2)`

#### CB Format (Compressed Branch)
- `C.BEQZ rs1', offset` → `BEQ rs1', x0, offset`
- `C.BNEZ rs1', offset` → `BNE rs1', x0, offset`
- `C.SRLI rd', shamt` → `SRLI rd', rd', shamt`
- `C.SRAI rd', shamt` → `SRAI rd', rd', shamt`
- `C.ANDI rd', imm` → `ANDI rd', rd', imm`
- `C.SUB rd', rs2'` → `SUB rd', rd', rs2'`
- `C.XOR rd', rs2'` → `XOR rd', rd', rs2'`
- `C.OR rd', rs2'` → `OR rd', rd', rs2'`
- `C.AND rd', rs2'` → `AND rd', rd', rs2'`

#### CJ Format (Compressed Jump)
- `C.J offset` → `JAL x0, offset`
- `C.JAL offset` → `JAL x1, offset`

#### CIW Format (Compressed Immediate Wide)
- `C.ADDI4SPN rd', nzuimm` → `ADDI rd', x2, nzuimm`

Note: `rd'` and `rs'` refer to the compressed register set (x8-x15).

## Resource Usage

The C extension implementation adds:
- Combinational logic for instruction expansion
- Additional decode signals for C instruction formats
- Modified fetch state machine
- Immediate value generation for C formats

The resource overhead is minimal when disabled and modest when enabled.

## Testing

A test case has been integrated into the comprehensive test suite that verifies basic C instruction functionality when the extension is enabled. The test is automatically skipped when the C extension is disabled.

## Backward Compatibility

The implementation maintains full backward compatibility:
- When `VIGNA_CORE_C_EXTENSION` is undefined, no C extension logic is synthesized
- All existing tests pass with the C extension both enabled and disabled
- Standard 32-bit instructions work identically regardless of C extension setting

## Future Enhancements

Potential future improvements include:
- Support for additional C extension instructions
- Optimization for better timing or resource usage
- Enhanced test coverage
- Support for mixed 16-bit/32-bit instruction streams within the same fetch

## Verification

The implementation has been verified to:
1. ✅ Compile without errors when C extension is disabled
2. ✅ Compile without errors when C extension is enabled  
3. ✅ Pass all existing tests when C extension is disabled
4. ✅ Pass all existing tests when C extension is enabled
5. ✅ Correctly expand C instructions to equivalent 32-bit instructions
6. ✅ Maintain processor functionality and timing

This provides a solid foundation for RISC-V C extension support in the Vigna processor.