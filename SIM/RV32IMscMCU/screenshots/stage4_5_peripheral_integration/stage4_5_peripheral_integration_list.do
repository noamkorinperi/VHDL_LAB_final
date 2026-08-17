onerror {resume}
add list -width 41 /tb_stage4_5_peripheral_integration/clk
add list /tb_stage4_5_peripheral_integration/reset
add list -hex /tb_stage4_5_peripheral_integration/address
add list -hex /tb_stage4_5_peripheral_integration/write_data
add list -hex /tb_stage4_5_peripheral_integration/read_data
add list /tb_stage4_5_peripheral_integration/read_en
add list /tb_stage4_5_peripheral_integration/write_en
add list /tb_stage4_5_peripheral_integration/hit
add list -hex /tb_stage4_5_peripheral_integration/switches
add list -hex /tb_stage4_5_peripheral_integration/ledr
add list /tb_stage4_5_peripheral_integration/keys_n
add list /tb_stage4_5_peripheral_integration/button_state
add list /tb_stage4_5_peripheral_integration/key_event
add list -unsigned /tb_stage4_5_peripheral_integration/timer_count
add list -unsigned /tb_stage4_5_peripheral_integration/timer_capture
add list /tb_stage4_5_peripheral_integration/pwm
add list /tb_stage4_5_peripheral_integration/timer_event
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta all
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
