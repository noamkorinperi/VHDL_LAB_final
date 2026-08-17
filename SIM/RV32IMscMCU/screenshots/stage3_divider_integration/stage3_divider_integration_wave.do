onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_stage3_divider_integration/sysclk
add wave -noupdate /tb_stage3_divider_integration/divclk
add wave -noupdate /tb_stage3_divider_integration/reset
add wave -noupdate -radix hexadecimal /tb_stage3_divider_integration/pc
add wave -noupdate -radix hexadecimal /tb_stage3_divider_integration/instruction
add wave -noupdate /tb_stage3_divider_integration/div_busy
add wave -noupdate /tb_stage3_divider_integration/div_done
add wave -noupdate /tb_stage3_divider_integration/regwrite
add wave -noupdate /tb_stage3_divider_integration/dut/cpu/div_start_w
add wave -noupdate /tb_stage3_divider_integration/dut/cpu/divider_hold_w
add wave -noupdate /tb_stage3_divider_integration/dut/cpu/div_active_q
add wave -noupdate /tb_stage3_divider_integration/dut/cpu/div_retired_q
add wave -noupdate -radix hexadecimal /tb_stage3_divider_integration/r1
add wave -noupdate -radix hexadecimal /tb_stage3_divider_integration/r2
add wave -noupdate -radix hexadecimal /tb_stage3_divider_integration/result
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2498047 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {21485100 ps}
