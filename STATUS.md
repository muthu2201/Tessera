# Status

- [x] Initial dispatcher RTL written
- [x] Directed testbench and initial CI pass
- [x] Randomized request/ready stress test added
- [x] Yosys generic synthesis and structural checks added
- [x] Provisional target selected: Lattice ECP5 LFE5U-25F / CABGA381 / speed grade 6
- [x] ECP5 mapping and nextpnr place-and-route stages configured in CI
- [ ] Latest randomized simulation and ECP5 place-and-route run confirmed
- [ ] Select a physical ECP5 board and add its real pin constraints
- [ ] Board-specific timing closure and bitstream validation
- [ ] Hardware power/performance measurements

The current ECP5 flow allows unconstrained I/O because no board is selected yet. It can assess device mapping and placement/routing feasibility, but it does not create a board-validated bitstream. Generic synthesis and simulation do not prove deadlock freedom for a larger system or performance/energy versus GPUs.
