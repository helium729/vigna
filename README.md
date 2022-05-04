# VIGNA

Vigna is a CPU core that implements [RISC-V RV32I Instruction Set](http://riscv.org).

Tools (gcc, binutils, etc..) can be obtained via the [RISC-V Website](https://riscv.org/software-status/)

The current version is v1.05

**Warning: This project is in devlopment and not fully tested, please don't use in real world!**


#### Table of Contents

- [Features and Typical Applications](#features-and-typical-applications)
- [Files in this Repository](#files-in-this-repository)
- [Performance](#performance)
- [Memory Interface](#memory-interface)
- [Evaluation](#evaluation)
- [Future Plans](#future-plans)

Features and Typical Applications
--------------------------------
Vigna is a two-stage pipelined micro-controller style CPU. The core has an approximate CPI of 3 when the instruction bus and data bus are separated. The micro-controller is size-optimized and has a simple extensible bus.

This core can be integrated into other systems and used as an auxiliary core on FPGA. Due to the small size and low logic load, it can be easily adapted into various systems.

Files in this Repository
-----------------

