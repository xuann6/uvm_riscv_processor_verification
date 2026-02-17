# Makefile for Verilator-based RISC-V Processor UVM Verification
# Requires: Verilator 5.x+ with --timing support
# Requires: UVM 2017-1.0 sources (Accellera 1800.2-2017-1.0)

VERILATOR = verilator

# Root of the repository (resolve relative to this Makefile's location)
MKFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
REPO_ROOT  := $(abspath $(MKFILE_DIR)/../..)

# Paths
PROC_DIR  = $(REPO_ROOT)/processor
TB_FILE   = tb_top.sv
TOP_MODULE = tb

# UVM source path (download from Accellera if not present)
UVM_HOME ?= $(REPO_ROOT)/1800.2-2017-1.0/src

# Verilator flags
VFLAGS  = --binary
VFLAGS += --timing
VFLAGS += --top-module $(TOP_MODULE)
VFLAGS += -I$(PROC_DIR)
VFLAGS += -j 0
VFLAGS += -Wno-fatal
VFLAGS += --x-assign 0
VFLAGS += --x-initial 0
# Note: --public-flat-rw is omitted; it conflicts with Verilator's
# std::process codegen (causes __PVT__ prefix mismatch in C++ output)

# UVM-specific flags (per Antmicro Verilator UVM guide)
VFLAGS += +incdir+$(UVM_HOME)
VFLAGS += +define+UVM_NO_DPI
VFLAGS += +incdir+$(CURDIR)

# Suppress common warnings
VFLAGS += -Wno-WIDTHEXPAND
VFLAGS += -Wno-WIDTHTRUNC
VFLAGS += -Wno-UNUSEDSIGNAL
VFLAGS += -Wno-UNOPTFLAT
VFLAGS += -Wno-BLKSEQ
VFLAGS += -Wno-CASEINCOMPLETE
VFLAGS += -Wno-LATCH
VFLAGS += -Wno-INITIALDLY
VFLAGS += -Wno-MULTIDRIVEN

# Source files: UVM package first, then processor top, then testbench
SRC = $(UVM_HOME)/uvm_pkg.sv $(PROC_DIR)/top.sv $(TB_FILE)	

# Output directory and binary
OBJ_DIR = obj_dir
BINARY  = $(OBJ_DIR)/V$(TOP_MODULE)

# Default test name (override with: make run TEST=riscv_r_type_test)
TEST ?= riscv_base_test

# UVM download URL
UVM_TARBALL_URL = https://www.accellera.org/images/downloads/standards/uvm/Accellera-1800.2-2017-1.0.tar.gz
UVM_PKG_SV = $(UVM_HOME)/uvm_pkg.sv

.PHONY: all build run clean rebuild help setup

all: run

build: $(BINARY)

# Download UVM sources if not present
setup: $(UVM_PKG_SV)

$(UVM_PKG_SV):
	@echo "=== Downloading UVM 2017-1.0 sources ==="
	curl -sL $(UVM_TARBALL_URL) -o /tmp/uvm-2017.tar.gz
	tar -xzf /tmp/uvm-2017.tar.gz -C $(REPO_ROOT)
	rm -f /tmp/uvm-2017.tar.gz
	@echo "=== UVM sources installed to $(REPO_ROOT)/1800.2-2017-1.0 ==="

$(BINARY): $(UVM_PKG_SV) $(TB_FILE) $(wildcard $(PROC_DIR)/*.sv)
	@echo "=== Building with Verilator + UVM ==="
	@echo "UVM_HOME = $(UVM_HOME)"
	$(VERILATOR) $(VFLAGS) $(SRC)

run: $(BINARY)
	@echo "=== Running UVM Test: $(TEST) ==="
	@$(BINARY) +UVM_TESTNAME=$(TEST)
	@echo "=== Simulation Complete ==="

clean:
	rm -rf $(OBJ_DIR)

rebuild: clean all

help:
	@echo "Usage:"
	@echo "  make setup                         - Download UVM 2017-1.0 sources (run once)"
	@echo "  make build                         - Compile (auto-downloads UVM if needed)"
	@echo "  make run                           - Build and run default test (riscv_base_test)"
	@echo "  make run TEST=riscv_r_type_test    - Run R-type instruction test"
	@echo "  make run TEST=riscv_i_type_test    - Run I-type instruction test"
	@echo "  make run TEST=riscv_load_store_test - Run load/store test"
	@echo "  make clean                         - Remove build artifacts"
	@echo "  make rebuild                       - Clean and rebuild"
