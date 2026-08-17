transcript file stage3_divider_integration.log
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
vcom -2008 ../../DUT/RV32IMscMCU/mcu_peripherals.vhd
vcom -2008 ../../DUT/RV32IMscMCU/CONTROL.VHD
vcom -2008 ../../DUT/RV32IMscMCU/DMEMORY.VHD
vcom -2008 ../../DUT/RV32IMscMCU/EXECUTE.VHD
vcom -2008 ../../DUT/RV32IMscMCU/IDECODE.VHD
vcom -2008 ../../DUT/RV32IMscMCU/IFETCH.VHD
vcom -2008 ../../DUT/RV32IMscMCU/RV32I_CORE.vhd
vcom -2008 ../../TB/RV32IMscMCU/mcu_sim_harness.vhd
vcom -2008 ../../TB/RV32IMscMCU/tb_stage3_divider_integration.vhd
vsim -t 1ps -L altera_mf work.tb_stage3_divider_integration
add wave sim:/tb_stage3_divider_integration/sysclk sim:/tb_stage3_divider_integration/divclk sim:/tb_stage3_divider_integration/reset
add wave -radix hex sim:/tb_stage3_divider_integration/pc sim:/tb_stage3_divider_integration/instruction
add wave sim:/tb_stage3_divider_integration/div_busy sim:/tb_stage3_divider_integration/div_done sim:/tb_stage3_divider_integration/regwrite
add wave sim:/tb_stage3_divider_integration/dut/cpu/div_start_w sim:/tb_stage3_divider_integration/dut/cpu/divider_hold_w
add wave sim:/tb_stage3_divider_integration/dut/cpu/div_active_q sim:/tb_stage3_divider_integration/dut/cpu/div_retired_q
add wave -radix hex sim:/tb_stage3_divider_integration/r1 sim:/tb_stage3_divider_integration/r2 sim:/tb_stage3_divider_integration/result
view list
add list sim:/tb_stage3_divider_integration/sysclk sim:/tb_stage3_divider_integration/divclk sim:/tb_stage3_divider_integration/reset
add list -radix hex sim:/tb_stage3_divider_integration/pc sim:/tb_stage3_divider_integration/instruction
add list sim:/tb_stage3_divider_integration/div_busy sim:/tb_stage3_divider_integration/div_done sim:/tb_stage3_divider_integration/regwrite
add list sim:/tb_stage3_divider_integration/dut/cpu/div_start_w sim:/tb_stage3_divider_integration/dut/cpu/divider_hold_w
add list sim:/tb_stage3_divider_integration/dut/cpu/div_active_q sim:/tb_stage3_divider_integration/dut/cpu/div_retired_q
add list -radix hex sim:/tb_stage3_divider_integration/r1 sim:/tb_stage3_divider_integration/r2 sim:/tb_stage3_divider_integration/result
run -all
wave zoom full
if {[file exists stage3_divider_integration_list.do]} {file delete -force stage3_divider_integration_list.do}
write format list stage3_divider_integration_list.do
transcript file ""
