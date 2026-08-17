transcript file stage6_interrupt_controller.log
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vcom -2008 ../../DUT/RV32IMscMCU/mcu_memory_map_pkg.vhd
vcom -2008 ../../DUT/RV32IMscMCU/interrupt_controller.vhd
vcom -2008 ../../TB/RV32IMscMCU/tb_stage6_interrupt_controller.vhd
vsim -t 1ps work.tb_stage6_interrupt_controller
add wave sim:/tb_stage6_interrupt_controller/clk sim:/tb_stage6_interrupt_controller/reset
add wave -radix hex sim:/tb_stage6_interrupt_controller/address sim:/tb_stage6_interrupt_controller/write_data sim:/tb_stage6_interrupt_controller/read_data
add wave sim:/tb_stage6_interrupt_controller/read_en sim:/tb_stage6_interrupt_controller/write_en sim:/tb_stage6_interrupt_controller/hit
add wave sim:/tb_stage6_interrupt_controller/timer_event sim:/tb_stage6_interrupt_controller/key_event
add wave sim:/tb_stage6_interrupt_controller/gie sim:/tb_stage6_interrupt_controller/inta sim:/tb_stage6_interrupt_controller/intr
add wave -radix hex sim:/tb_stage6_interrupt_controller/ie_value sim:/tb_stage6_interrupt_controller/ifg_value sim:/tb_stage6_interrupt_controller/irq_type
view list
add list sim:/tb_stage6_interrupt_controller/clk sim:/tb_stage6_interrupt_controller/reset
add list -radix hex sim:/tb_stage6_interrupt_controller/address sim:/tb_stage6_interrupt_controller/write_data sim:/tb_stage6_interrupt_controller/read_data
add list sim:/tb_stage6_interrupt_controller/read_en sim:/tb_stage6_interrupt_controller/write_en sim:/tb_stage6_interrupt_controller/hit
add list sim:/tb_stage6_interrupt_controller/timer_event sim:/tb_stage6_interrupt_controller/key_event
add list sim:/tb_stage6_interrupt_controller/gie sim:/tb_stage6_interrupt_controller/inta sim:/tb_stage6_interrupt_controller/intr
add list -radix hex sim:/tb_stage6_interrupt_controller/ie_value sim:/tb_stage6_interrupt_controller/ifg_value sim:/tb_stage6_interrupt_controller/irq_type
run -all
wave zoom full
if {[file exists stage6_interrupt_controller_list.do]} {file delete -force stage6_interrupt_controller_list.do}
write format list stage6_interrupt_controller_list.do
transcript file ""
