transcript file stage4_basic_timer.log
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vcom -2008 ../../DUT/RV32IMscMCU/mcu_memory_map_pkg.vhd
vcom -2008 ../../DUT/RV32IMscMCU/basic_timer.vhd
vcom -2008 ../../TB/RV32IMscMCU/tb_stage4_basic_timer.vhd
vsim -t 1ps work.tb_stage4_basic_timer
add wave sim:/tb_stage4_basic_timer/clk sim:/tb_stage4_basic_timer/reset
add wave -radix hex sim:/tb_stage4_basic_timer/address sim:/tb_stage4_basic_timer/write_data sim:/tb_stage4_basic_timer/read_data
add wave sim:/tb_stage4_basic_timer/read_en sim:/tb_stage4_basic_timer/write_en sim:/tb_stage4_basic_timer/hit
add wave -radix hex sim:/tb_stage4_basic_timer/dut/btctl1_q sim:/tb_stage4_basic_timer/dut/btctl2_q
add wave -radix hex sim:/tb_stage4_basic_timer/dut/btcmpr0_q sim:/tb_stage4_basic_timer/dut/btcmpr1_q
add wave -radix unsigned sim:/tb_stage4_basic_timer/counter sim:/tb_stage4_basic_timer/capture_value
add wave sim:/tb_stage4_basic_timer/pwm sim:/tb_stage4_basic_timer/timer_event
add wave sim:/tb_stage4_basic_timer/compare0_event sim:/tb_stage4_basic_timer/compare1_event sim:/tb_stage4_basic_timer/capture_event
add wave sim:/tb_stage4_basic_timer/capin1 sim:/tb_stage4_basic_timer/capin2
view list
add list sim:/tb_stage4_basic_timer/clk sim:/tb_stage4_basic_timer/reset
add list -radix hex sim:/tb_stage4_basic_timer/address sim:/tb_stage4_basic_timer/write_data sim:/tb_stage4_basic_timer/read_data
add list sim:/tb_stage4_basic_timer/read_en sim:/tb_stage4_basic_timer/write_en sim:/tb_stage4_basic_timer/hit
add list -radix hex sim:/tb_stage4_basic_timer/dut/btctl1_q sim:/tb_stage4_basic_timer/dut/btctl2_q
add list -radix unsigned sim:/tb_stage4_basic_timer/counter sim:/tb_stage4_basic_timer/capture_value
add list sim:/tb_stage4_basic_timer/pwm sim:/tb_stage4_basic_timer/timer_event
add list sim:/tb_stage4_basic_timer/compare0_event sim:/tb_stage4_basic_timer/compare1_event sim:/tb_stage4_basic_timer/capture_event
add list sim:/tb_stage4_basic_timer/capin1 sim:/tb_stage4_basic_timer/capin2
run -all
wave zoom full
if {[file exists stage4_basic_timer_list.do]} {file delete -force stage4_basic_timer_list.do}
write format list stage4_basic_timer_list.do
transcript file ""
