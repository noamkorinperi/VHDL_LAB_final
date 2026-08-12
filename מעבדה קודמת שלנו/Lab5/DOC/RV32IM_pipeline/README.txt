# RV32IM Pipelined RISC-V Core

This repository contains a VHDL implementation of a **5-stage pipelined RISC-V processor** based on the RV32I datapath, with an added partial M-extension path for the `mul` instruction.  
The design is intended for simulation in ModelSim and synthesis/debug on an Intel/Altera FPGA using Quartus and SignalTap.

## Project Overview

The processor is organized as a classic 5-stage pipeline:

```text
IF  ->  ID  ->  EX  ->  MEM  ->  WB
```

Main features:

- 32-bit RISC-V datapath.
- 5-stage pipeline with dedicated pipeline registers.
- Instruction memory / data memory implemented using Intel/Altera `altsyncram`.
- Hazard handling using stall, flush, and forwarding logic.
- Branch and jump redirection support.
- Two-stage adapted multiplier for `mul`.
- Debug outputs for SignalTap, including PC/instruction taps for pipeline stages.
- FPGA top wrapper with board-level switch and LED mapping.

## Top-Level Entities

| Entity | File | Purpose |
|---|---|---|
| `RV32IM_pipeline_top` | `RV32IM_pipeline_top(1).vhd` | FPGA board-level wrapper around the pipelined core. Maps switches, LEDs, and debug outputs. |
| `RV32IM_PIPELINE_CORE` | `RV32IM_PIPELINE_CORE_start(3).vhd` | Main pipelined CPU core. Instantiates IF, ID, EX, MEM, WB stages and hazard units. |
| `Ifetch` | `IFETCH_pipeline(3).VHD` | Program counter logic and instruction memory interface. |
| `Idecode` | `IDECODE_pipeline(1).VHD` | Register file read/write and immediate generation. |
| `control` | `CONTROL(5).VHD` | Combinational instruction decoder and control-signal generator. |
| `Execute` | `EXECUTE(4).VHD` | ALU, branch comparison, and branch/jump target generation. |
| `dmemory` | `DMEMORY(6).VHD` | Data memory interface using `altsyncram`. |
| `IF_ID_REG` | `IF_ID_REG(2).vhd` | Pipeline register between IF and ID. |
| `ID_EX_REG` | `ID_EX_REG(2).vhd` | Pipeline register between ID and EX. |
| `EX_MEM_REG` | `EX_MEM_REG(2).vhd` | Pipeline register between EX and MEM. |
| `MEM_WB_REG` | `MEM_WB_REG(2).vhd` | Pipeline register between MEM and WB. |
| `forwarding_unit` | `forwarding_unit(4).vhd` | Resolves data hazards by selecting forwarded operands. |
| `stall_unit` | `stall_unit(7).vhd` | Inserts a one-cycle stall for load-use and mul-use hazards. |
| `pipeline_muxes` | `pipeline_muxes(3).vhd` | Forwarding muxes and write-back mux. |
| `Multiplier16_s1`, `Multiplier16_s2` | `Multiplier16_adapted_simple(2).vhd` | Two-stage multiplier implementation. |
| `PLL` | `PLL(5).vhd` | FPGA PLL used when running on hardware. |

## Packages

| Package | File | Purpose |
|---|---|---|
| `cond_compilation_package` | `cond_compilation_package(5).vhd` | Global configuration constants for simulation/FPGA mode, memory size, PC width, address width, and PLL parameters. |
| `const_package` | `const_package(5).vhd` | Instruction masks, opcode constants, ALU operation encodings, and shared datapath constants. |
| `aux_package` | `aux_package_pipeline(1).vhd` | Component declarations for the pipelined core and its submodules. Compile only this updated `aux_package`; do not compile an older `aux_package.vhd` in the same library. |

## Pipeline Architecture

### IF Stage

The IF stage is implemented by `Ifetch` and includes:

- Program counter register.
- Sequential PC update using `PC + 4`.
- Branch/jump target selection.
- PC hold support during stalls using `PCWrite_i`.
- Instruction memory access through `altsyncram`.

The next-PC priority is:

```text
reset -> jalr -> taken branch / jal -> stall hold -> PC + 4
```

### ID Stage

The ID stage contains:

- Register file with 32 registers.
- Source register decoding from the instruction.
- Immediate/sign-extension generation.
- Write-back input path from the WB stage.

The register file write-back is driven by:

```text
wb_rd_i, wb_write_data_i, wb_regwrite_i
```

### EX Stage

The EX stage contains:

- ALU operation execution.
- Branch comparison.
- Branch/jump target address generation.
- Stage 1 of the adapted multiplier.

ALU operation selection is controlled by `ALUOp_ctrl_o` from the control unit.

### MEM Stage

The MEM stage contains:

