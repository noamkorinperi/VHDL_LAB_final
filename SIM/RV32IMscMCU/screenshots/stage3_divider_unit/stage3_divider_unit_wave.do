onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_stage3_divider_unit/sysclk
add wave -noupdate /tb_stage3_divider_unit/divclk
add wave -noupdate /tb_stage3_divider_unit/reset
add wave -noupdate /tb_stage3_divider_unit/start
add wave -noupdate /tb_stage3_divider_unit/busy
add wave -noupdate /tb_stage3_divider_unit/done
add wave -noupdate -radix hexadecimal /tb_stage3_divider_unit/operation
add wave -noupdate -radix hexadecimal /tb_stage3_divider_unit/dividend
add wave -noupdate -radix hexadecimal /tb_stage3_divider_unit/divisor
add wave -noupdate -radix hexadecimal /tb_stage3_divider_unit/result
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
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
WaveRestoreZoom {0 ps} {5944050 ps}
