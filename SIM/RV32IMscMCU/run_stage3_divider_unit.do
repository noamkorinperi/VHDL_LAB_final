transcript file stage3_divider_unit.log
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vcom -2008 ../../DUT/RV32IMscMCU/const_package.vhd
vcom -2008 ../../DUT/RV32IMscMCU/divider_unsigned.vhd
vcom -2008 ../../DUT/RV32IMscMCU/divider_accelerator.vhd
vcom -2008 ../../TB/RV32IMscMCU/tb_stage3_divider_unit.vhd
vsim -t 1ps work.tb_stage3_divider_unit
add wave sim:/tb_stage3_divider_unit/sysclk sim:/tb_stage3_divider_unit/divclk sim:/tb_stage3_divider_unit/reset
add wave sim:/tb_stage3_divider_unit/start sim:/tb_stage3_divider_unit/busy sim:/tb_stage3_divider_unit/done
add wave -radix hex sim:/tb_stage3_divider_unit/operation sim:/tb_stage3_divider_unit/dividend
add wave -radix hex sim:/tb_stage3_divider_unit/divisor sim:/tb_stage3_divider_unit/result
view list
add list sim:/tb_stage3_divider_unit/sysclk sim:/tb_stage3_divider_unit/divclk sim:/tb_stage3_divider_unit/reset
add list sim:/tb_stage3_divider_unit/start sim:/tb_stage3_divider_unit/busy sim:/tb_stage3_divider_unit/done
add list -radix hex sim:/tb_stage3_divider_unit/operation sim:/tb_stage3_divider_unit/dividend
add list -radix hex sim:/tb_stage3_divider_unit/divisor sim:/tb_stage3_divider_unit/result
run -all
wave zoom full
if {[file exists stage3_divider_unit_list.do]} {file delete -force stage3_divider_unit_list.do}
write format list stage3_divider_unit_list.do
transcript file ""
