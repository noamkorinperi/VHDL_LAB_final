create_clock -name CLOCK_50 -period 20.000 -waveform {0.000 10.000} [get_ports {CLOCK_50}]

derive_pll_clocks
derive_clock_uncertainty

# The CPU/peripheral domain (PLL 20 MHz output, named *|divclk by the PLL IP)
# and the iterative-divider domain (board CLOCK_50) exchange only synchronized
# toggle/data handshakes.  Do not time those CDC paths as synchronous transfers.
set_clock_groups -asynchronous \
    -group [get_clocks {CLOCK_50}] \
    -group [get_clocks {*|divclk}]

# KEY/SW are human-operated asynchronous inputs.  The pushbuttons and capture
# inputs contain their own synchronizers; switch data is sampled by firmware.
# LED/HEX are observation-only outputs with no external synchronous receiver.
set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to [get_ports {LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}]
