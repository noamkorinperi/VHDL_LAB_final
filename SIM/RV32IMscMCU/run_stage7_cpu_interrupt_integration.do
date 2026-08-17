transcript file stage7_cpu_interrupt_integration.log
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
vcom -2008 ../../TB/RV32IMscMCU/tb_stage7_cpu_interrupt_integration.vhd
vsim -t 1ps -L altera_mf work.tb_stage7_cpu_interrupt_integration
add wave sim:/tb_stage7_cpu_interrupt_integration/sys_clk sim:/tb_stage7_cpu_interrupt_integration/reset
add wave -radix hex sim:/tb_stage7_cpu_interrupt_integration/pc sim:/tb_stage7_cpu_interrupt_integration/instruction
add wave sim:/tb_stage7_cpu_interrupt_integration/intr sim:/tb_stage7_cpu_interrupt_integration/inta sim:/tb_stage7_cpu_interrupt_integration/gie sim:/tb_stage7_cpu_interrupt_integration/irq_active
add wave -radix hex sim:/tb_stage7_cpu_interrupt_integration/irq_type sim:/tb_stage7_cpu_interrupt_integration/interrupt_ie sim:/tb_stage7_cpu_interrupt_integration/interrupt_ifg
add wave sim:/tb_stage7_cpu_interrupt_integration/keys_n sim:/tb_stage7_cpu_interrupt_integration/div_busy sim:/tb_stage7_cpu_interrupt_integration/div_done
add wave sim:/tb_stage7_cpu_interrupt_integration/bus_read sim:/tb_stage7_cpu_interrupt_integration/bus_write
add wave -radix hex sim:/tb_stage7_cpu_interrupt_integration/bus_addr sim:/tb_stage7_cpu_interrupt_integration/bus_wdata
view list
add list sim:/tb_stage7_cpu_interrupt_integration/sys_clk sim:/tb_stage7_cpu_interrupt_integration/reset
add list -radix hex sim:/tb_stage7_cpu_interrupt_integration/pc sim:/tb_stage7_cpu_interrupt_integration/instruction
add list sim:/tb_stage7_cpu_interrupt_integration/intr sim:/tb_stage7_cpu_interrupt_integration/inta sim:/tb_stage7_cpu_interrupt_integration/gie sim:/tb_stage7_cpu_interrupt_integration/irq_active
add list -radix hex sim:/tb_stage7_cpu_interrupt_integration/irq_type sim:/tb_stage7_cpu_interrupt_integration/interrupt_ie sim:/tb_stage7_cpu_interrupt_integration/interrupt_ifg
add list sim:/tb_stage7_cpu_interrupt_integration/keys_n sim:/tb_stage7_cpu_interrupt_integration/div_busy sim:/tb_stage7_cpu_interrupt_integration/div_done
add list sim:/tb_stage7_cpu_interrupt_integration/bus_read sim:/tb_stage7_cpu_interrupt_integration/bus_write
add list -radix hex sim:/tb_stage7_cpu_interrupt_integration/bus_addr sim:/tb_stage7_cpu_interrupt_integration/bus_wdata
run -all
wave zoom full
if {[file exists stage7_cpu_interrupt_integration_list.do]} {file delete -force stage7_cpu_interrupt_integration_list.do}
write format list stage7_cpu_interrupt_integration_list.do
transcript file ""
