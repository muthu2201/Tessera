# Tessera Shared Execution System: Initial Resource Estimate

Date: 2026-10-22  
RTL revision: `157e0031a5432fe5542efb588efcb322778b64a0`  
Top module: `tessera_execution_system`  
Tool: Yosys 0.33, `synth_ecp5` target

## ECP5 mapped cell counts

| Resource | Mapped count |
|---|---:|
| LUT4 | 4,415 |
| TRELLIS_FF | 957 |
| MULT18X18D | 3 |
| CCU2C | 176 |
| PFUMX | 919 |
| L6MUX21 | 368 |
| Total mapped cells | 6,838 |

The ECP5 mapping pass completed and Yosys `check` reported zero problems. The generic synthesis pass also completed with zero reported problems and 10,129 generic cells before technology-specific mapping.

## Interpretation

- This is an early synthesis estimate for the integrated four-client configuration used by the module defaults, not a place-and-route result.
- The three `MULT18X18D` cells are inferred hard multiplier blocks in the ECP5 mapping. Do not treat them as three independent full tensor engines; they are the mapped arithmetic resources after synthesis optimization.
- LUT and flip-flop counts are useful for initial capacity planning, but they do not establish timing closure, power, board-level operation, or fit on a specific board with its constraints.
- No device-specific placement, routing, pin assignment, clock constraint, or timing sign-off was performed by this report.
- The existing CI's dispatcher-only ECP5 timing estimate is separate and must not be interpreted as timing for this whole execution system.

## Reproduction

The dedicated [Execution System CI](https://github.com/muthu2201/Tessera/actions/runs/39716465404) uploads a 30-day artifact named `tessera-execution-system-synthesis-reports` containing the generic Yosys log and ECP5 mapping log. The [full RTL CI](https://github.com/muthu2201/Tessera/actions/runs/39716465343) also passed for this revision.
