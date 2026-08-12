# RV32IM MCU for DE10-Standard

FPGA final project implementing an RV32IM single-cycle MCU in VHDL for the
Terasic DE10-Standard board.

Current implementation status: stages 0–3 are prepared. Quartus Analysis &
Synthesis passes; the supplied ModelSim tests are ready to run.

## Project navigation

- `PROJECT_PLAN.md` — timestamped roadmap and current status.
- `DUT/RV32IMscMCU` — active VHDL implementation.
- `TB/RV32IMscMCU` — self-checking testbenches.
- `SIM/RV32IMscMCU` — ModelSim scripts and memory images.
- `Quartus/RV32IMscMCU` — Quartus project for Cyclone V.
- `DOC/MODELSIM_TESTS_STAGE0_TO_STAGE3.md` — test instructions.
- `Benchmark apps` — instructor-provided application benchmarks.

Generated Quartus and ModelSim artifacts are intentionally excluded through
`.gitignore`.
