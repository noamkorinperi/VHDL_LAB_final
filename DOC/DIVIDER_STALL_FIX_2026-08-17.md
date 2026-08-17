# Divider integration stall fix — 17.08.2026

## Symptom

`run_stage3_divider_integration.do` originally stopped at 782 ns with:

```text
Stage 3 integration: PC changed while divider busy
```

At the failure point the accelerator was still busy, but the instruction had
already changed from the DIV at PC `0x34` to the following store at `0x38`.
Consequently the combinational DIV decode and the CPU stall both fell to zero.

## Root cause

The original single-cycle `IFETCH` addresses ITCM from `next_pc_w`. This is
correct during ordinary one-cycle execution, but a multi-cycle operation also
has to keep the instruction associated with the held `pc_q` visible. Holding
only the PC registers left ITCM pointing at the following instruction.

There was a second boundary condition at completion: fetch must remain stalled
through the system-clock edge that writes the divider result to `rd`. Releasing
on the combinational `done` pulse can replace the DIV decode before that edge.

## Fix

- `IFETCH.VHD` selects `pc_q` as the ITCM address while `stall_i='1'`.
- `RV32I_CORE.vhd` adds `div_retired_q`. The DIV instruction stays stalled
  through its single write-back edge, then receives exactly one release cycle.
- A new request is blocked while the previous instruction is being retired.
- The release flag clears after one clock, including for back-to-back divider
  instructions.
- The Stage 3 integration Wave/List now includes `div_start_w`, `stall_w`,
  `div_active_q`, and `div_retired_q`.

## Verification

- Stage 3 divider integration: PASS at 20462 ns.
- Stage 3 divider unit: PASS.
- Stage 0 baseline: PASS.
- Stage 1 interconnect: PASS.
- Stage 2 GPIO unit: PASS.
- Stage 2 GPIO/test0 integration: PASS.
- Stage 2 GPIO/test1/test2 integration: PASS.
- Quartus Analysis & Synthesis after the functional fix: 0 errors and 13
  warnings; the warnings are the previously documented non-blocking warnings.

The ModelSim arithmetic metavalue warnings occur only during initialization at
0 ps and are not the cause of the original failure.
