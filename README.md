# VIGNA

Vigna is a CPU core that implements [RISC-V Instruction Set](http://riscv.org). Current supported architecture is RV32I/E[M]

Tools (gcc, binutils, etc..) can be obtained via the [RISC-V Website](https://riscv.org/software-status/)

The current version is v1.09

This version includes a comprehensive test suite with enhanced processor testbenches that verify instruction execution, arithmetic operations, memory operations, and more.

**If you find a bug or have any questions, you can create an issue.**

**Various contributions are welcomed!**


#### Table of Contents

- [Features and Typical Applications](#features-and-typical-applications)
- [Files in this Repository](#files-in-this-repository)
- [Testing](#testing)
- [Memory Interface](#memory-interface)
- [Design Details](#design-details)
- [Future Plans](#future-plans)

Features and Typical Applications
--------------------------------
Vigna is a two-stage micro-controller style CPU with parallele state-machine architecture. The core has an approximate CPI of 3 when the instruction bus and data bus are separated. The micro-controller is size-optimized and has a simple extensible bus.

This core can be integrated into other systems and used as an auxiliary core on a FPGA. Due to the small size and low logic payload, it can be easily adapted into various systems.

This core has a ultra-low size on FPGAs. On Xilinx Artix-7 series FPGAs, it only uses 582 LUTs and 285FFs(Synthesized with Xilinx Vivado 2020.1 with default synthesis strategy).

Files in this Repository
-----------------
#### README.md
You are reading it right now.

#### vigna_core.v
This Verilog file contains module `vigna`, which is the design RTL code of the core.

#### vigna_coproc.v
This Verilog file contains the coprocessor module for M extension support (multiplication and division operations).

#### vigna_conf.vh
This Verilog header file defines the configurations of core vigna, including extension enables, bus binding options, and core parameters.

#### TESTS.md
Documentation explaining the comprehensive test programs created for the Vigna processor, including detailed coverage of RISC-V instruction testing.

#### Makefile
Build system that provides targets for compiling, running tests, syntax checking, and waveform generation for the processor testbenches.

#### sim/
Directory containing comprehensive test suites for the Vigna RISC-V processor core:

##### sim/processor_testbench.v
Basic testbench that exercises various instruction types and monitors execution.

##### sim/enhanced_processor_testbench.v
Enhanced testbench with result verification through memory stores, testing arithmetic operations, immediate operations, load/store operations, and comparison operations.

##### sim/comprehensive_processor_testbench.v
Comprehensive testbench that adds shift operations, upper immediate operations, and branch operations.

##### sim/mem_sim.v
Memory simulator module that provides instruction and data memory interfaces for testbenches.

##### sim/README.md
Detailed documentation for the test suite, including build instructions, test descriptions, and usage examples.



Testing
-------
The Vigna processor includes a comprehensive test suite located in the `sim/` directory. The test infrastructure provides verification of RISC-V instruction execution through multiple testbench levels:

### Requirements
- Icarus Verilog (iverilog) for simulation
- GTKWave for waveform viewing (optional)
- Make for build automation

### Running Tests
```bash
# Quick tests (no waveform generation)
make enhanced_quick_test
make comprehensive_quick_test

# Full tests with waveform generation
make enhanced_test
make comprehensive_test

# Syntax checking
make enhanced_syntax
make comprehensive_syntax
```

### Test Coverage
The test suite covers:
- All basic RISC-V RV32I instructions
- Arithmetic and logical operations (ADD, SUB, AND, OR, XOR, SLT)
- Immediate operations (ADDI, ANDI, ORI, XORI, SLTI)
- Memory operations (LW, SW)
- Shift operations (SLLI, SRLI, SRAI)
- Upper immediate operations (LUI, AUIPC)
- Branch operations (BEQ, BNE, etc.)
- M extension operations (if enabled)

For detailed test documentation, see `TESTS.md` and `sim/README.md`.

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
- Enhanced documentation about design details
- Additional utility modules (GPIO, UART, Timer, Bus adapters)
- AXI4-Lite bus interface adapter
- Interrupt support implementation
- Performance optimizations
