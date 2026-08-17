transcript file stage4_5_peripheral_integration.log
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vcom -2008 ../../DUT/RV32IMscMCU/mcu_memory_map_pkg.vhd
vcom -2008 ../../DUT/RV32IMscMCU/gpio_peripheral.vhd
vcom -2008 ../../DUT/RV32IMscMCU/basic_timer.vhd
vcom -2008 ../../DUT/RV32IMscMCU/pushbutton_unit.vhd
vcom -2008 ../../DUT/RV32IMscMCU/mcu_peripherals.vhd
vcom -2008 ../../TB/RV32IMscMCU/tb_stage4_5_peripheral_integration.vhd
vsim -t 1ps work.tb_stage4_5_peripheral_integration
add wave sim:/tb_stage4_5_peripheral_integration/clk sim:/tb_stage4_5_peripheral_integration/reset
add wave -radix hex sim:/tb_stage4_5_peripheral_integration/address sim:/tb_stage4_5_peripheral_integration/write_data sim:/tb_stage4_5_peripheral_integration/read_data
add wave sim:/tb_stage4_5_peripheral_integration/read_en sim:/tb_stage4_5_peripheral_integration/write_en sim:/tb_stage4_5_peripheral_integration/hit
add wave -radix hex sim:/tb_stage4_5_peripheral_integration/switches sim:/tb_stage4_5_peripheral_integration/ledr
add wave sim:/tb_stage4_5_peripheral_integration/keys_n sim:/tb_stage4_5_peripheral_integration/button_state sim:/tb_stage4_5_peripheral_integration/key_event
add wave -radix unsigned sim:/tb_stage4_5_peripheral_integration/timer_count sim:/tb_stage4_5_peripheral_integration/timer_capture
add wave sim:/tb_stage4_5_peripheral_integration/pwm sim:/tb_stage4_5_peripheral_integration/timer_event
view list
add list sim:/tb_stage4_5_peripheral_integration/clk sim:/tb_stage4_5_peripheral_integration/reset
add list -radix hex sim:/tb_stage4_5_peripheral_integration/address sim:/tb_stage4_5_peripheral_integration/write_data sim:/tb_stage4_5_peripheral_integration/read_data
add list sim:/tb_stage4_5_peripheral_integration/read_en sim:/tb_stage4_5_peripheral_integration/write_en sim:/tb_stage4_5_peripheral_integration/hit
add list -radix hex sim:/tb_stage4_5_peripheral_integration/switches sim:/tb_stage4_5_peripheral_integration/ledr
add list sim:/tb_stage4_5_peripheral_integration/keys_n sim:/tb_stage4_5_peripheral_integration/button_state sim:/tb_stage4_5_peripheral_integration/key_event
add list -radix unsigned sim:/tb_stage4_5_peripheral_integration/timer_count sim:/tb_stage4_5_peripheral_integration/timer_capture
add list sim:/tb_stage4_5_peripheral_integration/pwm sim:/tb_stage4_5_peripheral_integration/timer_event
run -all
wave zoom full
if {[file exists stage4_5_peripheral_integration_list.do]} {file delete -force stage4_5_peripheral_integration_list.do}
write format list stage4_5_peripheral_integration_list.do
transcript file ""
