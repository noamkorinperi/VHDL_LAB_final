# -----------------------------------------------------------------------------
# LAB5 Part 2 - RV32IM PIPELINE waveform setup for ModelSim/Questa
#
# Usage:
#   1. Compile all DUT files first.
#   2. Compile tb_RV32IM_pipeline_wave.vhd.
#   3. Run: do RV32IM_pipeline_wave_setup_only.do
#   4. Then manually run the simulation, e.g.: run -all
#
# Notes:
#   - The script starts/restarts work.tb_RV32IM_pipeline with +acc so internal
#     DUT signals such as stall_s, flush_s, forwarding and MUL path can be shown.
#   - This setup-only version does NOT execute run/run-all automatically.
#     The TB will stop automatically only after you manually run it.
# -----------------------------------------------------------------------------

onerror {resume}

# Start the simulation if none is loaded; otherwise restart current simulation.
if {[catch {restart -f}]} {
    vsim -voptargs=+acc work.tb_RV32IM_pipeline
}

quietly WaveActivateNextPane {} 0
quietly wave delete *
log -r /*

# -----------------------------------------------------------------------------
# TB control
# -----------------------------------------------------------------------------
add wave -noupdate -divider {TB control}
add wave -noupdate -color Green /tb_rv32im_pipeline/clk_i
add wave -noupdate -color Red   /tb_rv32im_pipeline/rst_i
add wave -noupdate -radix unsigned /tb_rv32im_pipeline/tb_cycle_count
add wave -noupdate /tb_rv32im_pipeline/tb_done
add wave -noupdate /tb_rv32im_pipeline/tb_pass
add wave -noupdate -radix unsigned /tb_rv32im_pipeline/tb_stalls
add wave -noupdate -radix unsigned /tb_rv32im_pipeline/tb_flushes
add wave -noupdate -radix unsigned /tb_rv32im_pipeline/tb_stores
add wave -noupdate -radix unsigned /tb_rv32im_pipeline/tb_mul_mem
add wave -noupdate -radix unsigned /tb_rv32im_pipeline/tb_regwrites
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/tb_halt_pc
add wave -noupdate -radix unsigned /tb_rv32im_pipeline/tb_halt_repeat

# -----------------------------------------------------------------------------
# Stage PCs and instructions - main pipeline flow for screenshots
# -----------------------------------------------------------------------------
add wave -noupdate -divider {Pipeline stage PC / instruction}
add wave -noupdate -color {Cornflower Blue} -radix hexadecimal /tb_rv32im_pipeline/pc_o
add wave -noupdate -color {Cornflower Blue} -radix hexadecimal /tb_rv32im_pipeline/instruction_o
add wave -noupdate -color Cyan -radix hexadecimal /tb_rv32im_pipeline/IDpc_o
add wave -noupdate -color Cyan -radix hexadecimal /tb_rv32im_pipeline/IDinstruction_o
add wave -noupdate -color Yellow -radix hexadecimal /tb_rv32im_pipeline/EXpc_o
add wave -noupdate -color Yellow -radix hexadecimal /tb_rv32im_pipeline/EXinstruction_o
add wave -noupdate -color Orange -radix hexadecimal /tb_rv32im_pipeline/MEMpc_o
add wave -noupdate -color Orange -radix hexadecimal /tb_rv32im_pipeline/MEMinstruction_o
add wave -noupdate -color Magenta -radix hexadecimal /tb_rv32im_pipeline/WBpc_o
add wave -noupdate -color Magenta -radix hexadecimal /tb_rv32im_pipeline/WBinstruction_o

# -----------------------------------------------------------------------------
# Decoded TB helper markers - useful for a clean MUL / halt-loop screenshot
# -----------------------------------------------------------------------------
add wave -noupdate -divider {TB decoded instruction markers}
add wave -noupdate -color Gold /tb_rv32im_pipeline/tb_if_mul
add wave -noupdate -color Gold /tb_rv32im_pipeline/tb_id_mul
add wave -noupdate -color Gold /tb_rv32im_pipeline/tb_ex_mul
add wave -noupdate -color Gold /tb_rv32im_pipeline/tb_mem_mul
add wave -noupdate -color Gold /tb_rv32im_pipeline/tb_wb_mul
add wave -noupdate -color Red /tb_rv32im_pipeline/tb_mem_halt_loop
add wave -noupdate -color Red /tb_rv32im_pipeline/tb_wb_halt_loop

# -----------------------------------------------------------------------------
# Top-level control and performance counters
# -----------------------------------------------------------------------------
add wave -noupdate -divider {Top-level control and counters}
add wave -noupdate /tb_rv32im_pipeline/RegWrite_ctrl_o
add wave -noupdate /tb_rv32im_pipeline/MemWrite_ctrl_o
add wave -noupdate /tb_rv32im_pipeline/Branch_ctrl_o
add wave -noupdate /tb_rv32im_pipeline/brTaken_o
add wave -noupdate /tb_rv32im_pipeline/STRIGGER_o
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/CLKCNT_o
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/STCNT_o
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/FHCNT_o
add wave -noupdate -radix unsigned /tb_rv32im_pipeline/tb_stcnt_value
add wave -noupdate -radix unsigned /tb_rv32im_pipeline/tb_fhcnt_value

# -----------------------------------------------------------------------------
# Hazard / interlock / forwarding internals
# These require vsim -voptargs=+acc. onerror resume keeps the script robust if
# a signal name was optimized/renamed in a local version.
# -----------------------------------------------------------------------------
add wave -noupdate -divider {Internal hazard / forwarding}
add wave -noupdate -color Red /tb_rv32im_pipeline/DUT/stall_s
add wave -noupdate -color Red /tb_rv32im_pipeline/DUT/flush_s
add wave -noupdate -color Green /tb_rv32im_pipeline/DUT/pcwrite_s
add wave -noupdate -color Green /tb_rv32im_pipeline/DUT/ifidwrite_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/forwardA_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/forwardB_s
add wave -noupdate /tb_rv32im_pipeline/DUT/id_uses_rs1_s
add wave -noupdate /tb_rv32im_pipeline/DUT/id_uses_rs2_s
add wave -noupdate /tb_rv32im_pipeline/DUT/id_ex_MemRead_ctrl_s
add wave -noupdate /tb_rv32im_pipeline/DUT/id_ex_MULOp_ctrl_s
add wave -noupdate /tb_rv32im_pipeline/DUT/ex_mem_MULOp_ctrl_s

# -----------------------------------------------------------------------------
# Branch / flush explanation signals
# -----------------------------------------------------------------------------
add wave -noupdate -divider {Branch and flush path}
add wave -noupdate /tb_rv32im_pipeline/DUT/ex_brTaken_s
add wave -noupdate /tb_rv32im_pipeline/DUT/ex_mem_Branch_ctrl_s
add wave -noupdate /tb_rv32im_pipeline/DUT/ex_mem_brTaken_s
add wave -noupdate /tb_rv32im_pipeline/DUT/ex_mem_Jal_ctrl_s
add wave -noupdate /tb_rv32im_pipeline/DUT/ex_mem_Jalr_ctrl_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/ex_mem_addr_gen_s

# -----------------------------------------------------------------------------
# MUL path across EX -> MEM -> WB
# -----------------------------------------------------------------------------
add wave -noupdate -divider {Internal MUL path}
add wave -noupdate /tb_rv32im_pipeline/DUT/id_ex_MULOp_ctrl_s
add wave -noupdate /tb_rv32im_pipeline/DUT/ex_mem_MULOp_ctrl_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/forwarded_data1_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/forwarded_data2_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/ex_mul_pp_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/ex_mem_pp_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/mem_mul_res_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/mem_wb_mul_res_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/wb_write_data_s

# Optional decomposition inside the two MUL units
add wave -noupdate -divider {Optional MUL unit decomposition}
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/MUL_S1/A_i
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/MUL_S1/B_i
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/MUL_S1/P_o
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/MUL_S1/P0_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/MUL_S1/P1_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/MUL_S1/P2_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/MUL_S1/P3_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/MUL_S2/P_i
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/MUL_S2/M_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/MUL_S2/Res_o

# -----------------------------------------------------------------------------
# Register operands, WB result and DTCM interface
# -----------------------------------------------------------------------------
add wave -noupdate -divider {Register operands / WB / DTCM}
add wave -noupdate -color {Cornflower Blue} -radix hexadecimal /tb_rv32im_pipeline/read_data1_o
add wave -noupdate -color {Cornflower Blue} -radix hexadecimal /tb_rv32im_pipeline/read_data2_o
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/write_data_o
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/alu_res_o
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/dtcm_addr_o
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/dtcm_data_wr_o
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/dtcm_data_rd_o
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/dtcm_addr_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/ex_mem_store_data_s
add wave -noupdate -radix hexadecimal /tb_rv32im_pipeline/DUT/dtcm_data_rd_s

# -----------------------------------------------------------------------------
# Formatting
# -----------------------------------------------------------------------------
TreeUpdate [SetDefaultTree]
quietly wave cursor active 1
WaveRestoreCursors {{MUL area} {2100 ns} 0} {{Branch/flush area} {5200 ns} 0}
configure wave -namecolwidth 280
configure wave -valuecolwidth 90
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update

# -----------------------------------------------------------------------------
# Setup-only mode:
# This DO file intentionally does NOT run the simulation.
# After it finishes preparing the wave window, run manually, for example:
#   run -all
# or:
#   run 10 us
# -----------------------------------------------------------------------------
WaveRestoreZoom {0 ns} {9000 ns}

echo "Wave setup completed. Run the simulation manually with: run -all"
