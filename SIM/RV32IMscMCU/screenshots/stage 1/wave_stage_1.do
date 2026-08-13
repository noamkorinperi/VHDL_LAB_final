onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/cpu_addr
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/cpu_wdata
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/cpu_rdata
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/cpu_read
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/cpu_write
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/dtcm_addr
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/dtcm_wdata
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/dtcm_rdata
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/dtcm_read
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/dtcm_write
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/mmio_addr
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/mmio_wdata
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/mmio_rdata
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/mmio_read
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/mmio_write
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/mmio_hit
add wave -noupdate -radix hexadecimal /tb_stage1_interconnect/unmapped
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
WaveRestoreZoom {0 ps} {5250 ps}
