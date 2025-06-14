# Makefile for Vigna processor tests

# Tools
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Directories
SIM_DIR = sim

# Source files
CORE_SOURCES = vigna_core.v
SIM_SOURCES = $(SIM_DIR)/mem_sim.v

# Configuration files for different RISC-V variants
CONF_DEFAULT = vigna_conf.vh
CONF_RV32I = vigna_conf_rv32i.vh
CONF_RV32IM = vigna_conf_rv32im.vh
CONF_RV32IC = vigna_conf_rv32ic.vh
CONF_RV32IMC = vigna_conf_rv32imc.vh
CONF_RV32E = vigna_conf_rv32e.vh
CONF_RV32IM_ZICSR = vigna_conf_rv32im_zicsr.vh
CONF_RV32IMC_ZICSR = vigna_conf_rv32imc_zicsr.vh
CONF_C_TEST = vigna_conf_c_test.vh

# Test targets
TESTBENCH = processor_testbench
ENHANCED_TESTBENCH = enhanced_processor_testbench
COMPREHENSIVE_TESTBENCH = comprehensive_processor_testbench
C_EXTENSION_TESTBENCH = c_extension_testbench
PROGRAM_TESTBENCH = program_testbench
INTERRUPT_TESTBENCH = interrupt_test
AXI_TESTBENCH = vigna_axi_testbench
VVP_FILE = $(SIM_DIR)/$(TESTBENCH).vvp
ENHANCED_VVP_FILE = $(SIM_DIR)/$(ENHANCED_TESTBENCH).vvp
COMPREHENSIVE_VVP_FILE = $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).vvp
C_EXTENSION_VVP_FILE = $(SIM_DIR)/$(C_EXTENSION_TESTBENCH).vvp
PROGRAM_VVP_FILE = $(SIM_DIR)/$(PROGRAM_TESTBENCH).vvp
INTERRUPT_VVP_FILE = $(SIM_DIR)/$(INTERRUPT_TESTBENCH).vvp
AXI_VVP_FILE = $(SIM_DIR)/$(AXI_TESTBENCH).vvp
VCD_FILE = $(SIM_DIR)/processor_test.vcd
ENHANCED_VCD_FILE = $(SIM_DIR)/enhanced_processor_test.vcd
COMPREHENSIVE_VCD_FILE = $(SIM_DIR)/comprehensive_processor_test.vcd
C_EXTENSION_VCD_FILE = $(SIM_DIR)/c_extension_test.vcd
PROGRAM_VCD_FILE = $(SIM_DIR)/program_test.vcd
INTERRUPT_VCD_FILE = $(SIM_DIR)/interrupt_test.vcd
AXI_VCD_FILE = $(SIM_DIR)/vigna_axi_test.vcd

# Default target
all: comprehensive_test interrupt_test

# Test all configurations
test_all_configs: test_rv32i test_rv32im test_rv32ic test_rv32imc test_rv32e test_rv32im_zicsr test_rv32imc_zicsr

# Test all interfaces
test_all: comprehensive_test program_test axi_test interrupt_test

# Compile basic testbench
$(VVP_FILE): $(CORE_SOURCES) $(SIM_DIR)/$(TESTBENCH).v $(CONF_DEFAULT)
	$(IVERILOG) -o $(VVP_FILE) -I. $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(TESTBENCH).v

# Compile enhanced testbench
$(ENHANCED_VVP_FILE): $(CORE_SOURCES) $(SIM_DIR)/$(ENHANCED_TESTBENCH).v $(CONF_DEFAULT)
	$(IVERILOG) -o $(ENHANCED_VVP_FILE) -I. $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(ENHANCED_TESTBENCH).v

# Compile comprehensive testbench
$(COMPREHENSIVE_VVP_FILE): $(CORE_SOURCES) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v $(CONF_DEFAULT)
	$(IVERILOG) -o $(COMPREHENSIVE_VVP_FILE) -I. $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v

# Compile C extension testbench
$(C_EXTENSION_VVP_FILE): $(CORE_SOURCES) $(SIM_DIR)/$(C_EXTENSION_TESTBENCH).v $(CONF_C_TEST)
	$(IVERILOG) -o $(C_EXTENSION_VVP_FILE) -I. $(CORE_SOURCES) $(CONF_C_TEST) $(SIM_DIR)/$(C_EXTENSION_TESTBENCH).v

# Compile program testbench
$(PROGRAM_VVP_FILE): $(CORE_SOURCES) $(SIM_DIR)/$(PROGRAM_TESTBENCH).v $(CONF_DEFAULT)
	$(IVERILOG) -o $(PROGRAM_VVP_FILE) -I. $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(PROGRAM_TESTBENCH).v

