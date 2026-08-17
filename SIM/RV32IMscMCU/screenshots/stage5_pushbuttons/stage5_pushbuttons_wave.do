onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_stage5_pushbuttons/clk
add wave -noupdate /tb_stage5_pushbuttons/reset
add wave -noupdate /tb_stage5_pushbuttons/keys_n
add wave -noupdate /tb_stage5_pushbuttons/buttons
add wave -noupdate /tb_stage5_pushbuttons/press_event
add wave -noupdate -radix hexadecimal /tb_stage5_pushbuttons/address
add wave -noupdate -radix hexadecimal /tb_stage5_pushbuttons/read_data
add wave -noupdate /tb_stage5_pushbuttons/read_en
add wave -noupdate /tb_stage5_pushbuttons/hit
add wave -noupdate /tb_stage5_pushbuttons/dut/key_sync1_n_q
add wave -noupdate /tb_stage5_pushbuttons/dut/key_sync2_n_q
add wave -noupdate -radix unsigned /tb_stage5_pushbuttons/key1_events
add wave -noupdate -radix unsigned /tb_stage5_pushbuttons/key2_events
add wave -noupdate -radix unsigned /tb_stage5_pushbuttons/key3_events
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
WaveRestoreZoom {0 ps} {916650 ps}
