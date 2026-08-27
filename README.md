# VHDL_LAB_final

RV32IM single-cycle MCU implemented in VHDL for the Terasic DE10-Standard
FPGA board.

## Validation status of this branch

The forum-compliance changes pass the complete automated ModelSim regression,
Quartus Full Compilation, and fully constrained TimeQuest analysis.

**They have not yet been programmed onto or physically validated on a
DE10-Standard board.** The reset, compare, PWM, DIV and REM board results
recorded on `main` apply to the `main` image only and must not be treated as
physical evidence for this branch.

See `DOC/FORUM_COMPLIANCE_STATUS.md` for the forum-question audit and
`DOC/PHYSICAL_VALIDATION_FORUM_BRANCH.md` for the exact DE10-Standard physical
validation procedure and evidence gate.

## Project navigation

- `PROJECT_PLAN.md` — timestamped roadmap and current status.
- `DUT/RV32IMscMCU` — active VHDL implementation.
- `TB/RV32IMscMCU` — self-checking testbenches.
- `SIM/RV32IMscMCU` — ModelSim scripts and memory images.
- `Quartus/RV32IMscMCU` — Quartus project for Cyclone V.
- `DOC/MODELSIM_TESTS_STAGE0_TO_STAGE3.md` — test instructions.
- `DOC/MODELSIM_TESTS_STAGE4_TO_STAGE5.md` — current GUI test instructions.
- `DOC/PHYSICAL_LAB_TEST_STAGE5_5.md` — historical stage-5.5 smoke procedure.
- `DOC/PHYSICAL_VALIDATION_FORUM_BRANCH.md` — current branch physical
  validation procedure and evidence template.
- `DOC/MODELSIM_TESTS_STAGE6_TO_STAGE7.md` — interrupt test instructions.
- `DOC/MODELSIM_TESTS_STAGE8.md` — full benchmark matrix, assertions and IPC.
- `DOC/QUARTUS_FPGA_STAGE9.md` — final Quartus build and board procedure.
- `DOC/FORUM_COMPLIANCE_STATUS.md` — forum compliance matrix and branch gate.
- `SIM/RV32IMscMCU/run_stage8_full_verification.do` — unified stages 0–8
  system regression for all nine supplied applications.
- `Quartus/RV32IMscMCU/compile_stage9.cmd` — reproducible full FPGA build.
- `SIM/RV32IMscMCU/run_stage5_5_smoke_firmware.do` — retained stage-5.5
  regression for the earlier smoke firmware.
- `DOC/CPU_IMMEDIATE_DECODE_FIX_2026-08-13.md` — documented LUI/load decode fix.
- `Benchmark apps` — instructor-provided application benchmarks.

Generated Quartus and ModelSim artifacts are intentionally excluded through
`.gitignore`.
