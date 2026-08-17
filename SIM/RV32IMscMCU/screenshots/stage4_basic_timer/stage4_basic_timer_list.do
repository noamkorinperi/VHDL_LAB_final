onerror {resume}
add list -width 28 /tb_stage4_basic_timer/clk
add list /tb_stage4_basic_timer/reset
add list -hex /tb_stage4_basic_timer/address
add list -hex /tb_stage4_basic_timer/write_data
add list -hex /tb_stage4_basic_timer/read_data
add list /tb_stage4_basic_timer/read_en
add list /tb_stage4_basic_timer/write_en
add list /tb_stage4_basic_timer/hit
add list -hex /tb_stage4_basic_timer/dut/btctl1_q
add list -hex /tb_stage4_basic_timer/dut/btctl2_q
add list -unsigned /tb_stage4_basic_timer/counter
add list -unsigned /tb_stage4_basic_timer/capture_value
add list /tb_stage4_basic_timer/pwm
add list /tb_stage4_basic_timer/timer_event
add list /tb_stage4_basic_timer/compare0_event
add list /tb_stage4_basic_timer/compare1_event
add list /tb_stage4_basic_timer/capture_event
add list /tb_stage4_basic_timer/capin1
add list /tb_stage4_basic_timer/capin2
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta all
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
