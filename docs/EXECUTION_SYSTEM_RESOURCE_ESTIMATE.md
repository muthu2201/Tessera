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
RTL revision: `2b9f1732f17055da6af146eb47b1ceb6ba9b2663`  
Top module: `tessera_execution_system_fpga_shell`  
Tool flow: Yosys 0.33 `synth_ecp5` + nextpnr-ecp5, ECP5-25K / CABGA381 / speed grade 6

| Metric | Result |
|---|---:|
| LUT4 utilization | 1,435 / 24,288 (5%) |
| Flip-flops | 405 / 24,288 (1%) |
| Hard multipliers | 3 / 28 (10%) |
| I/O cells | 128 / 197 (64%) |
| nextpnr estimated max frequency, placement | 35.94 MHz (initial 12 MHz-target run) |
| nextpnr estimated max frequency, after routing | 46.80 MHz |
| Explicit nextpnr target | 40 MHz, PASS after routing |
| Routing | Completed |

The shell's physical interface fits this package, unlike the raw four-client top-level interface, which required 363 I/O cells against 197 available and failed placement. The single-client shell exposes one requester's command and data buses while retaining the shared vector/tensor core.

**40 MHz target follow-up:** Commit `2b9f1732f17055da6af146eb47b1ceb6ba9b2663` added an explicit `--freq 40` constraint to the nextpnr command. The place-route job completed successfully and reported a post-route maximum frequency of 46.80 MHz, PASS at 40.00 MHz. [Execution System CI run](https://github.com/muthu2201/Tessera/actions/runs/39717448064) and [full RTL CI run](https://github.com/muthu2201/Tessera/actions/runs/39717448094) both passed.

**Important limitations:** This run uses `--lpf-allow-unconstrained` and no board-specific pin assignment or clock constraint. The 40 MHz result is an exploratory estimate, not timing sign-off or proof of board operation. Apply the intended board's LPF constraints and validate its actual clock and I/O timing before claiming hardware readiness.

Reproduction artifact and job logs: [latest Execution System CI run](https://github.com/muthu2201/Tessera/actions/runs/39717448064), artifact `tessera-single-client-shell-ecp5-place-route`.


## Latest scoreboard optimization validation

Date: 2026-10-22  
RTL revision: `04ef6a4eeafaccbee296257631b8c7a7bcddb6f3`  
Change: permit same-cycle reuse of a scoreboard slot released by a known completion, including when the scoreboard is full.

The regression test fills all eight slots in its reduced test configuration, verifies that allocation remains blocked without a completion, then presents a known completion and a new allocation together. It checks that the replacement tag is tracked and that the live count remains constant. Both [Execution System CI run 39723253627](https://github.com/muthu2201/Tessera/actions/runs/39723253627) and [full RTL CI run 39723253574](https://github.com/muthu2201/Tessera/actions/runs/39723253574) passed.

The latest full execution-system ECP5 mapping reported 3,898 LUT4 cells, 957 flip-flops, and 3 hard multipliers; Yosys `check` reported zero problems. The single-client shell place-and-route run reported a post-route estimated maximum frequency of 45.59 MHz, passing the exploratory 40 MHz target. See the linked CI run for the exact logs and artifacts.

These figures are from CI's exploratory configuration. The timing run still permits unconstrained I/O and has no board-specific pin or clock/I/O timing constraints. The result is not timing sign-off or physical-board validation.
