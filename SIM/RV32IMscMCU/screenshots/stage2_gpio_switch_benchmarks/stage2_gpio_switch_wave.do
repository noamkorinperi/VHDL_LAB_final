onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_stage2_gpio_switch_benchmarks/sysclk
add wave -noupdate /tb_stage2_gpio_switch_benchmarks/reset
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_switch_benchmarks/switches
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_switch_benchmarks/addr1
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_switch_benchmarks/data1
add wave -noupdate /tb_stage2_gpio_switch_benchmarks/write1
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_switch_benchmarks/ledr1
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_switch_benchmarks/addr2
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_switch_benchmarks/data2
add wave -noupdate /tb_stage2_gpio_switch_benchmarks/write2
add wave -noupdate -radix hexadecimal /tb_stage2_gpio_switch_benchmarks/ledr2
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
WaveRestoreZoom {0 ps} {2459100 ps}
