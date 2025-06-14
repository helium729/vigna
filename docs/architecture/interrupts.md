# Interrupt Handling Architecture

This document describes the interrupt handling capabilities of the Vigna processor, including machine-level interrupt support and the associated Control and Status Registers (CSRs).

## Overview

The Vigna processor supports machine-level interrupt handling following the RISC-V privileged architecture specification. The interrupt system provides hardware interrupt detection, automatic context switching, and software interrupt handling capabilities.

## Configuration

Interrupt support is controlled by the `VIGNA_CORE_INTERRUPT` macro in configuration files:

```systemverilog
// Enable interrupt support
`define VIGNA_CORE_INTERRUPT
```

**Note**: Interrupt support requires the Zicsr extension to be enabled as it relies on CSR instructions for interrupt management:

```systemverilog
`define VIGNA_CORE_ZICSR_EXTENSION  // Required for interrupt support
`define VIGNA_CORE_INTERRUPT        // Enable interrupt handling
```

Currently, interrupt support is disabled by default in all configuration files but can be enabled by uncommenting the define.

## Interrupt Sources

The Vigna processor supports three standard RISC-V interrupt sources:

### Hardware Interrupt Inputs

```systemverilog
input ext_irq,      // External interrupt (MEI)
input timer_irq,    // Timer interrupt (MTI)  
input soft_irq,     // Software interrupt (MSI)
```

| Signal | Description | Priority |
|--------|-------------|----------|
| `ext_irq` | External interrupt from external interrupt controller | Highest (1) |
| `timer_irq` | Timer interrupt from machine timer | Medium (2) |
| `soft_irq` | Software interrupt triggered by software | Lowest (3) |

### Interrupt Priority

Interrupts are prioritized in the following order:
1. **External interrupt** (`ext_irq`) - Highest priority
2. **Timer interrupt** (`timer_irq`) - Medium priority  
3. **Software interrupt** (`soft_irq`) - Lowest priority

## Control and Status Registers

### Machine Status Register (MSTATUS) - 0x300

Key fields in MSTATUS:
- **MIE (bit 3)**: Machine Interrupt Enable - Global interrupt enable
- **MPIE (bit 7)**: Machine Previous Interrupt Enable - Saves MIE on trap entry

### Machine Interrupt Enable (MIE) - 0x304

Controls which interrupt sources are enabled:
- **MSIE (bit 3)**: Machine Software Interrupt Enable
- **MTIE (bit 7)**: Machine Timer Interrupt Enable  
- **MEIE (bit 11)**: Machine External Interrupt Enable

### Machine Interrupt Pending (MIP) - 0x344

Shows which interrupts are currently pending:
- **MSIP (bit 3)**: Machine Software Interrupt Pending
- **MTIP (bit 7)**: Machine Timer Interrupt Pending
- **MEIP (bit 11)**: Machine External Interrupt Pending

### Machine Trap Vector (MTVEC) - 0x305

Contains the base address of the machine trap handler.

### Machine Exception Program Counter (MEPC) - 0x341

Stores the PC value where execution should resume after handling the interrupt.

### Machine Cause (MCAUSE) - 0x342

Indicates the cause of the trap:
- **MSB = 1**: Interrupt (bit 31 set)
- **Exception Code**: Identifies the interrupt source

### Machine Trap Value (MTVAL) - 0x343

Contains additional information about the trap (typically 0 for interrupts).

### Machine Scratch (MSCRATCH) - 0x340

Temporary storage for machine mode software.

## Interrupt Handling Flow

### 1. Interrupt Detection

The processor continuously monitors for enabled and pending interrupts:

```systemverilog
// Check for pending and enabled interrupts
wire ext_irq_ready, timer_irq_ready, soft_irq_ready;
assign ext_irq_ready   = ext_irq & mie[11] & global_irq_enable;   // MEI
assign timer_irq_ready = timer_irq & mie[7] & global_irq_enable;  // MTI  
assign soft_irq_ready  = soft_irq & mie[3] & global_irq_enable;   // MSI

