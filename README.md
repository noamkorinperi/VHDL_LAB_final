# VHDL_LAB_final

RV32IM single-cycle MCU implemented in VHDL for the Terasic DE10-Standard
FPGA board.

Current implementation status: stages 0–9 pass the complete automated ModelSim
regression and physical DE10-Standard validation. The final interrupt-test4 SOF
has timing closure and passes reset, compare, PWM, DIV and REM board tests.

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
- `DOC/MODELSIM_TESTS_STAGE8.md` — full benchmark matrix, assertions and IPC.
- `DOC/QUARTUS_FPGA_STAGE9.md` — final Quartus build and board procedure.
- `SIM/RV32IMscMCU/run_stage8_full_verification.do` — unified stages 0–8
  system regression for all nine supplied applications.
- `Quartus/RV32IMscMCU/compile_stage9.cmd` — reproducible full FPGA build.
- `SIM/RV32IMscMCU/run_stage5_5_smoke_firmware.do` — retained stage-5.5
  regression for the earlier smoke firmware.
- `DOC/CPU_IMMEDIATE_DECODE_FIX_2026-08-13.md` — documented LUI/load decode fix.
- `Benchmark apps` — instructor-provided application benchmarks.

Generated Quartus and ModelSim artifacts are intentionally excluded through
`.gitignore`.
