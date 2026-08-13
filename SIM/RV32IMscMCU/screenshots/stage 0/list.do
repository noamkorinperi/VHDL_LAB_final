onerror {resume}
add list -width 28 /tb_stage0_baseline/sysclk
add list /tb_stage0_baseline/divclk
add list /tb_stage0_baseline/reset
add list -hex /tb_stage0_baseline/pc
add list -hex /tb_stage0_baseline/instruction
add list -hex /tb_stage0_baseline/r1
add list -hex /tb_stage0_baseline/r2
add list -hex /tb_stage0_baseline/alu
add list /tb_stage0_baseline/regwrite
add list /tb_stage0_baseline/memwrite
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta all
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
