transcript file stage1_interconnect.log
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vcom -2008 ../../DUT/RV32IMscMCU/mcu_memory_map_pkg.vhd
vcom -2008 ../../DUT/RV32IMscMCU/mcu_interconnect.vhd
vcom -2008 ../../TB/RV32IMscMCU/tb_stage1_interconnect.vhd
vsim -t 1ps work.tb_stage1_interconnect
add wave -radix hex sim:/tb_stage1_interconnect/*
run -all
wave zoom full
transcript file ""
