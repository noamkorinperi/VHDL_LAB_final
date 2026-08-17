onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_stage4_basic_timer/clk
add wave -noupdate /tb_stage4_basic_timer/reset
add wave -noupdate -radix hexadecimal /tb_stage4_basic_timer/address
add wave -noupdate -radix hexadecimal /tb_stage4_basic_timer/write_data
add wave -noupdate -radix hexadecimal /tb_stage4_basic_timer/read_data
add wave -noupdate /tb_stage4_basic_timer/read_en
add wave -noupdate /tb_stage4_basic_timer/write_en
add wave -noupdate /tb_stage4_basic_timer/hit
add wave -noupdate -radix hexadecimal /tb_stage4_basic_timer/dut/btctl1_q
add wave -noupdate -radix hexadecimal /tb_stage4_basic_timer/dut/btctl2_q
add wave -noupdate -radix hexadecimal /tb_stage4_basic_timer/dut/btcmpr0_q
add wave -noupdate -radix hexadecimal /tb_stage4_basic_timer/dut/btcmpr1_q
add wave -noupdate -radix unsigned /tb_stage4_basic_timer/counter
add wave -noupdate -radix unsigned /tb_stage4_basic_timer/capture_value
add wave -noupdate /tb_stage4_basic_timer/pwm
add wave -noupdate /tb_stage4_basic_timer/timer_event
add wave -noupdate /tb_stage4_basic_timer/compare0_event
add wave -noupdate /tb_stage4_basic_timer/compare1_event
add wave -noupdate /tb_stage4_basic_timer/capture_event
add wave -noupdate /tb_stage4_basic_timer/capin1
add wave -noupdate /tb_stage4_basic_timer/capin2
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
WaveRestoreZoom {0 ps} {1966650 ps}
