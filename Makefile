# Makefile for Vigna processor tests

# Tools
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Directories
SIM_DIR = sim

# Source files
CORE_SOURCES = vigna_core.v vigna_conf.vh
SIM_SOURCES = $(SIM_DIR)/mem_sim.v

# Test targets
TESTBENCH = processor_testbench
ENHANCED_TESTBENCH = enhanced_processor_testbench
COMPREHENSIVE_TESTBENCH = comprehensive_processor_testbench
INTERRUPT_TESTBENCH = interrupt_test
AXI_TESTBENCH = vigna_axi_testbench
VVP_FILE = $(SIM_DIR)/$(TESTBENCH).vvp
ENHANCED_VVP_FILE = $(SIM_DIR)/$(ENHANCED_TESTBENCH).vvp
COMPREHENSIVE_VVP_FILE = $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).vvp
INTERRUPT_VVP_FILE = $(SIM_DIR)/$(INTERRUPT_TESTBENCH).vvp
AXI_VVP_FILE = $(SIM_DIR)/$(AXI_TESTBENCH).vvp
VCD_FILE = $(SIM_DIR)/processor_test.vcd
ENHANCED_VCD_FILE = $(SIM_DIR)/enhanced_processor_test.vcd
COMPREHENSIVE_VCD_FILE = $(SIM_DIR)/comprehensive_processor_test.vcd
INTERRUPT_VCD_FILE = $(SIM_DIR)/interrupt_test.vcd
AXI_VCD_FILE = $(SIM_DIR)/vigna_axi_test.vcd

# Default target
all: comprehensive_test interrupt_test

# Test all interfaces
test_all: comprehensive_test interrupt_test axi_test

# Compile basic testbench
$(VVP_FILE): $(CORE_SOURCES) $(SIM_DIR)/$(TESTBENCH).v
	$(IVERILOG) -o $(VVP_FILE) -I. $(CORE_SOURCES) $(SIM_DIR)/$(TESTBENCH).v

# Compile enhanced testbench
$(ENHANCED_VVP_FILE): $(CORE_SOURCES) $(SIM_DIR)/$(ENHANCED_TESTBENCH).v
	$(IVERILOG) -o $(ENHANCED_VVP_FILE) -I. $(CORE_SOURCES) $(SIM_DIR)/$(ENHANCED_TESTBENCH).v

# Compile comprehensive testbench
$(COMPREHENSIVE_VVP_FILE): $(CORE_SOURCES) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v
	$(IVERILOG) -o $(COMPREHENSIVE_VVP_FILE) -I. $(CORE_SOURCES) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v

# Compile interrupt testbench
$(INTERRUPT_VVP_FILE): $(CORE_SOURCES) $(SIM_DIR)/$(INTERRUPT_TESTBENCH).v
	$(IVERILOG) -o $(INTERRUPT_VVP_FILE) -I. $(CORE_SOURCES) $(SIM_DIR)/$(INTERRUPT_TESTBENCH).v

# Compile AXI testbench
$(AXI_VVP_FILE): vigna_axi.v $(CORE_SOURCES) $(SIM_DIR)/$(AXI_TESTBENCH).v
	$(IVERILOG) -o $(AXI_VVP_FILE) -I. vigna_axi.v $(CORE_SOURCES) $(SIM_DIR)/$(AXI_TESTBENCH).v

# Run basic simulation
test: $(VVP_FILE)
	cd $(SIM_DIR) && $(VVP) $(TESTBENCH).vvp

# Run enhanced simulation
enhanced_test: $(ENHANCED_VVP_FILE)
	cd $(SIM_DIR) && $(VVP) $(ENHANCED_TESTBENCH).vvp

# Run comprehensive simulation
comprehensive_test: $(COMPREHENSIVE_VVP_FILE)
	cd $(SIM_DIR) && $(VVP) $(COMPREHENSIVE_TESTBENCH).vvp

