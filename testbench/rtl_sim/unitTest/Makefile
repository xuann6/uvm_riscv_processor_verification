# Makefile for Verilator-based RISC-V Processor Unit Tests
# Requires: Verilator 5.x+ with --timing support

VERILATOR = verilator

# Paths
PROC_DIR = ../../../processor
TB_FILE  = tb_unittest.sv
TOP_MODULE = tb

# Verilator flags
VFLAGS  = --binary
VFLAGS += --timing
VFLAGS += --public-flat-rw
VFLAGS += --top-module $(TOP_MODULE)
VFLAGS += -I$(PROC_DIR)
VFLAGS += -j 0
VFLAGS += --x-assign 0
VFLAGS += --x-initial 0
VFLAGS += -Wno-WIDTHEXPAND
VFLAGS += -Wno-WIDTHTRUNC
VFLAGS += -Wno-UNUSEDSIGNAL
VFLAGS += -Wno-UNOPTFLAT
VFLAGS += -Wno-BLKSEQ
VFLAGS += -Wno-CASEINCOMPLETE
VFLAGS += -Wno-LATCH
VFLAGS += -Wno-INITIALDLY
VFLAGS += -Wno-MULTIDRIVEN

# Source files
SRC = $(PROC_DIR)/top.sv $(TB_FILE)

# Output directory and binary
OBJ_DIR = obj_dir
BINARY  = $(OBJ_DIR)/V$(TOP_MODULE)

.PHONY: all build run clean rebuild

all: run

build: $(BINARY)

$(BINARY): $(TB_FILE) $(wildcard $(PROC_DIR)/*.sv)
	$(VERILATOR) $(VFLAGS) $(SRC)

run: $(BINARY)
	@echo "=== Running RISC-V Processor Unit Tests ==="
	@$(BINARY)
	@echo "=== Simulation Complete ==="

clean:
	rm -rf $(OBJ_DIR)

rebuild: clean all
