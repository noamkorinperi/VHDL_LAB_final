onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_stage4_5_peripheral_integration/clk
add wave -noupdate /tb_stage4_5_peripheral_integration/reset
add wave -noupdate -radix hexadecimal /tb_stage4_5_peripheral_integration/address
add wave -noupdate -radix hexadecimal /tb_stage4_5_peripheral_integration/write_data
add wave -noupdate -radix hexadecimal /tb_stage4_5_peripheral_integration/read_data
add wave -noupdate /tb_stage4_5_peripheral_integration/read_en
add wave -noupdate /tb_stage4_5_peripheral_integration/write_en
add wave -noupdate /tb_stage4_5_peripheral_integration/hit
add wave -noupdate -radix hexadecimal /tb_stage4_5_peripheral_integration/switches
add wave -noupdate -radix hexadecimal /tb_stage4_5_peripheral_integration/ledr
add wave -noupdate /tb_stage4_5_peripheral_integration/keys_n
add wave -noupdate /tb_stage4_5_peripheral_integration/button_state
add wave -noupdate /tb_stage4_5_peripheral_integration/key_event
add wave -noupdate -radix unsigned /tb_stage4_5_peripheral_integration/timer_count
add wave -noupdate -radix unsigned /tb_stage4_5_peripheral_integration/timer_capture
add wave -noupdate /tb_stage4_5_peripheral_integration/pwm
add wave -noupdate /tb_stage4_5_peripheral_integration/timer_event
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
WaveRestoreZoom {0 ps} {392700 ps}