# Compile interrupt testbench
$(INTERRUPT_VVP_FILE): $(CORE_SOURCES) $(SIM_DIR)/$(INTERRUPT_TESTBENCH).v
	$(IVERILOG) -o $(INTERRUPT_VVP_FILE) -I. $(CORE_SOURCES) $(SIM_DIR)/$(INTERRUPT_TESTBENCH).v

# Compile AXI testbench
$(AXI_VVP_FILE): vigna_axi.v $(CORE_SOURCES) $(SIM_DIR)/$(AXI_TESTBENCH).v $(CONF_DEFAULT)
	$(IVERILOG) -o $(AXI_VVP_FILE) -I. vigna_axi.v $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(AXI_TESTBENCH).v

# Run basic simulation
test: $(VVP_FILE)
	cd $(SIM_DIR) && $(VVP) $(TESTBENCH).vvp

# Run enhanced simulation
enhanced_test: $(ENHANCED_VVP_FILE)
	cd $(SIM_DIR) && $(VVP) $(ENHANCED_TESTBENCH).vvp

# Run comprehensive simulation
comprehensive_test: $(COMPREHENSIVE_VVP_FILE)
	cd $(SIM_DIR) && $(VVP) $(COMPREHENSIVE_TESTBENCH).vvp

# Run C extension simulation
c_extension_test: $(C_EXTENSION_VVP_FILE)
	cd $(SIM_DIR) && $(VVP) $(C_EXTENSION_TESTBENCH).vvp


