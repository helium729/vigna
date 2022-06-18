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
 * uncomment the first line to enable this feature */

//`define VIGNA_CORE_STACK_ADDR_RESET_ENABLE 
`define VIGNA_CORE_STACK_ADDR_RESET_VALUE 32'h0000_1000

/* ------------------------------------------------------------------------- */

`endif