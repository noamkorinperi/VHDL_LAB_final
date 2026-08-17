onerror {resume}
add list -width 32 /tb_stage3_divider_unit/sysclk
add list /tb_stage3_divider_unit/divclk
add list /tb_stage3_divider_unit/reset
add list /tb_stage3_divider_unit/start
add list /tb_stage3_divider_unit/busy
add list /tb_stage3_divider_unit/done
add list -hex /tb_stage3_divider_unit/operation
add list -hex /tb_stage3_divider_unit/dividend
add list -hex /tb_stage3_divider_unit/divisor
add list -hex /tb_stage3_divider_unit/result
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta all
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
