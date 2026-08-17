onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_stage2_gpio_integration/sysclk
add wave -noupdate /tb_stage2_gpio_integration/reset
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_integration/bus_addr
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_integration/bus_wdata
add wave -noupdate /tb_stage2_gpio_integration/bus_write
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_integration/ledr
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_integration/dut/hex0_o
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_integration/dut/hex1_o
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_integration/dut/hex2_o
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_integration/dut/hex3_o
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_integration/dut/hex4_o
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_integration/dut/hex5_o
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
WaveRestoreZoom {0 ps} {2585100 ps}