# Run interrupt simulation
interrupt_test: $(INTERRUPT_VVP_FILE)
	cd $(SIM_DIR) && $(VVP) $(INTERRUPT_TESTBENCH).vvp

# Run AXI simulation
axi_test: $(AXI_VVP_FILE)
	cd $(SIM_DIR) && $(VVP) $(AXI_TESTBENCH).vvp

# View waveforms (requires X11)
wave: $(VCD_FILE)
	$(GTKWAVE) $(VCD_FILE) &

enhanced_wave: $(ENHANCED_VCD_FILE)
	$(GTKWAVE) $(ENHANCED_VCD_FILE) &

comprehensive_wave: $(COMPREHENSIVE_VCD_FILE)
	$(GTKWAVE) $(COMPREHENSIVE_VCD_FILE) &

interrupt_wave: $(INTERRUPT_VCD_FILE)
	$(GTKWAVE) $(INTERRUPT_VCD_FILE) &

axi_wave: $(AXI_VCD_FILE)
	$(GTKWAVE) $(AXI_VCD_FILE) &

# Syntax check
syntax:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(SIM_DIR)/$(TESTBENCH).v

enhanced_syntax:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(SIM_DIR)/$(ENHANCED_TESTBENCH).v

comprehensive_syntax:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v

interrupt_syntax:
	$(IVERILOG) -t null -I. $(CORE_SOURCES) $(SIM_DIR)/$(INTERRUPT_TESTBENCH).v

axi_syntax:
	$(IVERILOG) -t null -I. vigna_axi.v $(CORE_SOURCES) $(SIM_DIR)/$(AXI_TESTBENCH).v

# Clean generated files
clean:
	rm -f $(VVP_FILE) $(VCD_FILE) $(ENHANCED_VVP_FILE) $(ENHANCED_VCD_FILE) $(COMPREHENSIVE_VVP_FILE) $(COMPREHENSIVE_VCD_FILE) $(INTERRUPT_VVP_FILE) $(INTERRUPT_VCD_FILE) $(AXI_VVP_FILE) $(AXI_VCD_FILE)

# Quick test without waveform dumping
quick_test:
	$(IVERILOG) -o /tmp/test.vvp -I. $(CORE_SOURCES) $(SIM_DIR)/$(TESTBENCH).v
	$(VVP) /tmp/test.vvp
	rm -f /tmp/test.vvp

enhanced_quick_test:
	$(IVERILOG) -o /tmp/enhanced_test.vvp -I. $(CORE_SOURCES) $(SIM_DIR)/$(ENHANCED_TESTBENCH).v
	$(VVP) /tmp/enhanced_test.vvp
	rm -f /tmp/enhanced_test.vvp

comprehensive_quick_test:
	$(IVERILOG) -o /tmp/comprehensive_test.vvp -I. $(CORE_SOURCES) $(SIM_DIR)/$(COMPREHENSIVE_TESTBENCH).v
	$(VVP) /tmp/comprehensive_test.vvp
	rm -f /tmp/comprehensive_test.vvp

interrupt_quick_test:
	$(IVERILOG) -o /tmp/interrupt_test.vvp -I. $(CORE_SOURCES) $(SIM_DIR)/$(INTERRUPT_TESTBENCH).v
	$(VVP) /tmp/interrupt_test.vvp
	rm -f /tmp/interrupt_test.vvp

axi_quick_test:
	$(IVERILOG) -o /tmp/axi_test.vvp -I. vigna_axi.v $(CORE_SOURCES) $(SIM_DIR)/$(AXI_TESTBENCH).v
	$(VVP) /tmp/axi_test.vvp
	rm -f /tmp/axi_test.vvp

.PHONY: all test_all test enhanced_test comprehensive_test interrupt_test axi_test wave enhanced_wave comprehensive_wave interrupt_wave axi_wave syntax enhanced_syntax comprehensive_syntax interrupt_syntax axi_syntax clean quick_test enhanced_quick_test comprehensive_quick_test interrupt_quick_test axi_quick_test