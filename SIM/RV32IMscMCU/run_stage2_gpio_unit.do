transcript file stage2_gpio_unit.log
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vcom -2008 ../../DUT/RV32IMscMCU/mcu_memory_map_pkg.vhd
vcom -2008 ../../DUT/RV32IMscMCU/gpio_peripheral.vhd
vcom -2008 ../../TB/RV32IMscMCU/tb_stage2_gpio_unit.vhd
vsim -t 1ps work.tb_stage2_gpio_unit
add wave -radix hex sim:/tb_stage2_gpio_unit/*
view list
add list -radix hex sim:/tb_stage2_gpio_unit/*
run -all
wave zoom full
if {[file exists stage2_gpio_unit_list.do]} {file delete -force stage2_gpio_unit_list.do}
write format list stage2_gpio_unit_list.do
transcript file ""
