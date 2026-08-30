RV32IMscMCU working tree
========================

DUT/RV32IMscMCU
  Synthesizable VHDL. The lab sources were copied here so the originals remain
  unchanged. The active tree now contains the interconnect, GPIO, divider,
  Basic Timer, pushbutton conditioner and structural peripheral mux.

TB/RV32IMscMCU
  Self-checking unit and integration testbenches for stages 0-5.

SIM/RV32IMscMCU
  Independent ModelSim .do scripts, memory images and saved GUI evidence.
  Each script builds its own dependency set and prepares both Wave and List.

DOC
  Architecture, timestamped status, ModelSim instructions, defect analyses and
  final documentation material.

Quartus/RV32IMscMCU
  Quartus project scaffold for the DE10-Standard and local synthesis memory
  initialization files.  Generated db, incremental_db and output_files folders
  are build products and must not be included in the final submission package.

Reference-only folders
----------------------

מעבדה קודמת שלנו
קבצים מהמדריך
Benchmark apps

Do not edit files in the reference-only folders.

Final Quartus build
-------------------
The final timing-qualified FPGA implementation was compiled with Quartus Prime 21.1 using Fitter Seed = 2.
The setting is stored in Quartus/RV32IMscMCU/RV32IMscMCU.qsf.
