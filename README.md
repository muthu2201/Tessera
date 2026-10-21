# Tessera RTL CI Starter

This repository starts Tessera's hardware-validation path with a small synthesizable command dispatcher and a self-checking SystemVerilog testbench.

## Scope

- Typed resource requests and round-robin arbitration
- Ready/valid-style request acceptance and completion tracking
- Functional tests for arbitration, backpressure, reset, and completion
- GitHub Actions CI using Icarus Verilog

This is a control-plane starter, not the full Tessera fabric, and it does not establish performance or energy claims.

## Run locally

Install Icarus Verilog and GNU Make, then run:

```sh
make test
```

The CI workflow runs the same command on pushes and pull requests.
