onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Clocks
add wave -noupdate /tb_stage0_baseline/sysclk
add wave -noupdate /tb_stage0_baseline/divclk
add wave -noupdate /tb_stage0_baseline/reset
add wave -noupdate -divider Core
add wave -noupdate -radix hexadecimal /tb_stage0_baseline/pc
add wave -noupdate -radix hexadecimal /tb_stage0_baseline/instruction
add wave -noupdate -radix hexadecimal /tb_stage0_baseline/r1
add wave -noupdate -radix hexadecimal /tb_stage0_baseline/r2
add wave -noupdate -radix hexadecimal /tb_stage0_baseline/alu
add wave -noupdate /tb_stage0_baseline/regwrite
add wave -noupdate /tb_stage0_baseline/memwrite
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2154874 ps} 0}
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
WaveRestoreZoom {789448 ps} {4736697 ps}
