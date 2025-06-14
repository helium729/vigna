`ifndef VIGNA_CONF_RV32IMF_VH
`define VIGNA_CONF_RV32IMF_VH

/* RV32IMF Configuration - Base integer + Multiply/Divide + Single precision floating point */

/* enabling E extension
 * which disables x16-x32 support */
 
//`define VIGNA_CORE_E_EXTENSION

/* ------------------------------------------------------------------------- */

/* bus binding option
 * comment this line to separate instruction and data bus */

`define VIGNA_TOP_BUS_BINDING

/* ------------------------------------------------------------------------- */

/* core reset address */

`define VIGNA_CORE_RESET_ADDR 32'h0000_0000

/* ------------------------------------------------------------------------- */

/* core stack pointer(x2) reset
 * note that in the spec, the stack pointer should be aligned to 16 bytes
 * uncomment the first line to enable this feature 
 * WARNING: this configuration might cause the area to double, setting 
 * the register with proper software is recommended.
 */

//`define VIGNA_CORE_STACK_ADDR_RESET_ENABLE 
//`define VIGNA_CORE_STACK_ADDR_RESET_VALUE 32'h0000_1000

/* ------------------------------------------------------------------------- */

/* shift instruction options 
 * two-stage shift: make shifts in 4 bits then 1 bit
 * none: shift one bit per cycle
 * two-stage shift provides the best timing (while larger),
 * the 1-bit shift logic has the minimum area  
 */

`define VIGNA_CORE_TWO_STAGE_SHIFT

/*--------------------------------------------------------------------------*/

/* preload negative option
 * preload the negative number for the alu
 * this option uses more resources but provides better timing */

`define VIGNA_CORE_PRELOAD_NEGATIVE

/*--------------------------------------------------------------------------*/

/* M extension support - ENABLED for RV32IMF
 * multiply/divide instructions */

`define VIGNA_CORE_M_EXTENSION

/*--------------------------------------------------------------------------*/

/* F extension support - ENABLED for RV32IMF
 * RISC-V single-precision floating point extension
 * adds 32-bit IEEE 754 floating point support with 32 FP registers */

`define VIGNA_CORE_F_EXTENSION

/*--------------------------------------------------------------------------*/

/* Interrupt support - DISABLED for RV32IMF
 * uncomment to enable interrupt handling */

//`define VIGNA_CORE_INTERRUPT

/* CSR support - DISABLED for RV32IMF  
 * uncomment to enable Control and Status Register support */

//`define VIGNA_CORE_ZICSR_EXTENSION

/* C extension support - DISABLED for RV32IMF
 * uncomment to enable RISC-V Compact instruction extension */

//`define VIGNA_CORE_C_EXTENSION

`define VIGNA_CORE_ALIGNMENT

/*--------------------------------------------------------------------------*/

/* AXI-Lite bus interface option
 * uncomment this line to enable AXI4-Lite interface instead of simple interface
 * when enabled, use vigna_axi module instead of vigna module 
 * This does not have effect actually, so do it at your will.
 */

//`define VIGNA_AXI_LITE_INTERFACE

`endif