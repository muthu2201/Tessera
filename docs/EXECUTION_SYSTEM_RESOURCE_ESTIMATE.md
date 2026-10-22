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

## Single-client FPGA shell place-and-route experiment

Date: 2026-10-22  
RTL revision: `9f2698b39c8abf3615da9241bab47a7f9f9697b9`  
Top module: `tessera_execution_system_fpga_shell`  
Tool flow: Yosys 0.33 `synth_ecp5` + nextpnr-ecp5, ECP5-25K / CABGA381 / speed grade 6

| Metric | Result |
|---|---:|
| LUT4 utilization | 1,435 / 24,288 (5%) |
| Flip-flops | 405 / 24,288 (1%) |
| Hard multipliers | 3 / 28 (10%) |
| I/O cells | 128 / 197 (64%) |
| nextpnr estimated max frequency, placement | 35.94 MHz |
| nextpnr estimated max frequency, after routing | 46.80 MHz |
| Routing | Completed |

The shell's physical interface fits this package, unlike the raw four-client top-level interface, which required 363 I/O cells against 197 available and failed placement. The single-client shell exposes one requester's command and data buses while retaining the shared vector/tensor core.

**Important limitations:** This run uses `--lpf-allow-unconstrained` and no board-specific pin assignment or clock constraint. nextpnr reports a derived 12 MHz target and estimated frequencies; these are exploratory tool estimates, not timing sign-off or proof of board operation. The reported routed estimate is not a substitute for applying the intended board's LPF constraints and validating its actual clock and I/O timing.

Reproduction artifact and job logs: [Execution System CI run](https://github.com/muthu2201/Tessera/actions/runs/39717272231), artifact `tessera-single-client-shell-ecp5-place-route`.
