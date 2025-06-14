# Vigna Documentation

This directory contains comprehensive documentation for the Vigna RISC-V processor.

## Documentation Overview

### Architecture and Design
- [Architecture Overview](architecture/overview.md) - High-level processor architecture and design principles
- [Interrupt Handling](architecture/interrupts.md) - Machine-level interrupt support and CSR-based interrupt management

### Extensions
- [C Extension](extensions/c-extension.md) - RISC-V Compact instruction extension support
- [M Extension](extensions/m-extension.md) - RISC-V Multiply/Divide extension support
- [Zicsr Extension](extensions/zicsr-extension.md) - Control and Status Register extension support

### Testing
- [Instruction Tests](testing/instruction-tests.md) - Individual RISC-V instruction verification
- [Complete Program Tests](testing/complete-program-tests.md) - Full C program execution testing
- [Configuration Testing](testing/configuration-testing.md) - Multi-configuration testing framework
- [Simulation Guide](testing/simulation.md) - Test suite and simulation documentation

## Quick Navigation

- **Getting Started**: See the main [README.md](../README.md) in the root directory
- **Running Tests**: Start with [Simulation Guide](testing/simulation.md)
- **Understanding Extensions**: Check [M Extension](extensions/m-extension.md), [Zicsr Extension](extensions/zicsr-extension.md), or [C Extension](extensions/c-extension.md)
- **Interrupt Programming**: Review [Interrupt Handling](architecture/interrupts.md)
- **Advanced Testing**: Review [Configuration Testing](testing/configuration-testing.md)

## Contributing to Documentation

When adding new documentation:
1. Place files in the appropriate subdirectory
2. Update this index
3. Ensure cross-references use relative links
4. Follow the existing documentation style