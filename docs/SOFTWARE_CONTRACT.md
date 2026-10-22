# Tessera software-first contract (prototype v0)

## Goal

The software-visible behavior is the reference. Hardware implementations must match this contract or explicitly version any incompatible change. This document describes only behavior implemented by the current vector/tensor execution path; it is not a complete ISA, compiler, runtime, memory model, or GPU specification.

## Command model

A command identifies a client, execution unit, operation, tag, two 16-bit operands, and a 32-bit accumulator value. The current RTL accepts one command at a time through the shared dispatcher, chooses the vector or tensor tile using the client's unit-select bit, and returns a tagged completion through a shared FIFO.

- `client`: requester index; default system has four clients.
- `unit`: `vec` or `tensor`.
- `op`: operation code defined below.
- `tag`: opaque 8-bit correlation tag by default. A client/tag pair must not be reused while it is outstanding.
- `a`, `b`: signed 16-bit operands. Values are interpreted using their low 16 bits.
- `accumulator`: signed 32-bit accumulator input for tensor MAC.
- `status=0`: success. `status=1`: unsupported unit/opcode.
- `result`: 32-bit completion bit pattern. Vector results are signed 16-bit results sign-extended to 32 bits; tensor results are 32-bit two's-complement results. Invalid commands return zero.

## Implemented operations

| Unit | Opcode | Meaning | Result behavior |
|---|---:|---|---|
| vec | 0 | signed add | wrap to 16 bits, sign-extend to 32 |
| vec | 1 | signed multiply-low | retain low 16 product bits, sign-extend to 32 |
| vec | 2 | signed minimum | signed compare, sign-extend selected 16-bit value |
| vec | 3 | signed maximum | signed compare, sign-extend selected 16-bit value |
| vec | 4 | bitwise XOR | XOR low 16 bits, sign-extend as signed 16-bit result |
| tensor | 0 | signed 16×16 multiply | exact signed 32-bit product |
| tensor | 1 | signed multiply-accumulate | `accumulator + a*b`, wrap to 32 bits |
| either | other | invalid opcode | status 1, result 0 |

The executable reference is `software/tessera_model.py`. It intentionally uses integer bit masking to make wraparound explicit and returns result bit patterns matching RTL ports.

## Completion and backpressure

A requester holds its command request and payload stable until the dispatcher grants it. Completion fields must remain stable while `completion_valid=1` and `completion_ready=0`. Completion consumption is the point at which a live client/tag reservation is released. Duplicate live client/tag pairs are blocked. Unknown completion tags are a verification error in the scoreboard, not a separate software-visible interrupt today.

## Current non-goals

The current design does not yet define general memory loads/stores, virtual addresses, cache coherence, a host driver, binary instruction encoding, compiler ABI, multi-thread SIMT semantics, floating point, interrupts, context switching, or an application-level performance target. Do not assume those exist merely because the word GPU is convenient.

## Development rule

Add or change behavior in this order:

1. Update this contract and the Python reference model.
2. Add unit tests for normal cases, boundary values, invalid inputs, and wraparound.
3. Make RTL implement the same behavior and add/extend self-checking testbenches.
4. Run software and RTL CI together.
5. For hardware-specific claims, run implementation with real board constraints and validate on the selected device.