- Data memory read/write.
- Stage 2 of the adapted multiplier.
- Branch/jump resolution and pipeline flush generation.

Data memory address selection depends on `WORD_GRANULARITY`:

```text
WORD_GRANULARITY = true  -> use word address bits
WORD_GRANULARITY = false -> use byte address bits
```

### WB Stage

The WB stage chooses the value written back to the register file:

```text
jal/jalr   -> PC + 4
load       -> DTCM read data
mul        -> multiplier result
otherwise  -> ALU result
```

## Hazard Handling

### Forwarding

The `forwarding_unit` detects dependencies between the current EX-stage instruction and results from later stages.

Forwarding select encoding:

```text
00 -> use original ID/EX register data
10 -> forward from EX/MEM ALU result
01 -> forward from MEM/WB write-back result
11 -> unused / treated as original data
```

### Stalling

The `stall_unit` inserts a one-cycle interlock when the instruction in ID depends on a value that is not ready yet:

- Load-use hazard.
- Mul-use hazard.

When a stall is asserted:

```text
PCwrite_o   = 0
IFIDWrite_o = 0
Stall_o     = 1
```

### Flushing

A flush is generated after a taken branch or jump redirection. The design exposes `FHCNT_o`, a flush counter useful for debugging and performance inspection.

## Supported Instruction Groups

The control unit decodes the following RV32I-style instruction groups:

- Arithmetic and logical R-type instructions: `add`, `sub`, `and`, `or`, `xor`, `sll`, `srl`, `sra`, `slt`, `sltu`.
- Immediate arithmetic/logical instructions: `addi`, `andi`, `ori`, `xori`, `slli`, `srli`, `srai`, `slti`, `sltiu`.
- Upper-immediate instructions: `lui`, `auipc`.
- Branch instructions: `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`.
- Jump instructions: `jal`, `jalr`.
- Load/store instructions: `lb`, `lh`, `lw`, `lbu`, `lhu`, `lwu`, `sb`, `sh`, `sw`.
- M-extension: `mul` through the adapted two-stage multiplier.

> Note: `const_package` contains constants for additional M-extension and system instructions, but the uploaded control/datapath currently wires the `mul` path only.

## Multiplier Implementation

The `mul` instruction is implemented using a two-stage adapted multiplier:

```text
Stage 1, EX stage:
    Four 8-bit partial multiplications
    P = {P3, P2, P1, P0}

Pipeline register:
    EX/MEM register stores the packed partial products

Stage 2, MEM stage:
    Adder tree combines the partial products
    RESULT = P0 + (P1 + P2 << 8) + (P3 << 16)
```

Because the multiplier result becomes available in MEM/WB, a directly dependent instruction after `mul` requires one stall, similar to a load-use hazard.

## Debug and SignalTap Outputs

The core exposes several useful debug outputs:

| Signal | Meaning |
|---|---|
| `pc_o` | Current IF-stage PC. |
| `instruction_o` | Current IF-stage instruction. |
| `IDpc_o`, `EXpc_o`, `MEMpc_o`, `WBpc_o` | PC value in each pipeline stage. |
| `IDinstruction_o`, `EXinstruction_o`, `MEMinstruction_o`, `WBinstruction_o` | Instruction value in each pipeline stage. |
| `STCNT_o` | Stall counter. |
| `FHCNT_o` | Flush counter. |
| `CLKCNT_o` / `mclk_cnt_o` | Main clock counter. |
| `STRIGGER_o` | SignalTap trigger when the IF PC matches the selected breakpoint address. |
| `BPADDR_i` | 8-bit breakpoint address input, normally driven by `SW[7:0]`. |

In the FPGA wrapper:

```text
SW[7:0]     -> BPADDR_i
LEDR[7:0]   -> low byte of stall counter
LEDR[8]     -> breakpoint trigger
LEDR[9]     -> flush activity indicator
```

## Build Configuration

The main configuration constants are located in `cond_compilation_package(5).vhd`.

Important parameters:

| Constant | Meaning |
|---|---|
| `G_MODELSIM` | `1` for ModelSim-style simulation, `0` for FPGA build. |
| `G_WORD_GRANULARITY` | Selects word-addressed or byte-addressed memory behavior. |
| `G_ADDRWIDTH` | ITCM/DTCM memory address width. |
| `G_DATA_WORDSNUM` | Number of memory words. |
| `G_PC_WIDTH` | Program counter width. |
| `G_MA_WIDTH` | Memory address width used by the datapath. |
| `G_PLL_DIV`, `G_PLL_MUL` | PLL configuration parameters used in FPGA mode. |

In the uploaded package, `G_MODELSIM` is set to `1`.  
For FPGA synthesis, set/override `MODELSIM = 0` so that the PLL path and FPGA reset polarity are used.

