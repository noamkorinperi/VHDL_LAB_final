transcript file stage5_5_smoke_firmware.log
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
vcom -2008 ../../TB/RV32IMscMCU/mcu_interrupt_sim_harness.vhd
vcom -2008 ../../TB/RV32IMscMCU/tb_stage5_5_smoke_firmware.vhd
vsim -t 1ps -L altera_mf work.tb_stage5_5_smoke_firmware
add wave sim:/tb_stage5_5_smoke_firmware/sys_clk sim:/tb_stage5_5_smoke_firmware/reset
add wave -radix hex sim:/tb_stage5_5_smoke_firmware/pc sim:/tb_stage5_5_smoke_firmware/instruction
add wave sim:/tb_stage5_5_smoke_firmware/keys_n sim:/tb_stage5_5_smoke_firmware/ledr
add wave -radix hex sim:/tb_stage5_5_smoke_firmware/switches
add wave sim:/tb_stage5_5_smoke_firmware/hex0 sim:/tb_stage5_5_smoke_firmware/pwm
add wave sim:/tb_stage5_5_smoke_firmware/bus_read sim:/tb_stage5_5_smoke_firmware/bus_write
add wave -radix hex sim:/tb_stage5_5_smoke_firmware/bus_addr sim:/tb_stage5_5_smoke_firmware/bus_wdata
view list
add list sim:/tb_stage5_5_smoke_firmware/sys_clk sim:/tb_stage5_5_smoke_firmware/reset
add list -radix hex sim:/tb_stage5_5_smoke_firmware/pc sim:/tb_stage5_5_smoke_firmware/instruction
add list sim:/tb_stage5_5_smoke_firmware/keys_n sim:/tb_stage5_5_smoke_firmware/ledr
add list -radix hex sim:/tb_stage5_5_smoke_firmware/switches
add list sim:/tb_stage5_5_smoke_firmware/hex0 sim:/tb_stage5_5_smoke_firmware/pwm
add list sim:/tb_stage5_5_smoke_firmware/bus_read sim:/tb_stage5_5_smoke_firmware/bus_write
add list -radix hex sim:/tb_stage5_5_smoke_firmware/bus_addr sim:/tb_stage5_5_smoke_firmware/bus_wdata
run -all
wave zoom full
if {[file exists stage5_5_smoke_firmware_list.do]} {file delete -force stage5_5_smoke_firmware_list.do}
write format list stage5_5_smoke_firmware_list.do
transcript file ""
