# RV32I / Partial RV32IM Single-Cycle RISC-V Core

This repository contains a VHDL implementation of a single-cycle 32-bit RISC-V CPU core developed for the **Advanced CPU Architecture and Hardware Accelerators Lab** at BGU.

The design is based on a classic single-cycle datapath and includes instruction fetch, decode/register-file, control, execute/ALU, data memory, and a top-level integration module. The project also includes FPGA-oriented support such as an Intel/Altera PLL, `altsyncram` instruction/data memories, and debug outputs intended for SignalTap validation.

> **Note:** The core is primarily an RV32I implementation with a limited `mul` addition from the RV32M extension. The current multiplier uses only the lower 16 bits of each source operand and produces a 32-bit result.

---

## Project Structure

```text
.
├── RV32I_CORE.vhd                 # Top-level structural CPU core
├── IFETCH.vhd                     # Program counter logic and instruction memory (ITCM)
├── IDECODE.vhd                    # Register file, immediate generation, write-back mux
├── CONTROL.vhd                    # Combinational instruction decoder and control unit
├── EXECUTE.vhd                    # ALU, branch comparison, jump/branch target generation
├── DMEMORY.vhd                    # Data memory (DTCM) using Intel/Altera altsyncram
├── Multiplier16.vhd               # 16x16 multiplier used for the partial MUL operation
├── PLL.vhd                        # Intel/Altera ALTPLL wrapper for FPGA clock generation
├── const_package.vhd              # Instruction masks, opcodes, ALU operation constants
├── cond_compilation_package.vhd   # Global configuration parameters
└── aux_package.vhd                # Component declarations
```

If your uploaded source files include suffixes such as `(2)`, `(3)`, or `(4)`, it is recommended to rename them to the clean filenames shown above before committing them to the repository.

---

## High-Level Architecture

The top-level module is `RV32I_CORE`. It connects the following blocks:

1. **IFETCH**  
   Holds and updates the program counter, calculates `PC + 4`, selects the next PC for branches and jumps, and reads instructions from the ITCM ROM.

2. **IDECODE**  
   Extracts opcode, register indexes, and immediates from the instruction. It implements the 32-register RISC-V register file, protects register `x0` from writes, generates sign-extended immediates, and selects the write-back data.

3. **CONTROL**  
   Decodes the 32-bit instruction into datapath control signals such as `RegWrite`, `MemRead`, `MemWrite`, `Branch`, `Jal`, `Jalr`, `ALUSrc`, `MemtoReg`, and `ALUOp`.

4. **EXECUTE**  
   Implements the ALU, branch condition checks, branch/jump target address calculation, and the partial `mul` operation through `Multiplier16`.

5. **DMEMORY**  
   Implements the data memory using Intel/Altera `altsyncram` in single-port RAM mode.

6. **PLL**  
   Used in FPGA mode to generate the internal clock and provide a PLL lock signal. In ModelSim mode, the external clock is used directly.

---

## Main Features

- 32-bit single-cycle RISC-V datapath
- Separate instruction and data memories: ITCM and DTCM
- Register file with 32 general-purpose registers
- Hard-wired zero register `x0`
- Arithmetic, logical, shift, comparison, branch, jump, load/store, and upper-immediate control paths
- SignalTap-oriented debug outputs from the top level
- FPGA and ModelSim configuration mode through `G_MODELSIM`
- Optional word-granularity or byte-granularity addressing through `G_WORD_GRANULARITY`
- Partial RV32M support through a 16x16 multiplier used for `mul`

---

## Supported Instruction Groups

### RV32I arithmetic and logic

- `add`, `sub`, `addi`
- `and`, `andi`
- `or`, `ori`
- `xor`, `xori`
- `sll`, `slli`
- `srl`, `srli`
- `sra`, `srai`
- `slt`, `slti`
- `sltu`, `sltiu`

### Branches and jumps

- `beq`, `bne`
- `blt`, `bge`
- `bltu`, `bgeu`
- `jal`, `jalr`

### Upper immediate instructions

- `lui`
- `auipc`

### Memory instructions

The control unit decodes:

- Loads: `lb`, `lh`, `lw`, `lbu`, `lhu`, `lwu`
- Stores: `sb`, `sh`, `sw`

However, the current DTCM implementation is a 32-bit single-port memory without byte-enable logic. Therefore, word accesses such as `lw` and `sw` are the safest supported memory operations unless byte/halfword handling is explicitly added and verified.

### Partial RV32M support

- `mul`

Current limitation: `mul` is implemented as `rs1[15:0] * rs2[15:0]`, not as a full 32x32 RV32M multiplier.

---

## Important Configuration Parameters

Global configuration is defined in `cond_compilation_package.vhd`.

| Parameter | Purpose |
|---|---|
| `G_MODELSIM` | Selects simulation or FPGA behavior. `1` = ModelSim, `0` = FPGA. |
| `G_WORD_GRANULARITY` | Selects word-addressed or byte-addressed memory behavior. |
| `G_ADDRWIDTH` | Address width for ITCM/DTCM. |
| `G_DATA_WORDSNUM` | Number of memory words. |
| `G_PC_WIDTH` | Program counter width. |
| `G_MA_WIDTH` | Memory address width. |
| `DBUS_WIDTH` | Data bus width. Default is 32 bits. |

The uploaded configuration is set to FPGA mode by default:

