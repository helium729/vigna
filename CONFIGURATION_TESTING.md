# Configuration Testing Guide

This document describes the comprehensive configuration testing framework for the Vigna RISC-V processor.

## Overview

The Vigna processor supports multiple RISC-V configurations with different optional extensions. The testing framework validates all supported configurations to ensure robust operation across different use cases.

## Supported Configurations

### Base Configurations
- **RV32I**: Base integer instruction set (32-bit)
- **RV32E**: Embedded base with reduced register file (16 registers)

### Extension Combinations
- **RV32IM**: Base + M extension (multiply/divide)
- **RV32IC**: Base + C extension (compressed instructions)
- **RV32IMC**: Base + M + C extensions
- **RV32IM+Zicsr**: Base + M + Zicsr extensions (CSR support)
- **RV32IMC+Zicsr**: Full featured (all extensions)

## Running Configuration Tests

### Individual Configuration Tests
```bash
make test_rv32i           # Test base RV32I
make test_rv32im          # Test with multiply/divide
make test_rv32ic          # Test with compressed instructions
make test_rv32imc         # Test with multiply + compressed
make test_rv32e           # Test embedded configuration
make test_rv32im_zicsr    # Test with multiply + CSR
make test_rv32imc_zicsr   # Test full featured
```

### All Configuration Tests
```bash
make test_all_configs     # Run all configuration tests
```

### Syntax Validation
```bash
make syntax_all_configs   # Check syntax for all configurations
```

## Configuration Files

The repository includes dedicated configuration files for each variant:

- `vigna_conf.vh` - Default configuration (RV32IM+Zicsr)
- `vigna_conf_rv32i.vh` - Base only
- `vigna_conf_rv32im.vh` - Base + multiply
- `vigna_conf_rv32ic.vh` - Base + compressed
- `vigna_conf_rv32imc.vh` - Base + multiply + compressed
- `vigna_conf_rv32e.vh` - Embedded base
- `vigna_conf_rv32im_zicsr.vh` - Base + multiply + CSR
- `vigna_conf_rv32imc_zicsr.vh` - Full featured
- `vigna_conf_c_test.vh` - C extension testing configuration

## Program Testing with Configurations

C program tests can be run with different configurations:

```bash
make program_test_rv32im_zicsr     # Test C programs with multiply + CSR
make program_test_rv32imc_zicsr    # Test C programs with full features
```

## Test Results

Each configuration test reports:
- Number of tests passed/failed
- Total test count
- Configuration-specific test results
- Cycle counts for performance analysis

## GitHub Actions Integration

The CI/CD pipeline automatically tests all configurations:
- Syntax validation for all configurations
- Functional testing for each configuration
- Program testing when cross-compiler is available

## Extension-Specific Testing

### M Extension (Multiply/Divide)
- Validates multiplication and division operations
- Tests signed/unsigned variants
- Verifies remainder operations

### C Extension (Compressed Instructions)
- Tests 16-bit compressed instruction execution
- Validates compression/decompression logic
- Ensures proper PC alignment

### Zicsr Extension (Control/Status Registers)
- Tests CSR read/write operations
- Validates privilege levels
- Tests CSR instruction variants (CSRRW, CSRRS, CSRRC, etc.)

### E Extension (Embedded)
- Validates reduced register file operation
- Tests with only x0-x15 registers available
- Ensures proper instruction encoding

## Performance Comparison

Different configurations have different performance characteristics:
- **RV32E**: Smallest area, reduced register pressure
- **RV32IC**: Improved code density with compressed instructions
- **RV32IM**: Better performance for arithmetic-intensive code
- **Full featured**: Maximum functionality at cost of area

## Debugging Configuration Issues

If a configuration test fails:

1. Check the specific configuration defines being used
2. Verify the processor core supports the extension
3. Review the test expectations for configuration-specific behavior
4. Use waveform analysis for detailed debugging

## Adding New Configurations

To add a new configuration:

1. Create a new configuration file `vigna_conf_newconfig.vh`
2. Add build targets in the Makefile
3. Add test targets with appropriate defines
4. Update the CI/CD pipeline
5. Document the new configuration

This framework ensures the Vigna processor works correctly across all supported RISC-V configurations and use cases.