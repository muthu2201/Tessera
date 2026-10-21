# Tessera command format (prototype v0)

This document defines the first software-visible contract for the current RTL path. It is intentionally small; it is not the complete Tessera ISA.

## Requester interface

Each requester presents one request bit and packed per-client operation and tag fields to `tessera_dispatcher`.

- `req[i]`: requester i has a pending command.
- `op_bus[i*OP_W +: OP_W]`: operation code for requester i.
- `tag_bus[i*TAG_W +: TAG_W]`: opaque requester-supplied tag.
- `grant[i]`: one-cycle acceptance pulse for requester i. A requester must keep its request and payload stable until granted.
- `cmd_ready`: downstream FIFO can accept a command. Arbitration does not advance while this is low.

The dispatcher chooses a pending requester in round-robin order. Its outputs are accepted only when `cmd_valid && cmd_ready`; the grant vector is asserted only on that transfer.

## FIFO record

The packed command record is:

| Field | Width (default) | Meaning |
|---|---:|---|
| `client_id` | 2 bits | Source requester index, 0 to 3 |
| `op` | 3 bits | Operation class |
| `tag` | 8 bits | Opaque correlation tag |

Packed order from most significant to least significant bit is `{client_id, op, tag}`. With defaults, the record is 13 bits wide. The FIFO stores the complete record and preserves order.

## Provisional operation classes

These values are a proposed v0 convention, not yet enforced by RTL:

| Code | Class | Intended resource family |
|---:|---|---|
| 0 | TENSOR | Dense or quantized tensor operations |
| 1 | VEC | Vector/SIMT operations |
| 2 | CAM | Associative lookup/search |
| 3 | EVENT | Sparse/event processing |
| 4 | MOVER | Data movement |
| 5 | RT | Ray traversal |
| 6 | CODEC | Video/image codec operations |
| 7 | CTRL | Control, synchronization, or reserved commands |

The current dispatcher treats `op` as opaque payload. It does not validate opcode legality, schedule execution, model memory dependencies, or guarantee completion. The tag is carried through the FIFO but there is no completion scoreboard yet.

## Flow control and known limits

- FIFO capacity is bounded and configurable; a full FIFO deasserts `in_ready` and backpressures the dispatcher.
- The current FIFO is synchronous, single-enqueue/single-dequeue, and uses asynchronous active-low reset for pointers and occupancy.
- This first version does not provide same-cycle full-FIFO replacement when a dequeue occurs. If full at the start of a cycle, `in_ready` remains low for that cycle.
- No multi-clock crossing, per-tile queues, dependency tokens, QoS, deadlines, cancellation, or completion tracking are implemented yet.
- This RTL is a control-plane prototype. It is not a complete accelerator and has not been measured on physical hardware.
