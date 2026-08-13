onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/clk
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/reset
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/read_enable
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/write_enable
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/hit
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/address
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/write_data
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/read_data
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/switches
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/ledr
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/hex0
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/hex1
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/hex2
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/hex3
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/hex4
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_unit/hex5
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {76913 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 274
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
WaveRestoreZoom {0 ps} {221320 ps}
