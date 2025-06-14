`ifndef VIGNA_CONF_VH
`define VIGNA_CONF_VH


/* ------------------------------------------------------------------------- */

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

`define VIGNA_CORE_M_EXTENSION

//ToDo
//`define VIGNA_CORE_M_FPGA_FAST

//ToDo
//`define VIGNA_CORE_INTERRUPT

/* C extension support
 * uncomment this line to enable RISC-V Compact instruction extension
 * this allows 16-bit compressed instructions to be used alongside 32-bit instructions */
 
////`define VIGNA_CORE_C_EXTENSION

`define VIGNA_CORE_ALIGNMENT

/*--------------------------------------------------------------------------*/

/* AXI-Lite bus interface option
 * uncomment this line to enable AXI4-Lite interface instead of simple interface
 * when enabled, use vigna_axi module instead of vigna module 
 * This does not have effect actually, so do it at your will.
 */

//`define VIGNA_AXI_LITE_INTERFACE

`endif
