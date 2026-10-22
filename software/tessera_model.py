"""Bit-accurate software reference model for Tessera prototype v0.

Completion results are returned as unsigned 32-bit bit patterns to match RTL
ports, while input operands are interpreted as signed 16-bit values.
"""
from dataclasses import dataclass

MASK16 = 0xFFFF
MASK32 = 0xFFFFFFFF


def signed(value: int, width: int) -> int:
    """Interpret the low *width* bits of value as a two's-complement integer."""
    value &= (1 << width) - 1
    sign_bit = 1 << (width - 1)
    return value - (1 << width) if value & sign_bit else value


@dataclass(frozen=True)
class Command:
    client: int
    unit: str
    op: int
    tag: int
    a: int
    b: int
    accumulator: int = 0


@dataclass(frozen=True)
class Completion:
    client: int
    tag: int
    status: int
    result: int


def execute(command: Command) -> Completion:
    """Execute one command according to the currently implemented RTL contract.

    unit is "vec" or "tensor". Status 0 means success; status 1 means the
    opcode or unit is unsupported. result is always a 32-bit bit pattern.
    """
    a = signed(command.a, 16)
    b = signed(command.b, 16)

    if command.unit == "vec":
        if command.op == 0:       # signed add, wrap to 16 bits
            value = signed(a + b, 16)
        elif command.op == 1:     # signed multiply, low 16 bits
            value = signed(a * b, 16)
        elif command.op == 2:     # signed minimum
            value = min(a, b)
        elif command.op == 3:     # signed maximum
            value = max(a, b)
        elif command.op == 4:     # bitwise XOR
            value = ((command.a & MASK16) ^ (command.b & MASK16))
            value = signed(value, 16)
        else:
            return Completion(command.client, command.tag, 1, 0)
        return Completion(command.client, command.tag, 0, value & MASK32)

    if command.unit == "tensor":
        product = a * b
        if command.op == 0:
            value = product
        elif command.op == 1:
            value = signed(command.accumulator, 32) + product
        else:
            return Completion(command.client, command.tag, 1, 0)
        return Completion(command.client, command.tag, 0, value & MASK32)

    return Completion(command.client, command.tag, 1, 0)
