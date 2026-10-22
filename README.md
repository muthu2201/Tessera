# Tessera RTL Prototype

Tessera is an evolving modular execution-fabric prototype. The current RTL integrates a shared command dispatcher, vector and tensor execution tiles, completion buffering, and dependency tracking. The development direction is software-first: define behavior in an executable reference model, then require hardware implementations to match it. This repository validates the design through simulation and open-source synthesis and place-and-route experiments; it is not yet a board-qualified accelerator.

## Software-first contract

- [Software-visible contract](docs/SOFTWARE_CONTRACT.md): command semantics, operations, bit widths, errors, tags, and completion behavior.
- [Python reference model](software/tessera_model.py): executable model of currently implemented vector and tensor operations.
- [Software model tests](software/test_tessera_model.py): arithmetic boundaries, wraparound, invalid operations, and tag preservation.

Run the software tests locally with:

```sh
make software-test
```

The reference model only specifies behavior already implemented in the current RTL. It does not claim to define a full ISA, compiler, runtime, memory system, or complete GPU programming model. Those are future architecture decisions.

## Current hardware architecture

- `rtl/tessera_execution_system.sv`: multi-client shared execution system. Commands select either the vector tile or tensor tile; completions are merged into a shared result FIFO.
- `rtl/tessera_vec_tile.sv`: 16-bit integer operations: signed add, multiply-low, min, max, and XOR.
- `rtl/tessera_tensor_tile.sv`: signed 16×16 multiplication and 32-bit multiply-accumulate.
- `rtl/tessera_dependency_scoreboard.sv`: per-client live-tag tracking, duplicate-allocation protection, completion validation, and capacity backpressure.
- `rtl/tessera_dispatcher.sv`: round-robin arbitration with state changes only on accepted handshakes.
- `rtl/tessera_command_fifo.sv`: synchronous ready/valid FIFO.
- `rtl/tessera_execution_system_fpga_shell.sv`: single-client physical-interface shell for exploratory ECP5 place-and-route. It retains the shared vector/tensor core but does not replace the multi-client top level.

See [the command format](docs/COMMAND_FORMAT.md) and [execution-system resource report](docs/EXECUTION_SYSTEM_RESOURCE_ESTIMATE.md) for implementation details. The older command-path/control-plane prototype is separate from the integrated vector/tensor execution system; do not treat its placeholder execution stub as real arithmetic execution.

## Validation

The GitHub Actions workflows run the Python reference-model tests, self-checking SystemVerilog testbenches, generic synthesis, ECP5 technology mapping, and an exploratory place-and-route job. The RTL coverage includes:

- Round-robin arbitration, ready/valid handshakes, reset, and payload stability under backpressure.
- FIFO full/empty behavior, simultaneous push/pop, and deterministic randomized reference-model stress.
- Vector signed arithmetic boundaries and unsupported-opcode behavior.
- Tensor signed multiplication boundaries, MAC overflow/wraparound, and unsupported-opcode behavior.
- Shared execution, mixed vector/tensor bursts, completion backpressure, duplicate and reused tags, reset recovery, and deterministic transaction stress.
- Scoreboard capacity, client-isolated tags, unknown completions, slot reuse, reset, and simultaneous allocation/completion.

Latest workflows on commit `978f5db42415ce85d90507c06ddc58031fb9570d` passed:
- [Full RTL CI](https://github.com/muthu2201/Tessera/actions/runs/39734563736).
- [Execution System CI](https://github.com/muthu2201/Tessera/actions/runs/39734563740).

## Exploratory ECP5 result

The single-client shell has previously completed nextpnr routing for an ECP5-25K, CABGA381, speed-grade-6 target. The recorded post-route estimated maximum frequency was 45.59 MHz against an explicit 40 MHz target. See the resource report for utilization and reproduction links.

This is **not timing sign-off**: the flow allows unconstrained I/O and has no board-specific pin assignment or clock/I/O timing constraints. The raw four-client interface also exceeds the selected package's I/O count, so the shell is a narrower integration experiment, not evidence that the full top-level interface fits that package. No physical FPGA board test has been performed.

## Local RTL commands

Install Icarus Verilog, Yosys, and nextpnr-ecp5, then use the targets defined by the Makefile:

```sh
make test
make synth
make ecp5
```

## Not yet established

Passing software tests, RTL simulation, and synthesis does not establish board operation, power, energy efficiency, application-level performance, scalability, or superiority to a commercial GPU. Those claims require defined workloads, a selected board and interface, constrained timing, and measured hardware results.
