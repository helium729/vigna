# VIGNA

Vigna is a CPU core that implements [RISC-V Instruction Set](http://riscv.org). Current supported architecture is RV32I/E[M][C]

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

#### C_EXTENSION.md
Documentation for the optional RISC-V Compact (C) instruction extension support, including implementation details, configuration, and supported instructions.

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

##### sim/program_testbench.v
Complete program testbench that executes entire C programs compiled to RISC-V machine code, verifying complex software functionality including algorithms, memory operations, and program termination.

#### programs/
Directory containing C test programs and build system:
- **simple_test.c**: Basic arithmetic and control flow test
- **fibonacci_simple.c**: Fibonacci sequence calculation  
- **sorting_test.c**: Bubble sort algorithm
- **Makefile**: Cross-compilation build system for RISC-V

#### tools/
Utility scripts for program testing:
- **bin_to_verilog_mem.py**: Converts compiled binaries to Verilog memory initialization format

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

# Test all RISC-V configurations
make test_all_configs

# Test specific configurations
make test_rv32i           # Base RV32I only
make test_rv32im          # With multiply/divide
make test_rv32ic          # With compressed instructions
make test_rv32imc_zicsr   # Full featured

# Syntax checking
make enhanced_syntax
make comprehensive_syntax
make syntax_all_configs   # All configurations

# Complete C program tests
make program_quick_test
make program_test_rv32im_zicsr
```

### Configuration Testing
The processor supports multiple RISC-V configurations:
- **RV32I**: Base integer instruction set
- **RV32IM**: Base + multiply/divide extension
- **RV32IC**: Base + compressed instructions
- **RV32IMC**: Base + multiply + compressed
- **RV32E**: Embedded (16 registers)
- **RV32IM+Zicsr**: Base + multiply + CSR support
- **RV32IMC+Zicsr**: Full featured configuration

See [CONFIGURATION_TESTING.md](CONFIGURATION_TESTING.md) for detailed information.

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
- **Complete C programs compiled to RISC-V machine code**

### Complete Program Tests
In addition to instruction-level tests, the framework includes complete program testing:

```bash
# Run complete C program tests
make program_test
make program_quick_test

# Build test programs from C source
cd programs && make all
```

The complete program tests verify:
- C program compilation and execution
- Complex algorithms (Fibonacci, sorting)
- Memory-mapped I/O functionality
- Program termination and result verification

For detailed information, see `COMPLETE_PROGRAM_TESTS.md`.

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

AXI4-Lite Interface
-------------------
The Vigna processor now supports an optional AXI4-Lite interface as an alternative to the simple memory interface. The AXI4-Lite interface provides industry-standard connectivity for integration into larger SoC designs.

#### Using AXI4-Lite Interface

To use the AXI4-Lite interface:

1. Uncomment `#define VIGNA_AXI_LITE_INTERFACE` in `vigna_conf.vh` (optional - for documentation)
2. Use the `vigna_axi` module instead of the `vigna` module:

```verilog
vigna_axi processor (
    .clk(clk),
    .resetn(resetn),
    
    // AXI4-Lite Instruction Read Interface
    .i_arvalid(i_arvalid),
    .i_arready(i_arready),
    .i_araddr(i_araddr),
    .i_arprot(i_arprot),
    .i_rvalid(i_rvalid),
    .i_rready(i_rready),
    .i_rdata(i_rdata),
    .i_rresp(i_rresp),
    
    // AXI4-Lite Data Interface
    .d_arvalid(d_arvalid), .d_arready(d_arready), .d_araddr(d_araddr), .d_arprot(d_arprot),
    .d_rvalid(d_rvalid), .d_rready(d_rready), .d_rdata(d_rdata), .d_rresp(d_rresp),
    .d_awvalid(d_awvalid), .d_awready(d_awready), .d_awaddr(d_awaddr), .d_awprot(d_awprot),
    .d_wvalid(d_wvalid), .d_wready(d_wready), .d_wdata(d_wdata), .d_wstrb(d_wstrb),
    .d_bvalid(d_bvalid), .d_bready(d_bready), .d_bresp(d_bresp)
);
```

#### Interface Comparison

| Feature | Simple Interface | AXI4-Lite Interface |
|---------|------------------|---------------------|
| **Standards Compliance** | Custom Wishbone-like | Industry Standard AXI4-Lite |
| **Integration** | Simple, direct connection | Standard SoC interconnects |
| **Latency** | Single cycle (zero wait-state) | Multi-cycle (address + data phases) |
| **Area** | Minimal | Moderate (wrapper overhead) |
| **Use Case** | Small systems, direct memory | SoC integration, standard interconnects |

#### Testing AXI4-Lite Interface

Run the AXI-specific tests to verify functionality:

```bash
make axi_test        # Run AXI4-Lite testbench
make axi_syntax      # Check AXI code syntax
```

#### Compatibility

- The original `vigna` module with simple interface remains unchanged and fully supported
- Both interfaces can be used in the same project for different instances
- All existing functionality and performance characteristics are preserved
- The AXI wrapper adds approximately ~200 LUTs of overhead

Design Details
------------
See the [wiki](https://github.com/helium729/vigna/wiki) for details in the design.

Future Plans
---------
- Enhanced documentation about design details
- Additional utility modules (GPIO, UART, Timer, Bus adapters)
- ~~AXI4-Lite bus interface adapter~~ ✅ **Completed**
- Interrupt support implementation
- Performance optimizations
