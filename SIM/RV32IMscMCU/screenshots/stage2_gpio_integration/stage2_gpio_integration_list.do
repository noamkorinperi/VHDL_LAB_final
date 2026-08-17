onerror {resume}
add list -width 36 /tb_stage2_gpio_integration/sysclk
add list /tb_stage2_gpio_integration/reset
add list -hex /tb_stage2_gpio_integration/bus_addr
add list -hex /tb_stage2_gpio_integration/bus_wdata
add list /tb_stage2_gpio_integration/bus_write
add list -hex /tb_stage2_gpio_integration/ledr
add list -hex /tb_stage2_gpio_integration/dut/hex0_o
add list -hex /tb_stage2_gpio_integration/dut/hex1_o
add list -hex /tb_stage2_gpio_integration/dut/hex2_o
add list -hex /tb_stage2_gpio_integration/dut/hex3_o
add list -hex /tb_stage2_gpio_integration/dut/hex4_o
add list -hex /tb_stage2_gpio_integration/dut/hex5_o
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta all
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
