# Status

- [x] Initial dispatcher RTL written
- [x] Directed testbench and initial CI pass
- [x] CI workflow configured
- [x] Randomized request/ready stress test added
- [x] Yosys synthesis and structural check added to CI
- [ ] New randomized simulation and synthesis run confirmed
- [ ] FPGA-specific synthesis/timing closure
- [ ] Hardware measurements

The dispatcher is a small control-plane prototype. Passing Icarus and generic Yosys checks does not prove FPGA timing closure, deadlock freedom for a larger system, or performance/energy versus GPUs.
