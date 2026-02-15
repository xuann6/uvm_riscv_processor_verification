#!/bin/tcsh

source /cae/apps/env/mentor-QuestaSim-2021.2-2_cae2022

export PATH=/cae/apps/data/mentor-2022/questasim/bin:${PATH}

echo "[ Info] Starting Compilation ..."

\rm -rf ./LibTop modelsim.ini  vsim.wlf transcript wave.do
echo "[ Info] Creating Library Object ..."

###################################################################################################
## Create QuestaSim design and library
###################################################################################################
vlib LibTop
vmap -quiet work $PWD/LibTop
echo "[ Info] Compiling Netlist and Testbench ..."

###################################################################################################
## Compile Verilog source and testbench
###################################################################################################
vlog -suppress vlog-2583 -sv +acc -nologo -quiet -work work \
    ../../processor/top.sv \
    ./tb_top.sv 

###################################################################################################
## Optimize design
###################################################################################################
echo "[ Info] Elaborating Design ..."
# Syntax
# vopt -quiet -suppress vopt-143 -work work -check_synthesis -o <name_of_top_design_>_opt <name_of_top_design>

###################################################################################################
## Run simulation
###################################################################################################
echo "[ Info] Starting Simulation ..."
## Syntax
vsim $1 -lib ./LibTop tb -t ps -do ./run.do -sv_seed 10
