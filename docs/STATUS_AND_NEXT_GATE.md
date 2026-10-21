# Tessera control-plane prototype: status and next implementation gate

## What currently passes
- Round-robin requester dispatcher with backpressure and randomized test.
- Bounded command FIFO with directed and 1,000-cycle reference-model stress test.
- Integrated dispatcher-to-command-FIFO path.
- Tagged completion queue with ordering and backpressure test.
- End-to-end command path through a deterministic latency stub into a tagged completion queue.
- Generic Yosys synthesis and ECP5 mapping/place-and-route estimates for the existing dispatcher path.

Latest end-to-end CI: https://github.com/muthu2201/Tessera/actions/runs/39688334416

## Current boundary
The execution stage is a deterministic protocol stub. It does not execute tensor/vector operations. Completion status is currently always success. No dependency scoreboard, duplicate/stale-tag rejection, timeout, cancellation, memory subsystem, or real compute datapath exists yet. ECP5 place-and-route is unconstrained at the I/O level and is not physical-board validation. Formal SAT assertions remain outside the required green CI path while the Yosys register-import issue is isolated.

## Next meaningful milestone: typed tile execution contract
Implement one generic tile interface rather than adding more isolated control modules:
1. Command acceptance carries client_id, op, tag, and a small operand/payload address field.
2. Tile advertises ready/busy; command acceptance only when ready.
3. Tile returns {client_id, tag, status, result} through a completion handshake.
4. Per-tag scoreboard marks accepted commands in-flight and rejects duplicate live tags.
5. Completion clears the matching in-flight entry; unknown/stale tags raise an error flag.
6. Test concurrent clients, backpressure, out-of-order completion, duplicate tags, unknown tags, and reset.
7. Keep the stub as one test implementation; replace it later with a real VEC tile first, then TENSOR.

## Non-goals for this milestone
Do not claim NVIDIA performance, energy efficiency, full GPU capability, or a production compiler. No physical hardware measurements exist. The current proof point is control-path correctness under simulation and open-source synthesis estimates.
