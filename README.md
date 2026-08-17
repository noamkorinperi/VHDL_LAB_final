# VHDL_LAB_final

RV32IM single-cycle MCU implemented in VHDL for the Terasic DE10-Standard
FPGA board.

Current implementation status: stages 0–5 are complete. Stage 5.5 is ready for
the DE10-Standard lab, and stages 6–7 pass automated ModelSim tests pending GUI
evidence.

## Project navigation

- `PROJECT_PLAN.md` — timestamped roadmap and current status.
- `DUT/RV32IMscMCU` — active VHDL implementation.
- `TB/RV32IMscMCU` — self-checking testbenches.
- `SIM/RV32IMscMCU` — ModelSim scripts and memory images.
- `Quartus/RV32IMscMCU` — Quartus project for Cyclone V.
- `DOC/MODELSIM_TESTS_STAGE0_TO_STAGE3.md` — test instructions.
- `DOC/MODELSIM_TESTS_STAGE4_TO_STAGE5.md` — current GUI test instructions.
- `DOC/PHYSICAL_LAB_TEST_STAGE5_5.md` — DE10-Standard button/PWM procedure.
- `DOC/MODELSIM_TESTS_STAGE6_TO_STAGE7.md` — interrupt test instructions.
- `SIM/RV32IMscMCU/run_stage5_5_smoke_firmware.do` — automated preflight for
  the exact firmware embedded in the hardware-test SOF.
- `DOC/CPU_IMMEDIATE_DECODE_FIX_2026-08-13.md` — documented LUI/load decode fix.
- `Benchmark apps` — instructor-provided application benchmarks.

Generated Quartus and ModelSim artifacts are intentionally excluded through
`.gitignore`.