// Interrupt request (prioritized)
wire interrupt_request;
assign interrupt_request = ext_irq_ready | timer_irq_ready | soft_irq_ready;
```

### 2. Interrupt Entry

When an interrupt is taken:
1. **PC Save**: Current PC is saved to MEPC
2. **Disable Interrupts**: MIE bit is cleared, MPIE saves the old MIE value
3. **Set Cause**: MCAUSE is set with interrupt cause code
4. **Jump to Handler**: PC is set to MTVEC base address

### 3. Interrupt Handler Execution

The interrupt handler (software) typically:
1. Save necessary registers to stack
2. Identify interrupt source (read MCAUSE)
3. Handle the specific interrupt
4. Restore registers from stack
5. Execute MRET to return

### 4. Interrupt Return (MRET)

The MRET instruction performs:
1. **Restore PC**: PC is restored from MEPC
2. **Restore Interrupts**: MIE is restored from MPIE, MPIE is set to 1
3. **Resume Execution**: Normal execution continues

## Implementation Details

### Interrupt Detection Logic

```systemverilog
// Global interrupt enable from mstatus.MIE (bit 3)
wire global_irq_enable;
assign global_irq_enable = mstatus[3];

// Individual interrupt enables from MIE register
wire ext_irq_enable   = mie[11];  // MEIE
wire timer_irq_enable = mie[7];   // MTIE  
wire soft_irq_enable  = mie[3];   // MSIE
```

### Context Switching

The processor automatically handles:
- PC preservation in MEPC
- Interrupt enable state management
- Cause code generation
- Trap vector lookup

### MRET Instruction

```systemverilog
// MRET instruction (Machine Return from trap)
wire is_mret;
assign is_mret = i_type_system && funct3 == 3'b000 && 
                 rs2 == 5'b00010 && rd == 5'b00000 && rs1 == 5'b00000;
```

MRET execution:
```systemverilog
if (is_mret) begin
    // Restore PC and interrupt enable
    csr_regs[CSR_MSTATUS][3] <= mstatus[7];  // Restore MIE from MPIE
    csr_regs[CSR_MSTATUS][7] <= 1;           // Set MPIE to 1
    ex_jump <= 1;                            // Jump to MEPC
end
```

## Interrupt Cause Codes

Following RISC-V specification:

| Interrupt Source | Cause Code | Description |
|------------------|------------|-------------|
| Software Interrupt | 3 | Machine software interrupt |
| Timer Interrupt | 7 | Machine timer interrupt |
| External Interrupt | 11 | Machine external interrupt |

The MSB (bit 31) of MCAUSE is set to 1 for all interrupts.

## Programming Model

### Enabling Interrupts

```assembly
# Enable global interrupts
li t0, 0x8
csrrs zero, mstatus, t0    # Set MSTATUS.MIE

# Enable specific interrupt sources  
li t0, 0x888               # Enable MSI, MTI, MEI
csrrs zero, mie, t0        # Set MIE bits
```

### Interrupt Handler Template

```assembly
interrupt_handler:
    # Save context (simplified)
    addi sp, sp, -32
    sw ra, 28(sp)
    sw t0, 24(sp)
    sw t1, 20(sp)
    # ... save other registers
    
    # Read interrupt cause
    csrr t0, mcause
    
    # Handle specific interrupts
    # ... interrupt-specific code
    
    # Restore context
    lw ra, 28(sp)
    lw t0, 24(sp)
    lw t1, 20(sp)
    # ... restore other registers
    addi sp, sp, 32
    
    # Return from interrupt
    mret
```

### Setting Trap Vector

```assembly
# Set interrupt handler address
la t0, interrupt_handler
csrw mtvec, t0
```

## Hardware Requirements

For proper interrupt operation:
- External interrupt controller must assert `ext_irq` appropriately
- Timer module must assert `timer_irq` on timer expiration
- Software can trigger `soft_irq` through memory-mapped registers

## Resource Usage

Interrupt support adds:
- Additional CSR registers for interrupt management
- Interrupt detection and priority logic
- Context switching hardware
- MRET instruction support

## Testing

Interrupt functionality can be tested through:
- Software interrupt generation
- Timer interrupt simulation
- External interrupt injection
- Context switching verification
- Nested interrupt handling (if supported)

## Limitations

Current implementation limitations:
- Machine mode only (no user/supervisor modes)
- No nested interrupt support
- Basic interrupt prioritization

## Compatibility

The interrupt system:
- ✅ Follows RISC-V privileged architecture specification
- ✅ Compatible with standard interrupt controllers
- ✅ Works with CSR-based software
- ✅ Supports standard interrupt handling patterns

This interrupt implementation provides a solid foundation for system-level programming and real-time applications using the Vigna processor.