## Memory Initialization

Both instruction memory and data memory are initialized from `.hex` files:

- ITCM initialization is defined in `IFETCH_pipeline(3).VHD`.
- DTCM initialization is defined in `DMEMORY(6).VHD`.

The uploaded files currently contain absolute Windows paths, for example:

```text
C:\Users\ASUS\Desktop\Computers_LAB\Lab5\Material\Benchmark_Apps\test4\RV32IM\man_compiled\bin\M9K-intel\ITCM.hex
C:\Users\ASUS\Desktop\Computers_LAB\Lab5\Material\Benchmark_Apps\test4\RV32IM\man_compiled\bin\M9K-intel\DTCM.hex
```

Before running the project on another computer, update these paths or move the `.hex` files into the project directory and use relative paths.

## Suggested Compilation Order

A safe compilation order is:

```tcl
vlib work
vmap work work

vcom "cond_compilation_package(5).vhd"
vcom "const_package(5).vhd"
vcom "aux_package_pipeline(1).vhd"

vcom "PLL(5).vhd"
vcom "CONTROL(5).VHD"
vcom "IFETCH_pipeline(3).VHD"
vcom "IDECODE_pipeline(1).VHD"
vcom "EXECUTE(4).VHD"
vcom "DMEMORY(6).VHD"

vcom "IF_ID_REG(2).vhd"
vcom "ID_EX_REG(2).vhd"
vcom "EX_MEM_REG(2).vhd"
vcom "MEM_WB_REG(2).vhd"

vcom "forwarding_unit(4).vhd"
vcom "stall_unit(7).vhd"
vcom "pipeline_muxes(3).vhd"
vcom "Multiplier16_adapted_simple(2).vhd"

vcom "RV32IM_PIPELINE_CORE_start(3).vhd"
vcom "RV32IM_pipeline_top(1).vhd"
```

For ModelSim, make sure the Intel/Altera `altera_mf` simulation library is available because `IFETCH_pipeline` and `DMEMORY` instantiate `altsyncram`.

## FPGA Usage Notes

For FPGA implementation:

1. Set the top-level entity to:

```text
RV32IM_pipeline_top
```

2. Map board pins in the Quartus `.qsf` file:

```text
clk_i  -> CLOCK_50
rst_i  -> KEY0, active-low on the board wrapper comments
SW     -> SW7..SW0
LEDR   -> LEDR9..LEDR0
```

3. Use SignalTap to observe:

```text
pc_o, instruction_o,
IDpc_o, EXpc_o, MEMpc_o, WBpc_o,
IDinstruction_o, EXinstruction_o, MEMinstruction_o, WBinstruction_o,
STCNT_o, FHCNT_o, CLKCNT_o, STRIGGER_o
```

## Repository File List

```text
aux_package_pipeline(1).vhd
cond_compilation_package(5).vhd
const_package(5).vhd
CONTROL(5).VHD
DMEMORY(6).VHD
EX_MEM_REG(2).vhd
EXECUTE(4).VHD
forwarding_unit(4).vhd
ID_EX_REG(2).vhd
IDECODE_pipeline(1).VHD
IF_ID_REG(2).vhd
IFETCH_pipeline(3).VHD
MEM_WB_REG(2).vhd
Multiplier16_adapted_simple(2).vhd
pipeline_muxes(3).vhd
PLL(5).vhd
RV32IM_PIPELINE_CORE_start(3).vhd
RV32IM_pipeline_top(1).vhd
stall_unit(7).vhd
```

## Notes and Limitations

- This package does not include a testbench file.
- The design depends on Intel/Altera `altsyncram`, so pure generic VHDL simulators may require vendor libraries or memory-model replacements.
- The uploaded memory initialization paths are machine-specific and should be changed before reuse.
- The M-extension datapath currently supports the uploaded `mul` implementation. Other M-extension constants exist in the package but are not fully integrated in the current control/datapath.
- File names contain copy suffixes such as `(1)`, `(2)`, etc. The VHDL entity names are unaffected, but for a clean repository it is recommended to rename files to stable names without copy suffixes.

## Recommended Clean File Names

For a cleaner Git repository, the files can be renamed as follows:

```text
aux_package_pipeline.vhd
cond_compilation_package.vhd
const_package.vhd
CONTROL.vhd
DMEMORY.vhd
EX_MEM_REG.vhd
EXECUTE.vhd
forwarding_unit.vhd
ID_EX_REG.vhd
IDECODE_pipeline.vhd
IF_ID_REG.vhd
IFETCH_pipeline.vhd
MEM_WB_REG.vhd
Multiplier16_adapted_simple.vhd
pipeline_muxes.vhd
PLL.vhd
RV32IM_PIPELINE_CORE.vhd
RV32IM_pipeline_top.vhd
stall_unit.vhd
```

