onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {TB control}
add wave -noupdate /tb_rv32im/clk_i
add wave -noupdate /tb_rv32im/rst_i
add wave -noupdate -radix unsigned /tb_rv32im/tb_cycle_count
add wave -noupdate /tb_rv32im/tb_done
add wave -noupdate /tb_rv32im/tb_pass
add wave -noupdate /tb_rv32im/tb_halt_detected
add wave -noupdate -divider {Instruction / PC}
add wave -noupdate -radix hexadecimal /tb_rv32im/pc_o
add wave -noupdate -radix hexadecimal /tb_rv32im/instruction_o
add wave -noupdate -divider {Top-level control}
add wave -noupdate /tb_rv32im/RegWrite_ctrl_o
add wave -noupdate /tb_rv32im/MemWrite_ctrl_o
add wave -noupdate /tb_rv32im/Branch_ctrl_o
add wave -noupdate /tb_rv32im/brTaken_o
add wave -noupdate -divider {MUL checker signals from TB}
add wave -noupdate -color Magenta /tb_rv32im/tb_mul_detected
add wave -noupdate -color Gold /tb_rv32im/tb_mul_match
add wave -noupdate -color Magenta -radix hexadecimal /tb_rv32im/tb_expected_mul
add wave -noupdate -radix unsigned /tb_rv32im/tb_mul_count
add wave -noupdate -radix unsigned /tb_rv32im/tb_mul_fail_count
add wave -noupdate -radix unsigned /tb_rv32im/tb_store_count
add wave -noupdate -divider {Register operands and result}
add wave -noupdate -color {Cornflower Blue} -radix hexadecimal /tb_rv32im/read_data1_o
add wave -noupdate -color {Cornflower Blue} -radix hexadecimal /tb_rv32im/read_data2_o
add wave -noupdate -radix hexadecimal /tb_rv32im/write_data_o
add wave -noupdate -color {Cornflower Blue} -radix hexadecimal /tb_rv32im/alu_res_o
add wave -noupdate -divider {DTCM interface}
add wave -noupdate -radix hexadecimal /tb_rv32im/dtcm_addr_o
add wave -noupdate -radix hexadecimal /tb_rv32im/dtcm_data_wr_o
add wave -noupdate -radix hexadecimal /tb_rv32im/dtcm_data_rd_o
add wave -noupdate -divider {Internal MUL path}
add wave -noupdate -color Gold /tb_rv32im/CORE/mul_op_w
add wave -noupdate -color Gold /tb_rv32im/CORE/CTL/mul_w
add wave -noupdate -radix hexadecimal /tb_rv32im/CORE/EXE/mul_res_w
add wave -noupdate -radix hexadecimal /tb_rv32im/CORE/EXE/MUL_UNIT/A_i
add wave -noupdate -radix hexadecimal /tb_rv32im/CORE/EXE/MUL_UNIT/B_i
add wave -noupdate -radix hexadecimal /tb_rv32im/CORE/EXE/MUL_UNIT/Res_o
add wave -noupdate -divider {Optional internal multiplier decomposition}
add wave -noupdate -radix hexadecimal /tb_rv32im/CORE/EXE/MUL_UNIT/P0
add wave -noupdate -radix hexadecimal /tb_rv32im/CORE/EXE/MUL_UNIT/P1
add wave -noupdate -radix hexadecimal /tb_rv32im/CORE/EXE/MUL_UNIT/P2
add wave -noupdate -radix hexadecimal /tb_rv32im/CORE/EXE/MUL_UNIT/P3
add wave -noupdate -radix hexadecimal /tb_rv32im/CORE/EXE/MUL_UNIT/M
add wave -noupdate -radix hexadecimal /tb_rv32im/CORE/EXE/MUL_UNIT/Result_32
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2050000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 243
configure wave -valuecolwidth 73
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
WaveRestoreZoom {0 ps} {15868679 ps}
