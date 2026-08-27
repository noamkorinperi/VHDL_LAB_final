create_clock -name CLOCK_50 -period 20.000 -waveform {0.000 10.000} [get_ports {CLOCK_50}]

derive_pll_clocks
derive_clock_uncertainty

# MCLK and SMCLK are separate 20 MHz PLLs with an integer 1:1 relationship and
# are intentionally timed together. DIVCLK is a third, 50 MHz PLL domain; its
# only MCLK crossings use the Figure-10 request/acknowledge synchronizers.
# MCLK and SMCLK are phase-identical; Quartus legally shares their physical
# clock network, so the post-fit timing netlist exposes it under mclk_pll.
set mclk_smclk_clocks [get_clocks {*mclk_pll*}]
set divclk_clocks [get_clocks {*divclk_pll*}]
set_clock_groups -asynchronous \
    -group $mclk_smclk_clocks \
    -group $divclk_clocks

# KEY inputs are hardware-debounced/static per the instructor clarification;
# SW inputs are human-operated. Neither has an external timing relationship.
# LED/HEX are observation-only outputs with no external synchronous receiver.
set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to [get_ports {LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}]

# The vendor JTAG debug fabric provides its own board-level timing contract.
set_false_path -from [get_ports {altera_reserved_tdi altera_reserved_tms}]
set_false_path -to [get_ports {altera_reserved_tdo}]
