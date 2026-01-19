# Disable numeric warnings
set NumericStdNoWarnings 1

# Set transcript file
transcript on
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns

# Add waves
# add wave -position insertpoint sim:/tb_top/*

# Run simulation
run -all

# If simulation didn't automatically stop, you can stop it here
# quit -sim