# Tessera RTL CI Starter

This repository starts Tessera's hardware-validation path with a small synthesizable command dispatcher and a self-checking SystemVerilog testbench.

## Scope

- Typed resource requests and round-robin arbitration
- Ready/valid-style request acceptance and completion tracking
- Directed and randomized functional tests for arbitration, backpressure, reset, and payload integrity
- GitHub Actions CI using Icarus Verilog, Yosys, and nextpnr

## Provisional FPGA target

The first open-source implementation target is **Lattice ECP5 LFE5U-25F, CABGA381, speed grade 6**. CI maps the dispatcher with Yosys and runs nextpnr-ecp5 place-and-route at a 50 MHz target.

This is a small control-plane validation target, not the final Tessera accelerator. CI currently allows unconstrained I/O because no specific development board or pin map has been selected. Therefore the result is a device-level placement/routing estimate, not a board-ready bitstream or verified timing closure under real board constraints.

## Run locally

Install Icarus Verilog, Yosys, and nextpnr-ecp5, then run:

```sh
make test
make synth
make ecp5
```

The CI workflow runs simulation, generic synthesis, ECP5 mapping, and place-and-route on pushes and pull requests.

Passing these checks does not establish power, energy, application performance, or superiority to a commercial GPU.
