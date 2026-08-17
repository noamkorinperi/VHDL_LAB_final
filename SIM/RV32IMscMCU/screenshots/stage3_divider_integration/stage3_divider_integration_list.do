onerror {resume}
add list -width 39 /tb_stage3_divider_integration/sysclk
add list /tb_stage3_divider_integration/divclk
add list /tb_stage3_divider_integration/reset
add list -hex /tb_stage3_divider_integration/pc
add list -hex /tb_stage3_divider_integration/instruction
add list /tb_stage3_divider_integration/div_busy
add list /tb_stage3_divider_integration/div_done
add list /tb_stage3_divider_integration/regwrite
add list /tb_stage3_divider_integration/dut/cpu/div_start_w
add list /tb_stage3_divider_integration/dut/cpu/divider_hold_w
add list /tb_stage3_divider_integration/dut/cpu/div_active_q
add list /tb_stage3_divider_integration/dut/cpu/div_retired_q
add list -hex /tb_stage3_divider_integration/r1
add list -hex /tb_stage3_divider_integration/r2
add list -hex /tb_stage3_divider_integration/result
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta all
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
