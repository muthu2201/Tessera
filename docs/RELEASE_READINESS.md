# Tessera Release Readiness Report

Date: 2026-10-22  
Validated RTL revision: `04ef6a4eeafaccbee296257631b8c7a7bcddb6f3`  
Current documentation revision: `63750791ee014683659574dc48001e0dbbe9d0d3`

## Status

**RTL/software validation passes; hardware release is not yet qualified.**

The two CI workflows passed on the validated RTL revision:
- [Execution System CI run 39723253627](https://github.com/muthu2201/Tessera/actions/runs/39723253627): simulation, synthesis, and single-client shell place-and-route succeeded.
- [Full RTL CI run 39723253574](https://github.com/muthu2201/Tessera/actions/runs/39723253574): testbench matrix and synthesis matrix succeeded.

The documentation-only revision `63750791ee014683659574dc48001e0dbbe9d0d3` also passed both workflows:
- [Execution System CI run 39723536245](https://github.com/muthu2201/Tessera/actions/runs/39723536245)
- [Full RTL CI run 39723536234](https://github.com/muthu2201/Tessera/actions/runs/39723536234)

## Verified coverage

- Dispatcher arbitration and handshake behavior.
- FIFO backpressure, simultaneous push/pop, and deterministic randomized reference-model checks.
- Vector signed arithmetic boundaries and unsupported-opcode status.
- Tensor signed multiplication, MAC wraparound, and unsupported-opcode status.
- Shared execution-system traffic, mixed vector/tensor bursts, completion backpressure and payload stability.
- Per-client dependency tags, duplicate prevention, unknown-completion handling, capacity limits, reset recovery, slot reuse, and same-cycle allocation/completion.
- Generic synthesis, ECP5 technology mapping, and exploratory place-and-route of the single-client shell.

## Resource and timing evidence

The latest execution-system mapping reported 3,898 LUT4 cells, 957 flip-flops, and 3 hard multipliers. Yosys reported zero structural problems. The single-client ECP5 shell place-and-route run estimated 45.59 MHz after routing and passed the configured 40 MHz target.

These are CI/tool estimates, not measurements from physical hardware. The flow permits unconstrained I/O and does not include a board-specific pin map or real clock/I/O timing constraints.

## Remaining release blockers

1. Select the actual FPGA board and verify its device/package and pin availability.
2. Define and review the host interface, clocking, reset, and I/O constraints for that board.
3. Run place-and-route with the board's real constraints and inspect timing paths, resource utilization, and warnings.
4. Program a physical board and run smoke tests for reset, command acceptance, arithmetic results, backpressure, and sustained mixed traffic.
5. Record measured frequency, power if available, and reproducible build/tool versions before making hardware-performance claims.

## Release decision

The repository is suitable as a **simulation- and synthesis-validated RTL prototype**. It is not yet appropriate to describe as a board-validated accelerator or a finished GPU. Keep those labels separate; marketing tends to promote the prototype to a finished product faster than physics permits.
