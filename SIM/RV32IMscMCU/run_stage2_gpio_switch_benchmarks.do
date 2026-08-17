transcript file stage2_gpio_switch_benchmarks.log
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
vcom -2008 ../../DUT/RV32IMscMCU/basic_timer.vhd
vcom -2008 ../../DUT/RV32IMscMCU/pushbutton_unit.vhd
vcom -2008 ../../DUT/RV32IMscMCU/interrupt_controller.vhd
vcom -2008 ../../DUT/RV32IMscMCU/mcu_peripherals.vhd
vcom -2008 ../../DUT/RV32IMscMCU/CONTROL.VHD
vcom -2008 ../../DUT/RV32IMscMCU/DMEMORY.VHD
vcom -2008 ../../DUT/RV32IMscMCU/EXECUTE.VHD
vcom -2008 ../../DUT/RV32IMscMCU/IDECODE.VHD
vcom -2008 ../../DUT/RV32IMscMCU/IFETCH.VHD
vcom -2008 ../../DUT/RV32IMscMCU/RV32I_CORE.vhd
vcom -2008 ../../TB/RV32IMscMCU/mcu_sim_harness.vhd
vcom -2008 ../../TB/RV32IMscMCU/tb_stage2_gpio_switch_benchmarks.vhd
vsim -t 1ps -L altera_mf work.tb_stage2_gpio_switch_benchmarks
add wave sim:/tb_stage2_gpio_switch_benchmarks/sysclk sim:/tb_stage2_gpio_switch_benchmarks/reset
add wave -radix hex sim:/tb_stage2_gpio_switch_benchmarks/switches
add wave -radix hex sim:/tb_stage2_gpio_switch_benchmarks/addr1 sim:/tb_stage2_gpio_switch_benchmarks/data1
add wave sim:/tb_stage2_gpio_switch_benchmarks/write1
add wave -radix hex sim:/tb_stage2_gpio_switch_benchmarks/ledr1
add wave -radix hex sim:/tb_stage2_gpio_switch_benchmarks/addr2 sim:/tb_stage2_gpio_switch_benchmarks/data2
add wave sim:/tb_stage2_gpio_switch_benchmarks/write2
add wave -radix hex sim:/tb_stage2_gpio_switch_benchmarks/ledr2
view list
add list sim:/tb_stage2_gpio_switch_benchmarks/sysclk sim:/tb_stage2_gpio_switch_benchmarks/reset
add list -radix hex sim:/tb_stage2_gpio_switch_benchmarks/switches
add list -radix hex sim:/tb_stage2_gpio_switch_benchmarks/addr1 sim:/tb_stage2_gpio_switch_benchmarks/data1
add list sim:/tb_stage2_gpio_switch_benchmarks/write1
add list -radix hex sim:/tb_stage2_gpio_switch_benchmarks/ledr1
add list -radix hex sim:/tb_stage2_gpio_switch_benchmarks/addr2 sim:/tb_stage2_gpio_switch_benchmarks/data2
add list sim:/tb_stage2_gpio_switch_benchmarks/write2
add list -radix hex sim:/tb_stage2_gpio_switch_benchmarks/ledr2
run -all
wave zoom full
if {[file exists stage2_gpio_switch_benchmarks_list.do]} {file delete -force stage2_gpio_switch_benchmarks_list.do}
write format list stage2_gpio_switch_benchmarks_list.do
transcript file ""
