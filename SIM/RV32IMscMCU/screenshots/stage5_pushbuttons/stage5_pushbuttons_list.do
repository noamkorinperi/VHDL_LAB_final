onerror {resume}
add list -width 28 /tb_stage5_pushbuttons/clk
add list /tb_stage5_pushbuttons/reset
add list /tb_stage5_pushbuttons/keys_n
add list /tb_stage5_pushbuttons/buttons
add list /tb_stage5_pushbuttons/press_event
add list -hex /tb_stage5_pushbuttons/address
add list -hex /tb_stage5_pushbuttons/read_data
add list /tb_stage5_pushbuttons/read_en
add list /tb_stage5_pushbuttons/hit
add list /tb_stage5_pushbuttons/dut/key_sync1_n_q
add list /tb_stage5_pushbuttons/dut/key_sync2_n_q
add list -unsigned /tb_stage5_pushbuttons/key1_events
add list -unsigned /tb_stage5_pushbuttons/key2_events
add list -unsigned /tb_stage5_pushbuttons/key3_events
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta all
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
