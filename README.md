# VIGNA

Vigna is a CPU core that implements [RISC-V Instruction Set](http://riscv.org). Current supported architecture is RV32I/E[M]

Tools (gcc, binutils, etc..) can be obtained via the [RISC-V Website](https://riscv.org/software-status/)

The current version is v1.21

This version is tested with `riscv-tests`, `dhrystone` and `coremark`.

**If you find a bug or have any questions, you can create an issue.**

**Various contributions are welcomed!**


#### Table of Contents

- [Features and Typical Applications](#features-and-typical-applications)
- [Files in this Repository](#files-in-this-repository)
- [Memory Interface](#memory-interface)
- [Design Details](#design-details)
- [Future Plans](#future-plans)

Features and Typical Applications
--------------------------------
Vigna is a two-stage pipelined micro-controller style CPU. The core has an approximate CPI of 3 when the instruction bus and data bus are separated. The micro-controller is size-optimized and has a simple extensible bus.

This core can be integrated into other systems and used as an auxiliary core on a FPGA. Due to the small size and low logic payload, it can be easily adapted into various systems.

Files in this Repository
-----------------
#### README.md
You are reading it right now.

#### vigna_core.v
This Verilog file contains module `vigna`, which is the design rtl code of the core.

#### vigna_top.v
This Verilog file contains module `vigna_top`, which is a wrapper of vigna core.

#### vigna_conf.v
This Verilog file defines the configurations of core vigna.


#### Utils
This directory contains MISC files for adaptions on different platforms.
Design files including gpio and AXI4-Lite adapters are in this directory.


##### axi_adapter
This Verilog file contains a module that adapts current bus into an AXI4-Lite bus interface. This adapter can be used with module vigna or vigna_top.

##### bus2to1.v
This Verilog file contains a module that merge 2 bus interfaces into one. This module uses a simple RS-latch logic. It is possible that warnings mignt occure when using linters like verilator or when synthesizing using yosys, but it should workout fine on FPGAs. If it turned out to be an error that cannot be solved, try fixing this by replacing the RS-latch logic with primitives.

#### bus1to2.v
A bus routing module that decide which way the bus signals should go with the accessing address. This module is recommanded to connect multiple slave devices and MMIOs.

#### gpio.v
GPIOs based on the native bus.

#### timer.v
Module to get cycles(in 64-bits) after reset.

#### uart.v
The uart module for a 2-wire uart interface with a simple fifo buffer.



Memory Interface
-----------------
The memory interface is basically the same with [picorv32](https://github.com/YosysHQ/picorv32). The interface is a simple valid-ready interface that can run one memory transfer at a time:

    output        valid,
    input         ready,
    output [31:0] addr,
    input  [31:0] rdata,
    output [31:0] wdata,
    output [ 3:0] wstrb

The core initiates a memory transfer by asserting `valid`. The valid signal stays high until the peer asserts `ready`. All core outputs are stable over the `valid` period. The transacton is done when both `valid` and `ready` are high. When the transaction is done, the core pulls `valid` down, and the peer should pull `ready` down as soon as it finds `valid` down.

#### Read Transfer

In a read transfer `wstrb` *must* has the value 0 and `wdata` is unused.

The memory reads the address `addr` and makes the read value available on `rdata` in the cycle `ready` is high.

There is no need for an external wait cycle. The memory read can be implemented asynchronously with `ready` going high in the same cycle as `valid`.


#### Write Transfer
In a write transfer `wstrb` is *not* 0 and `rdata` is unused. The memory write the data at `wdata` to the address `addr` and acknowledges the transfer by asserting `ready`.

The 4 bits of `wstrb` are write enables for the four bytes in the addressed
word. Only the 4 values `0000`, `1111`, `0011`, `0001` are possible, i.e. no write, write 32 bits, 
write lower 16 bits, or write a single byte.

There is no need for an external wait cycle. The memory can acknowledge the
write immediately  with `ready` going high in the same cycle as `valid`.

For more examples and explainations, goto [wiki](https://github.com/helium729/vigna/wiki).

Design Details
------------
See the [wiki](https://github.com/helium729/vigna/wiki) for details in the design.

Future Plans
---------
Next: more documentation about design details.
