transcript file stage8_full_verification.log
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
vcom -2008 ../../TB/RV32IMscMCU/tb_RV32IMscMCU.vhd

set suite {
    0 rv32im-manual
    1 rv32im-gcc
    2 gpio-test0
    3 gpio-test1
    4 gpio-test2
    5 interrupt-test1
    6 interrupt-test2
    7 interrupt-test3
    8 interrupt-test4
}

foreach {benchmark_id benchmark_name} $suite {
    echo "Running stage-8 benchmark $benchmark_id ($benchmark_name)"
    set benchmark_failed 0
    onbreak {set benchmark_failed 1; resume}
    vsim -t 1ps -L altera_mf -gBENCHMARK_ID=$benchmark_id work.tb_RV32IMscMCU
    add wave -radix hex sim:/tb_RV32IMscMCU/pc sim:/tb_RV32IMscMCU/instruction
    add wave sim:/tb_RV32IMscMCU/bus_read sim:/tb_RV32IMscMCU/bus_write
    add wave -radix hex sim:/tb_RV32IMscMCU/bus_addr sim:/tb_RV32IMscMCU/bus_wdata
    add wave sim:/tb_RV32IMscMCU/div_busy sim:/tb_RV32IMscMCU/div_done
    add wave sim:/tb_RV32IMscMCU/intr sim:/tb_RV32IMscMCU/inta sim:/tb_RV32IMscMCU/gie
    add wave -radix hex sim:/tb_RV32IMscMCU/irq_type sim:/tb_RV32IMscMCU/interrupt_ie sim:/tb_RV32IMscMCU/interrupt_ifg
    add wave sim:/tb_RV32IMscMCU/keys_n sim:/tb_RV32IMscMCU/switches sim:/tb_RV32IMscMCU/pwm
    run -all
    if {$benchmark_failed} {
        echo "STAGE 8 FAILED: $benchmark_name"
        transcript file ""
        error "Stage 8 benchmark failed: $benchmark_name"
    }
    if {$benchmark_id == 8} {
        write format wave stage8_representative_wave.do
    }
    quit -sim
}

echo "Running stage-8 acceptance: interrupt pending during DIV"
vcom -2008 ../../TB/RV32IMscMCU/tb_stage7_divider_interrupt_order.vhd
vsim -t 1ps -L altera_mf work.tb_stage7_divider_interrupt_order
run -all
quit -sim

echo "STAGE 8 FULL VERIFICATION PASS"
transcript file ""
