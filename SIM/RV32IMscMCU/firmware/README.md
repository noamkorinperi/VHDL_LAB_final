# Stage 8 firmware compatibility copy

`interrupt_test1_ITCM_fixed.hex` is a one-word corrected copy of the instructor's
`Intrrupt-based IO/test1` ITCM image.  The supplied program uses `j STATE1` when
`SW0=0`, which skips `ori gp,gp,1` and therefore never enables interrupts in the
short ModelSim mode.

The word at ITCM word address `0x2F` was changed from `0x01C0006F`
(`j STATE1`) to `0x00C0006F` (jump to the interrupt-enable instruction).  Its
Intel HEX checksum changed accordingly from `9D` to `9E`.  The instructor's
benchmark directory is intentionally left unchanged.
