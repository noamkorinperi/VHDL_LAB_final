onerror {resume}
add list -width 42 /tb_stage2_gpio_switch_benchmarks/sysclk
add list /tb_stage2_gpio_switch_benchmarks/reset
add list -hex /tb_stage2_gpio_switch_benchmarks/switches
add list -hex /tb_stage2_gpio_switch_benchmarks/addr1
add list -hex /tb_stage2_gpio_switch_benchmarks/data1
add list /tb_stage2_gpio_switch_benchmarks/write1
add list -hex /tb_stage2_gpio_switch_benchmarks/ledr1
add list -hex /tb_stage2_gpio_switch_benchmarks/addr2
add list -hex /tb_stage2_gpio_switch_benchmarks/data2
add list /tb_stage2_gpio_switch_benchmarks/write2
add list -hex /tb_stage2_gpio_switch_benchmarks/ledr2
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta all
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
