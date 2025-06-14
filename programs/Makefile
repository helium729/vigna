# Makefile for compiling C programs for Vigna RISC-V processor

# Tools
RISCV_PREFIX = riscv64-linux-gnu-
CC = $(RISCV_PREFIX)gcc
OBJCOPY = $(RISCV_PREFIX)objcopy
OBJDUMP = $(RISCV_PREFIX)objdump

# Flags for RV32I base ISA (matches Vigna processor)
CFLAGS = -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -O2 -Wl,--no-warn-rwx-segments

# Directories
BUILD_DIR = build
TOOLS_DIR = ../tools

# Programs
PROGRAMS = simple_test fibonacci_simple sorting_test
ELFS = $(addprefix $(BUILD_DIR)/, $(addsuffix .elf, $(PROGRAMS)))
BINS = $(addprefix $(BUILD_DIR)/, $(addsuffix .bin, $(PROGRAMS)))
MEMFILES = $(addprefix $(BUILD_DIR)/, $(addsuffix .mem, $(PROGRAMS)))
VFILES = $(addprefix $(BUILD_DIR)/, $(addsuffix .vh, $(PROGRAMS)))

.PHONY: all clean disasm

all: $(BUILD_DIR) $(ELFS) $(BINS) $(MEMFILES) $(VFILES)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile C to ELF
$(BUILD_DIR)/%.elf: %.c
	$(CC) $(CFLAGS) $< -o $@

# Extract binary (text section only)
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf
	$(OBJCOPY) -O binary --only-section=.text $< $@

# Convert binary to Verilog memory format
$(BUILD_DIR)/%.mem: $(BUILD_DIR)/%.bin
	python3 $(TOOLS_DIR)/bin_to_verilog_mem.py $< $@

# Convert binary to Verilog include format  
$(BUILD_DIR)/%.vh: $(BUILD_DIR)/%.bin
	python3 $(TOOLS_DIR)/bin_to_verilog_mem.py --format assignments $< $@

# Generate disassembly for debugging
disasm: $(ELFS)
	for elf in $(ELFS); do \
		echo "=== $$elf ===" ; \
		$(OBJDUMP) -d $$elf ; \
		echo ; \
	done

clean:
	rm -rf $(BUILD_DIR)

# Individual program targets
simple_test: $(BUILD_DIR)/simple_test.elf $(BUILD_DIR)/simple_test.bin $(BUILD_DIR)/simple_test.mem
fibonacci_test: $(BUILD_DIR)/fibonacci_test.elf $(BUILD_DIR)/fibonacci_test.bin $(BUILD_DIR)/fibonacci_test.mem
sorting_test: $(BUILD_DIR)/sorting_test.elf $(BUILD_DIR)/sorting_test.bin $(BUILD_DIR)/sorting_test.mem