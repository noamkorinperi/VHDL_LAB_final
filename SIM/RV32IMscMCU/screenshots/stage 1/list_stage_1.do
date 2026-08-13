onerror {resume}
add list -hex -width 34 /tb_stage1_interconnect/cpu_addr
add list -hex /tb_stage1_interconnect/cpu_wdata
add list -hex /tb_stage1_interconnect/cpu_rdata
add list -hex /tb_stage1_interconnect/cpu_read
add list -hex /tb_stage1_interconnect/cpu_write
add list -hex /tb_stage1_interconnect/dtcm_addr
add list -hex /tb_stage1_interconnect/dtcm_wdata
add list -hex /tb_stage1_interconnect/dtcm_rdata
add list -hex /tb_stage1_interconnect/dtcm_read
add list -hex /tb_stage1_interconnect/dtcm_write
add list -hex /tb_stage1_interconnect/mmio_addr
add list -hex /tb_stage1_interconnect/mmio_wdata
add list -hex /tb_stage1_interconnect/mmio_rdata
add list -hex /tb_stage1_interconnect/mmio_read
add list -hex /tb_stage1_interconnect/mmio_write
add list -hex /tb_stage1_interconnect/mmio_hit
add list -hex /tb_stage1_interconnect/unmapped
configure list -usestrobe 0
configure list -strobestart {0 ps} -strobeperiod {0 ps}
configure list -usesignaltrigger 1
configure list -delta all
configure list -signalnamewidth 0
configure list -datasetprefix 0
configure list -namelimit 5
