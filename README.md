# VIGNA

**A compact RISC-V processor core for embedded systems and FPGA integration**

Vigna is a size-optimized RISC-V CPU core that implements RV32I/E[M][C] instruction sets. Designed for embedded applications, it features a two-stage pipeline architecture with ultra-low resource usage.

[![RISC-V](https://img.shields.io/badge/RISC--V-RV32I%2FE%5BM%5D%5BC%5D-blue)](http://riscv.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-v1.09-orange.svg)]()

## Key Features

- **Ultra-compact**: Only 582 LUTs and 285 FFs on Xilinx Artix-7
- **RISC-V compliant**: Supports RV32I/E with M and C extensions
- **Two-stage pipeline**: ~3 CPI with separated instruction/data buses
- **Configurable**: Multiple ISA variants and extension combinations
- **Integration-ready**: Simple bus interface for FPGA systems

## Architecture

Vigna implements a **two-stage micro-controller style CPU** with parallel state-machine architecture:

- **Pipeline**: Fetch/Decode + Execute stages
- **Bus Interface**: Harvard architecture with separate instruction/data buses  
- **Extensions**: Modular support for M (multiply/divide) and C (compressed) extensions
- **Target Applications**: Auxiliary cores, embedded controllers, IoT devices

For detailed architecture information, see [Architecture Overview](docs/architecture/overview.md).

## Supported Configurations

| Configuration | Base | Multiply | Compressed | Registers | CSR |
|---------------|------|----------|------------|-----------|-----|
| RV32I         | ✓    | ✗        | ✗          | 32        | ✗   |
| RV32IM        | ✓    | ✓        | ✗          | 32        | ✗   |
| RV32IC        | ✓    | ✗        | ✓          | 32        | ✗   |
| RV32IMC       | ✓    | ✓        | ✓          | 32        | ✗   |
| RV32E         | ✓    | ✗        | ✗          | 16        | ✗   |
| +Zicsr        | Any  | Any      | Any        | Any       | ✓   |

## Quick Start

### 1. Get the Code
```bash
git clone https://github.com/helium729/vigna.git
cd vigna
```

### 2. Run Tests (requires iverilog)
```bash
# Install prerequisites (Ubuntu/Debian)
sudo apt update && sudo apt install iverilog gtkwave make

# Run comprehensive tests
make comprehensive_quick_test
```

### 3. Configure the Core

**Easy Configuration with GUI:**
```bash
# Launch the configuration generator GUI
python3 tools/vigna_config_generator.py --gui
```

**Command Line Configuration:**
```bash
# List available predefined configurations
python3 tools/vigna_config_generator.py --list

# Generate RV32IMC configuration
python3 tools/vigna_config_generator.py --config rv32imc --output vigna_conf.vh

# Custom configuration with specific options
python3 tools/vigna_config_generator.py --config rv32i --enable-m-extension --enable-c-extension --output my_config.vh
```

**Manual Configuration:**
Edit `vigna_conf.vh` to enable/disable extensions:
```verilog
// Enable multiply/divide extension
`define VIGNA_CORE_M_EXTENSION

// Enable compressed instruction extension  
`define VIGNA_CORE_C_EXTENSION
```

## Repository Structure

```
vigna/
├── vigna_core.v              # Main processor RTL
├── vigna_coproc.v           # Coprocessor for M extension
├── vigna_conf*.vh           # Configuration files
├── vigna_axi.v              # AXI4-Lite bus adapter
├── Makefile                 # Build system
├── docs/                    # 📁 Documentation
│   ├── architecture/        # Architecture and design docs
│   ├── extensions/          # Extension documentation  
│   └── testing/             # Test guides and references
├── sim/                     # 🧪 Test suite and testbenches
├── programs/                # 📝 C test programs
├── tools/                   # 🛠️ Utility scripts
│   ├── vigna_config_generator.py # Core configuration generator (CLI + GUI)
│   └── bin_to_verilog_mem.py     # Binary to Verilog memory converter
```

## Configuration Generator

The VIGNA processor includes a unified configuration generator that supports both CLI and GUI interfaces for creating custom processor configurations.

### Available Configurations

| Configuration | Extensions | Description |
|---------------|------------|-------------|
| `rv32i` | Base | Minimal RISC-V base configuration |
| `rv32e` | E | Embedded configuration with 16 registers |
| `rv32im` | I + M | Base + Multiply/Divide extension |
| `rv32ic` | I + C | Base + Compressed instruction extension |
| `rv32imc` | I + M + C | Base + Multiply/Divide + Compressed instructions |
| `rv32im_zicsr` | I + M + Zicsr | Base + Multiply/Divide + CSR extension |
| `rv32imc_zicsr` | I + M + C + Zicsr | Full featured configuration |

### Supported Features

- **RISC-V Extensions**: M (multiply/divide), C (compressed), E (embedded), Zicsr (CSR)
- **Performance Options**: Two-stage shift, preload negative, alignment checks
- **Memory Configuration**: Reset addresses, stack pointer initialization
- **Bus Architecture**: Unified vs separate instruction/data buses, AXI4-Lite support
- **Interrupt Support**: Machine-level interrupts with CSR integration

### Usage Examples

```bash
# GUI interface
python3 tools/vigna_config_generator.py --gui

# List all predefined configurations
python3 tools/vigna_config_generator.py --list

# Generate a predefined configuration
python3 tools/vigna_config_generator.py --config rv32imc --output vigna_conf.vh

# Parse existing configuration and modify
python3 tools/vigna_config_generator.py --parse vigna_conf_rv32i.vh --enable-m-extension --output custom.vh

# Custom configuration with validation
python3 tools/vigna_config_generator.py --enable-m-extension --enable-c-extension --validate

# Generate with custom reset address
python3 tools/vigna_config_generator.py --config rv32i --reset-addr "32'h1000_0000" --output boot_config.vh
```

## Documentation

- **[Architecture Overview](docs/architecture/overview.md)** - Detailed processor architecture
- **[Testing Guide](docs/testing/simulation.md)** - How to run and understand tests
- **[Configuration Guide](docs/testing/configuration-testing.md)** - Multi-configuration testing
- **[C Extension](docs/extensions/c-extension.md)** - Compressed instruction support
- **[Complete Program Tests](docs/testing/complete-program-tests.md)** - Full C program testing
- **[Instruction Tests](docs/testing/instruction-tests.md)** - Individual instruction verification

## Integration

### Memory Interface
- **Harvard Architecture**: Separate instruction and data buses
- **Simple Bus Protocol**: Easy integration with memories and peripherals
- **AXI4-Lite Adapter**: `vigna_axi.v` for SoC integration (Zynq, etc.)

### FPGA Integration
```verilog
vigna_core cpu (
    .clk(clk),
    .reset(reset),
    .inst_addr(inst_addr),
    .inst_data(inst_data),
    .data_addr(data_addr),
    .data_write(data_write),
    .data_read(data_read),
    // ... other signals
);
```

## Development Tools

**Core Configuration Generator**: `tools/vigna_config_generator.py`
- **GUI Interface**: Cross-platform configuration with tkinter
- **CLI Interface**: Scriptable configuration generation
- **Predefined Configs**: rv32i, rv32e, rv32im, rv32ic, rv32imc, rv32im_zicsr, rv32imc_zicsr
- **Custom Configs**: Fine-grained control over all processor features
- **Validation**: Automatic dependency checking and conflict resolution

**RISC-V Toolchain**: Get tools from [riscv.org](https://riscv.org/software-status/)
- GCC cross-compiler for RV32I
- Binutils for assembly and linking
- QEMU for emulation (optional)

## Contributing

🐛 **Found a bug?** Create an issue  
🚀 **Have an improvement?** Submit a pull request  
📖 **Documentation unclear?** Let us know  

**All contributions are welcome!**

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
