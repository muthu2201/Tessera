# Tessera software-first roadmap

## Decision

Treat the software-visible contract as the source of truth. Hardware is an implementation of that contract, not the place where software behavior is improvised. The current implementation remains prototype v0; this roadmap does not claim a complete GPU ISA or runtime.

## Stage 1: Freeze the prototype v0 semantics

- [x] Document vector and tensor operations and exact integer wraparound.
- [x] Add a bit-accurate Python reference model.
- [x] Test known boundaries, invalid opcodes, and result/tag behavior.
- [x] Add deterministic randomized arithmetic property tests.
- [ ] Add automated differential checks comparing a shared set of software vectors with RTL simulation.

**Exit gate:** Every documented operation has examples and boundary tests, and software/RTL agree on those vectors.

## Stage 2: Define the programming interface

Before designing new hardware, settle these items in versioned documents:

1. Command representation and API: Python first, then a stable C ABI if needed.
2. Execution model: command submission, tag ownership, completion consumption, error handling, and reset behavior.
3. Memory model: initially decide whether the first software target is register-fed operands only or includes DMA and addressable memory.
4. Parallelism: number of requesters, independent outstanding commands, ordering rules, and synchronization.
5. Numeric contract: signedness, widths, overflow, rounding, saturation, and future vector/tensor data types.
6. Workload targets: representative kernels and measurable throughput/latency goals.

Items not implemented in RTL must stay marked as proposed, not silently described as supported features.

## Stage 3: Build a useful software simulator

- Add a small program/workload API on top of the reference operations.
- Model queue capacity, tag reuse, completion backpressure, and deterministic execution latency.
- Add golden workloads such as vector transforms, dot products, and multiply-accumulate loops.
- Report operations completed, simulated cycles, queue stalls, and latency. These are model results, not physical performance claims.

## Stage 4: Make the RTL match

- Use common golden vectors for Python and SystemVerilog.
- Add differential testing to CI.
- Verify reset, simultaneous events, stalls, invalid commands, and capacity boundaries.
- Run synthesis and constrained place-and-route after selecting a target device and interface.

## Stage 5: Choose hardware from requirements

Select an FPGA/ASIC target only after the software contract, workloads, I/O requirements, and resource/performance budgets are concrete. Then define the host interface, pin map, clock/reset scheme, and real timing constraints. Physical validation remains mandatory before claiming board operation.

## Current limitations

The current RTL provides 16-bit integer vector operations and signed 16x16 multiply/MAC through a shared execution path. It does not yet provide general memory loads/stores, a compiler, a C ABI, a driver, virtual memory, cache coherence, floating point, SIMT thread semantics, or a complete GPU runtime.
