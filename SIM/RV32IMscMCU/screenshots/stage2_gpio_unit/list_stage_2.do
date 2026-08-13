onerror {resume}
add list -hex -width 26 /tb_stage2_gpio_unit/clk
add list -hex /tb_stage2_gpio_unit/reset
add list -hex /tb_stage2_gpio_unit/read_enable
add list -hex /tb_stage2_gpio_unit/write_enable
add list -hex /tb_stage2_gpio_unit/hit
add list -hex /tb_stage2_gpio_unit/address
add list -hex /tb_stage2_gpio_unit/write_data
add list -hex /tb_stage2_gpio_unit/read_data
add list -hex /tb_stage2_gpio_unit/switches
add list -hex /tb_stage2_gpio_unit/ledr
add list -hex /tb_stage2_gpio_unit/hex0
add list -hex /tb_stage2_gpio_unit/hex1
add list -hex /tb_stage2_gpio_unit/hex2
add list -hex /tb_stage2_gpio_unit/hex3
add list -hex /tb_stage2_gpio_unit/hex4
add list -hex /tb_stage2_gpio_unit/hex5
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta all
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
