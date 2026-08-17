# VHDL_LAB_final

RV32IM single-cycle MCU implemented in VHDL for the Terasic DE10-Standard
FPGA board.

Current implementation status: stages 0–3 are complete. Stages 4–5 (Basic
Timer, PWM, input capture and debounced pushbuttons) pass automated ModelSim
regression and Quartus Analysis & Synthesis; GUI evidence is the next gate.

## Project navigation

- `PROJECT_PLAN.md` — timestamped roadmap and current status.
- `DUT/RV32IMscMCU` — active VHDL implementation.
- `TB/RV32IMscMCU` — self-checking testbenches.
- `SIM/RV32IMscMCU` — ModelSim scripts and memory images.
- `Quartus/RV32IMscMCU` — Quartus project for Cyclone V.
- `DOC/MODELSIM_TESTS_STAGE0_TO_STAGE3.md` — test instructions.
- `DOC/MODELSIM_TESTS_STAGE4_TO_STAGE5.md` — current GUI test instructions.
- `DOC/CPU_IMMEDIATE_DECODE_FIX_2026-08-13.md` — documented LUI/load decode fix.
- `Benchmark apps` — instructor-provided application benchmarks.

Generated Quartus and ModelSim artifacts are intentionally excluded through
`.gitignore`.
