transcript file stage7_divider_interrupt_order.log
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vcom -2008 ../../DUT/RV32IMscMCU/cond_compilation_package.vhd
vcom -2008 ../../DUT/RV32IMscMCU/const_package.vhd
vcom -2008 ../../DUT/RV32IMscMCU/Multiplier16.vhd
vcom -2008 ../../DUT/RV32IMscMCU/divider_unsigned.vhd
vcom -2008 ../../DUT/RV32IMscMCU/divider_accelerator.vhd
vcom -2008 ../../DUT/RV32IMscMCU/CONTROL.VHD
vcom -2008 ../../DUT/RV32IMscMCU/DMEMORY.VHD
vcom -2008 ../../DUT/RV32IMscMCU/EXECUTE.VHD
vcom -2008 ../../DUT/RV32IMscMCU/IDECODE.VHD
vcom -2008 ../../DUT/RV32IMscMCU/IFETCH.VHD
vcom -2008 ../../DUT/RV32IMscMCU/RV32I_CORE.vhd
vcom -2008 ../../TB/RV32IMscMCU/tb_stage7_divider_interrupt_order.vhd
vsim -t 1ps -L altera_mf work.tb_stage7_divider_interrupt_order
add wave -radix hex sim:/tb_stage7_divider_interrupt_order/pc sim:/tb_stage7_divider_interrupt_order/instruction
add wave sim:/tb_stage7_divider_interrupt_order/div_busy sim:/tb_stage7_divider_interrupt_order/div_done
add wave sim:/tb_stage7_divider_interrupt_order/intr sim:/tb_stage7_divider_interrupt_order/inta
add wave sim:/tb_stage7_divider_interrupt_order/gie sim:/tb_stage7_divider_interrupt_order/irq_active
add wave sim:/tb_stage7_divider_interrupt_order/dbus_read sim:/tb_stage7_divider_interrupt_order/dbus_write
add wave -radix hex sim:/tb_stage7_divider_interrupt_order/dbus_addr sim:/tb_stage7_divider_interrupt_order/dbus_wdata
run -all
wave zoom full
transcript file ""