```vhdl
constant G_MODELSIM          : integer := 0; -- 1 = ModelSim, 0 = FPGA
constant G_WORD_GRANULARITY  : boolean := True;
constant G_ADDRWIDTH         : integer := M9K_TCM8KiB_ADDRWIDTH;
constant G_DATA_WORDSNUM     : integer := M9K_TCM8KiB_WORDSNUM;
constant G_PC_WIDTH          : integer := PC_WIDTH_TCM8KiB;
constant G_MA_WIDTH          : integer := MA_WIDTH_TCM8KiB;
```

For ModelSim simulation, change:

```vhdl
constant G_MODELSIM : integer := 1;
```

---

## Memory Initialization

Both instruction memory and data memory are initialized from `.hex` files.

The paths are currently hard-coded inside:

- `IFETCH.vhd` for `ITCM.hex`
- `DMEMORY.vhd` for `DTCM.hex`

Before running the project on another machine, update these paths to match your local project structure.

Example:

```vhdl
init_file => "path/to/ITCM.hex"
```

and:

```vhdl
init_file => "path/to/DTCM.hex"
```

For a cleaner repository, consider moving these paths to constants or using relative paths where supported by your toolchain.

---

## Compilation Order

A recommended compilation order is:

```text
cond_compilation_package.vhd
const_package.vhd
aux_package.vhd
Multiplier16.vhd
PLL.vhd
CONTROL.vhd
DMEMORY.vhd
EXECUTE.vhd
IDECODE.vhd
IFETCH.vhd
RV32I_CORE.vhd
```

`EXECUTE.vhd` instantiates `Multiplier16`, so the multiplier should be compiled before `EXECUTE.vhd`.

The design uses VHDL-2008 constructs such as `process(all)`, so compile with VHDL-2008 support when using ModelSim/Questa.

---

## ModelSim / Questa Simulation Notes

This repository currently contains the design source files only. A testbench is not included in the uploaded files.

General flow:

```tcl
vlib work
vmap work work

vcom -2008 cond_compilation_package.vhd
vcom -2008 const_package.vhd
vcom -2008 aux_package.vhd
vcom -2008 Multiplier16.vhd
vcom -2008 CONTROL.vhd
vcom -2008 DMEMORY.vhd
vcom -2008 EXECUTE.vhd
vcom -2008 IDECODE.vhd
vcom -2008 IFETCH.vhd
vcom -2008 RV32I_CORE.vhd
```

Depending on the ModelSim version and installed Intel FPGA libraries, the `altsyncram` components may require the `altera_mf` library to be available and compiled.

Before simulation:

1. Set `G_MODELSIM = 1`.
2. Make sure the `ITCM.hex` and `DTCM.hex` files exist at the paths defined in the source files.
3. Compile or reference the Intel/Altera simulation libraries if required.
4. Compile and run the relevant testbench.

---

## Quartus / FPGA Notes

For FPGA synthesis:

1. Keep `G_MODELSIM = 0`.
2. Add all VHDL source files to the Quartus project.
3. Make sure the target FPGA family is compatible with the generated `PLL.vhd` and `altsyncram` configuration.
4. Update the ITCM/DTCM `.hex` initialization paths.
5. Use the top-level entity:

```text
RV32I_CORE
```

The top-level exposes several internal signals as outputs for debugging and SignalTap validation, including:

- Program counter
- Current instruction
- Register-file read data
- ALU result
- Branch-taken signal
- DTCM address and data
- Main clock counter
- Selected control signals

---

## Reset and Clock Behavior

The top-level reset behavior depends on `G_MODELSIM`:

- **ModelSim mode**: reset is active-high.
- **FPGA mode**: reset is adapted for an active-low FPGA push button, and the core is also held in reset until the PLL is locked.

In FPGA mode, the internal clock is generated by `PLL.vhd`. In ModelSim mode, the input clock is passed directly into the core.

---

## Known Limitations and Notes

- The design is single-cycle, so each instruction is intended to complete in one clock cycle.
- `mul` is not a full 32x32 RV32M implementation; it currently multiplies only the lower 16 bits of the two operands.
- Byte and halfword memory accesses are decoded, but the DTCM does not currently implement byte-enable logic or explicit byte/halfword sign-extension handling.
- The source files use Intel/Altera-specific memory primitives, so portability to non-Intel FPGA toolchains requires replacing `altsyncram`.
- Memory initialization paths are absolute and should be changed before using the project on another machine.
- The uploaded files do not include a testbench, `.do` file, `.qsf` project file, or benchmark `.hex` files.

---

## Suggested Future Improvements

- Add a full 32x32 RV32M multiplier.
- Add byte-enable support for `sb`, `sh`, `lb`, `lh`, `lbu`, and `lhu`.
- Replace absolute `.hex` paths with relative paths.
- Add a ModelSim testbench and automated compile script.
- Add a Quartus project file or setup instructions.
- Add instruction-level verification tests for each supported instruction group.
- Add waveform screenshots or SignalTap validation results.

---

## Top-Level Entity

```vhdl
entity RV32I_CORE is
    generic (
        WORD_GRANULARITY : boolean := G_WORD_GRANULARITY;
        MODELSIM         : integer := G_MODELSIM;
        DATA_BUS_WIDTH   : integer := 32;
        ITCM_ADDR_WIDTH  : integer := G_ADDRWIDTH;
        DTCM_ADDR_WIDTH  : integer := G_ADDRWIDTH;
        PC_WIDTH         : integer := G_PC_WIDTH;
        MA_WIDTH         : integer := G_MA_WIDTH;
        DATA_WORDS_NUM   : integer := G_DATA_WORDSNUM;
        CLK_CNT_WIDTH    : integer := 16
    );
end RV32I_CORE;
```

---

## License

No explicit license file is currently included. Add a `LICENSE` file before publishing or sharing the repository publicly.
