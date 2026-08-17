transcript file stage5_pushbuttons.log
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vcom -2008 ../../DUT/RV32IMscMCU/mcu_memory_map_pkg.vhd
vcom -2008 ../../DUT/RV32IMscMCU/pushbutton_unit.vhd
vcom -2008 ../../TB/RV32IMscMCU/tb_stage5_pushbuttons.vhd
vsim -t 1ps work.tb_stage5_pushbuttons
add wave sim:/tb_stage5_pushbuttons/clk sim:/tb_stage5_pushbuttons/reset
add wave sim:/tb_stage5_pushbuttons/keys_n sim:/tb_stage5_pushbuttons/buttons sim:/tb_stage5_pushbuttons/press_event
add wave -radix hex sim:/tb_stage5_pushbuttons/address sim:/tb_stage5_pushbuttons/read_data
add wave sim:/tb_stage5_pushbuttons/read_en sim:/tb_stage5_pushbuttons/hit
add wave sim:/tb_stage5_pushbuttons/dut/key_sync1_n_q sim:/tb_stage5_pushbuttons/dut/key_sync2_n_q
add wave -radix unsigned sim:/tb_stage5_pushbuttons/key1_events sim:/tb_stage5_pushbuttons/key2_events sim:/tb_stage5_pushbuttons/key3_events
view list
add list sim:/tb_stage5_pushbuttons/clk sim:/tb_stage5_pushbuttons/reset
add list sim:/tb_stage5_pushbuttons/keys_n sim:/tb_stage5_pushbuttons/buttons sim:/tb_stage5_pushbuttons/press_event
add list -radix hex sim:/tb_stage5_pushbuttons/address sim:/tb_stage5_pushbuttons/read_data
add list sim:/tb_stage5_pushbuttons/read_en sim:/tb_stage5_pushbuttons/hit
add list sim:/tb_stage5_pushbuttons/dut/key_sync1_n_q sim:/tb_stage5_pushbuttons/dut/key_sync2_n_q
add list -radix unsigned sim:/tb_stage5_pushbuttons/key1_events sim:/tb_stage5_pushbuttons/key2_events sim:/tb_stage5_pushbuttons/key3_events
run -all
wave zoom full
if {[file exists stage5_pushbuttons_list.do]} {file delete -force stage5_pushbuttons_list.do}
write format list stage5_pushbuttons_list.do
transcript file ""
