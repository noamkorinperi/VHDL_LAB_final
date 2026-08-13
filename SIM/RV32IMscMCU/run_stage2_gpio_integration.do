transcript file stage2_gpio_integration.log
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
vcom -2008 ../../TB/RV32IMscMCU/tb_stage2_gpio_integration.vhd
vsim -t 1ps -L altera_mf work.tb_stage2_gpio_integration
add wave sim:/tb_stage2_gpio_integration/sysclk sim:/tb_stage2_gpio_integration/reset
add wave -radix hex sim:/tb_stage2_gpio_integration/bus_addr sim:/tb_stage2_gpio_integration/bus_wdata
add wave sim:/tb_stage2_gpio_integration/bus_write
add wave -radix hex sim:/tb_stage2_gpio_integration/ledr
add wave -radix hex sim:/tb_stage2_gpio_integration/dut/hex0_o sim:/tb_stage2_gpio_integration/dut/hex1_o
add wave -radix hex sim:/tb_stage2_gpio_integration/dut/hex2_o sim:/tb_stage2_gpio_integration/dut/hex3_o
add wave -radix hex sim:/tb_stage2_gpio_integration/dut/hex4_o sim:/tb_stage2_gpio_integration/dut/hex5_o
view list
add list sim:/tb_stage2_gpio_integration/sysclk sim:/tb_stage2_gpio_integration/reset
add list -radix hex sim:/tb_stage2_gpio_integration/bus_addr sim:/tb_stage2_gpio_integration/bus_wdata
add list sim:/tb_stage2_gpio_integration/bus_write
add list -radix hex sim:/tb_stage2_gpio_integration/ledr
add list -radix hex sim:/tb_stage2_gpio_integration/dut/hex0_o sim:/tb_stage2_gpio_integration/dut/hex1_o
add list -radix hex sim:/tb_stage2_gpio_integration/dut/hex2_o sim:/tb_stage2_gpio_integration/dut/hex3_o
add list -radix hex sim:/tb_stage2_gpio_integration/dut/hex4_o sim:/tb_stage2_gpio_integration/dut/hex5_o
run -all
wave zoom full
if {[file exists stage2_gpio_integration_list.do]} {file delete -force stage2_gpio_integration_list.do}
write format list stage2_gpio_integration_list.do
transcript file ""