# Run program simulation
program_test: $(PROGRAM_VVP_FILE)
	cd $(SIM_DIR) && cp ../programs/build/*.mem . && $(VVP) $(PROGRAM_TESTBENCH).vvp

# Run interrupt simulation
interrupt_test: $(INTERRUPT_VVP_FILE)
	cd $(SIM_DIR) && $(VVP) $(INTERRUPT_TESTBENCH).vvp

# Run AXI simulation
axi_test: $(AXI_VVP_FILE)
	cd $(SIM_DIR) && $(VVP) $(AXI_TESTBENCH).vvp

# Configuration-specific tests
test_rv32i:
	@echo "Testing RV32I (Base only) configuration..."
	$(IVERILOG) -o /tmp/rv32i_test.vvp -I. -D VIGNA_CORE_RESET_ADDR=32\'h0000_0000 -D VIGNA_CORE_TWO_STAGE_SHIFT -D VIGNA_CORE_PRELOAD_NEGATIVE -D VIGNA_TOP_BUS_BINDING -D VIGNA_CORE_ALIGNMENT $(CORE_SOURCES) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v
	$(VVP) /tmp/rv32i_test.vvp
	rm -f /tmp/rv32i_test.vvp

test_rv32im:
	@echo "Testing RV32IM (Base + Multiply) configuration..."
	$(IVERILOG) -o /tmp/rv32im_test.vvp -I. -D VIGNA_CORE_RESET_ADDR=32\'h0000_0000 -D VIGNA_CORE_TWO_STAGE_SHIFT -D VIGNA_CORE_PRELOAD_NEGATIVE -D VIGNA_TOP_BUS_BINDING -D VIGNA_CORE_ALIGNMENT -D VIGNA_CORE_M_EXTENSION $(CORE_SOURCES) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v
	$(VVP) /tmp/rv32im_test.vvp
	rm -f /tmp/rv32im_test.vvp

test_rv32ic:
	@echo "Testing RV32IC (Base + Compressed) configuration..."
	$(IVERILOG) -o /tmp/rv32ic_test.vvp -I. -D VIGNA_CORE_RESET_ADDR=32\'h0000_0000 -D VIGNA_CORE_TWO_STAGE_SHIFT -D VIGNA_CORE_PRELOAD_NEGATIVE -D VIGNA_TOP_BUS_BINDING -D VIGNA_CORE_ALIGNMENT -D VIGNA_CORE_C_EXTENSION $(CORE_SOURCES) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v
	$(VVP) /tmp/rv32ic_test.vvp
	rm -f /tmp/rv32ic_test.vvp

test_rv32imc:
	@echo "Testing RV32IMC (Base + Multiply + Compressed) configuration..."
	$(IVERILOG) -o /tmp/rv32imc_test.vvp -I. -D VIGNA_CORE_RESET_ADDR=32\'h0000_0000 -D VIGNA_CORE_TWO_STAGE_SHIFT -D VIGNA_CORE_PRELOAD_NEGATIVE -D VIGNA_TOP_BUS_BINDING -D VIGNA_CORE_ALIGNMENT -D VIGNA_CORE_M_EXTENSION -D VIGNA_CORE_C_EXTENSION $(CORE_SOURCES) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v
	$(VVP) /tmp/rv32imc_test.vvp
	rm -f /tmp/rv32imc_test.vvp

test_rv32e:
	@echo "Testing RV32E (Embedded base) configuration..."
	$(IVERILOG) -o /tmp/rv32e_test.vvp -I. -D VIGNA_CORE_RESET_ADDR=32\'h0000_0000 -D VIGNA_CORE_TWO_STAGE_SHIFT -D VIGNA_CORE_PRELOAD_NEGATIVE -D VIGNA_TOP_BUS_BINDING -D VIGNA_CORE_ALIGNMENT -D VIGNA_CORE_E_EXTENSION $(CORE_SOURCES) $(SIM_DIR)/$(TESTBENCH).v
	$(VVP) /tmp/rv32e_test.vvp
	rm -f /tmp/rv32e_test.vvp

test_rv32im_zicsr:
	@echo "Testing RV32IM+Zicsr (Base + Multiply + CSR) configuration..."
	$(IVERILOG) -o /tmp/rv32im_zicsr_test.vvp -I. -D VIGNA_CORE_RESET_ADDR=32\'h0000_0000 -D VIGNA_CORE_TWO_STAGE_SHIFT -D VIGNA_CORE_PRELOAD_NEGATIVE -D VIGNA_TOP_BUS_BINDING -D VIGNA_CORE_ALIGNMENT -D VIGNA_CORE_M_EXTENSION -D VIGNA_CORE_ZICSR_EXTENSION $(CORE_SOURCES) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v
	$(VVP) /tmp/rv32im_zicsr_test.vvp
	rm -f /tmp/rv32im_zicsr_test.vvp

test_rv32imc_zicsr:
	@echo "Testing RV32IMC+Zicsr (Full featured) configuration..."
	$(IVERILOG) -o /tmp/rv32imc_zicsr_test.vvp -I. -D VIGNA_CORE_RESET_ADDR=32\'h0000_0000 -D VIGNA_CORE_TWO_STAGE_SHIFT -D VIGNA_CORE_PRELOAD_NEGATIVE -D VIGNA_TOP_BUS_BINDING -D VIGNA_CORE_ALIGNMENT -D VIGNA_CORE_M_EXTENSION -D VIGNA_CORE_C_EXTENSION -D VIGNA_CORE_ZICSR_EXTENSION $(CORE_SOURCES) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v
	$(VVP) /tmp/rv32imc_zicsr_test.vvp
	rm -f /tmp/rv32imc_zicsr_test.vvp

# View waveforms (requires X11)
wave: $(VCD_FILE)
	$(GTKWAVE) $(VCD_FILE) &

enhanced_wave: $(ENHANCED_VCD_FILE)
	$(GTKWAVE) $(ENHANCED_VCD_FILE) &

comprehensive_wave: $(COMPREHENSIVE_VCD_FILE)
	$(GTKWAVE) $(COMPREHENSIVE_VCD_FILE) &


program_wave: $(PROGRAM_VCD_FILE)
	$(GTKWAVE) $(PROGRAM_VCD_FILE) &

interrupt_wave: $(INTERRUPT_VCD_FILE)
	$(GTKWAVE) $(INTERRUPT_VCD_FILE) &

axi_wave: $(AXI_VCD_FILE)
	$(GTKWAVE) $(AXI_VCD_FILE) &

c_extension_wave: $(C_EXTENSION_VCD_FILE)
	$(GTKWAVE) $(C_EXTENSION_VCD_FILE) &

# Syntax check
syntax:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(TESTBENCH).v

enhanced_syntax:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(ENHANCED_TESTBENCH).v

comprehensive_syntax:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v

c_extension_syntax:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(CONF_C_TEST) $(SIM_DIR)/$(C_EXTENSION_TESTBENCH).v

program_syntax:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(PROGRAM_TESTBENCH).v

interrupt_syntax:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(SIM_DIR)/$(INTERRUPT_TESTBENCH).v

axi_syntax:
	$(IVERILOG) -t null -I. vigna_axi.v $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(AXI_TESTBENCH).v

# Configuration-specific syntax checks
syntax_all_configs: syntax_rv32i syntax_rv32im syntax_rv32ic syntax_rv32imc syntax_rv32e syntax_rv32im_zicsr syntax_rv32imc_zicsr

syntax_rv32i:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(CONF_RV32I) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v

syntax_rv32im:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(CONF_RV32IM) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v

syntax_rv32ic:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(CONF_RV32IC) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v

syntax_rv32imc:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(CONF_RV32IMC) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v

syntax_rv32e:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(CONF_RV32E) $(SIM_DIR)/$(TESTBENCH).v

syntax_rv32im_zicsr:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(CONF_RV32IM_ZICSR) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v

syntax_rv32imc_zicsr:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(CONF_RV32IMC_ZICSR) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v

# Clean generated files
clean:
	rm -f $(VVP_FILE) $(VCD_FILE) $(ENHANCED_VVP_FILE) $(ENHANCED_VCD_FILE) $(COMPREHENSIVE_VVP_FILE) $(COMPREHENSIVE_VCD_FILE) $(PROGRAM_VVP_FILE) $(PROGRAM_VCD_FILE) $(AXI_VVP_FILE) $(AXI_VCD_FILE) $(INTERRUPT_VVP_FILE)  $(INTERRUPT_VCD_FILE)

# Quick test without waveform dumping
quick_test:
	$(IVERILOG) -o /tmp/test.vvp -I. $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(TESTBENCH).v
	$(VVP) /tmp/test.vvp
	rm -f /tmp/test.vvp

enhanced_quick_test:
	$(IVERILOG) -o /tmp/enhanced_test.vvp -I. $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(ENHANCED_TESTBENCH).v
	$(VVP) /tmp/enhanced_test.vvp
	rm -f /tmp/enhanced_test.vvp

comprehensive_quick_test:
	$(IVERILOG) -o /tmp/comprehensive_test.vvp -I. $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v
	$(VVP) /tmp/comprehensive_test.vvp
	rm -f /tmp/comprehensive_test.vvp

c_extension_quick_test:
	$(IVERILOG) -o /tmp/c_extension_test.vvp -I. $(CORE_SOURCES) $(CONF_C_TEST) $(SIM_DIR)/$(C_EXTENSION_TESTBENCH).v
	$(VVP) /tmp/c_extension_test.vvp
	rm -f /tmp/c_extension_test.vvp


program_quick_test:
	$(IVERILOG) -o /tmp/program_test.vvp -I. $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(PROGRAM_TESTBENCH).v
	cp programs/build/*.mem /tmp/
	$(VVP) /tmp/program_test.vvp
	rm -f /tmp/program_test.vvp

interrupt_quick_test:
	$(IVERILOG) -o /tmp/interrupt_test.vvp -I. $(CORE_SOURCES) $(SIM_DIR)/$(INTERRUPT_TESTBENCH).v
	$(VVP) /tmp/interrupt_test.vvp
	rm -f /tmp/interrupt_test.vvp

axi_quick_test:
	$(IVERILOG) -o /tmp/axi_test.vvp -I. vigna_axi.v $(CORE_SOURCES) $(CONF_DEFAULT) $(SIM_DIR)/$(AXI_TESTBENCH).v
	$(VVP) /tmp/axi_test.vvp
	rm -f /tmp/axi_test.vvp


# Configuration-specific program tests
program_test_rv32im_zicsr:
	@echo "Testing C programs with RV32IM+Zicsr configuration..."
	$(IVERILOG) -o /tmp/program_rv32im_zicsr.vvp -I. $(CORE_SOURCES) $(CONF_RV32IM_ZICSR) $(SIM_DIR)/$(PROGRAM_TESTBENCH).v
	cp programs/build/*.mem /tmp/
	$(VVP) /tmp/program_rv32im_zicsr.vvp
	rm -f /tmp/program_rv32im_zicsr.vvp

program_test_rv32imc_zicsr:
	@echo "Testing C programs with RV32IMC+Zicsr configuration..."
	$(IVERILOG) -o /tmp/program_rv32imc_zicsr.vvp -I. $(CORE_SOURCES) $(CONF_RV32IMC_ZICSR) $(SIM_DIR)/$(PROGRAM_TESTBENCH).v
	cp programs/build/*.mem /tmp/
	$(VVP) /tmp/program_rv32imc_zicsr.vvp
	rm -f /tmp/program_rv32imc_zicsr.vvp

.PHONY: all test_all_configs test_all test enhanced_test comprehensive_test program_test axi_test interrupt_test \
	test_rv32i test_rv32im test_rv32ic test_rv32imc test_rv32e test_rv32im_zicsr test_rv32imc_zicsr \
	wave enhanced_wave comprehensive_wave program_wave axi_wave \
	syntax enhanced_syntax comprehensive_syntax program_syntax axi_syntax \
	syntax_all_configs syntax_rv32i syntax_rv32im syntax_rv32ic syntax_rv32imc syntax_rv32e syntax_rv32im_zicsr syntax_rv32imc_zicsr \
	clean quick_test enhanced_quick_test comprehensive_quick_test program_quick_test axi_quick_test \
	program_test_rv32im_zicsr program_test_rv32imc_zicsr
