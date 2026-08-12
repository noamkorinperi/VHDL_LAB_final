transcript file stage0_baseline.log
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vcom -2008 ../../DUT/RV32IMscMCU/cond_compilation_package.vhd
vcom -2008 ../../DUT/RV32IMscMCU/const_package.vhd
vcom -2008 ../../DUT/RV32IMscMCU/mcu_memory_map_pkg.vhd
vcom -2008 ../../DUT/RV32IMscMCU/Multiplier16.vhd
vcom -2008 ../../DUT/RV32IMscMCU/divider_unsigned.vhd
vcom -2008 ../../DUT/RV32IMscMCU/divider_accelerator.vhd
vcom -2008 ../../DUT/RV32IMscMCU/mcu_interconnect.vhd
vcom -2008 ../../DUT/RV32IMscMCU/gpio_peripheral.vhd
vcom -2008 ../../DUT/RV32IMscMCU/CONTROL.VHD
vcom -2008 ../../DUT/RV32IMscMCU/DMEMORY.VHD
vcom -2008 ../../DUT/RV32IMscMCU/EXECUTE.VHD
vcom -2008 ../../DUT/RV32IMscMCU/IDECODE.VHD
vcom -2008 ../../DUT/RV32IMscMCU/IFETCH.VHD
vcom -2008 ../../DUT/RV32IMscMCU/RV32I_CORE.vhd
vcom -2008 ../../TB/RV32IMscMCU/mcu_sim_harness.vhd
vcom -2008 ../../TB/RV32IMscMCU/tb_stage0_baseline.vhd
vsim -t 1ps -L altera_mf work.tb_stage0_baseline
add wave -divider Clocks
add wave sim:/tb_stage0_baseline/sysclk sim:/tb_stage0_baseline/divclk sim:/tb_stage0_baseline/reset
add wave -divider Core
add wave -radix hex sim:/tb_stage0_baseline/pc sim:/tb_stage0_baseline/instruction
add wave -radix hex sim:/tb_stage0_baseline/r1 sim:/tb_stage0_baseline/r2 sim:/tb_stage0_baseline/alu
add wave sim:/tb_stage0_baseline/regwrite sim:/tb_stage0_baseline/memwrite
run -all
wave zoom full
transcript file ""
