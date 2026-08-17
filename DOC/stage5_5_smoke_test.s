# Stage 5.5 board smoke test (RV32I)
# t0 = MMIO base 0x2000
# LEDR8 is driven directly by PWM; LEDR9 is the debounced any-key indicator.

    lui  t0, 0x2
    lui  t1, 0x8
    addi t1, t1, -1
    sw   t1, 0x20(t0)       # BTCMPR0 = 32767 -> about 76.3 Hz at 20 MHz / 8

    addi t1, zero, 0x5C
    sw   t1, 0x04(t0)       # HEX0 displays C: proves firmware is running
    sw   t1, 0x1C(t0)       # PWM mode 0, /8, clear, run, output enabled

loop:
    lw   t2, 0x10(t0)       # SW7:0
    slli t2, t2, 7
    sw   t2, 0x24(t0)       # BTCMPR1 = SW7:0 * 128

    lw   t3, 0x14(t0)       # debounced KEY1..KEY3, active high
    sw   t3, 0x00(t0)       # show key state on LEDR2:0
    jal  zero, loop
