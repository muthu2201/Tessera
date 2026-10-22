import random
import unittest

from tessera_model import Command, Completion, execute


class TesseraModelTests(unittest.TestCase):
    def run_cmd(self, unit, op, a, b, acc=0, client=2, tag=0xA5):
        return execute(Command(client, unit, op, tag, a, b, acc))

    def test_vector_signed_add_wraps_and_sign_extends(self):
        self.assertEqual(self.run_cmd("vec", 0, 32767, 1),
                         Completion(2, 0xA5, 0, 0xFFFF8000))

    def test_vector_multiply_returns_low_16_bits(self):
        self.assertEqual(self.run_cmd("vec", 1, -32768, -32768).result, 0)

    def test_vector_signed_min_max(self):
        self.assertEqual(self.run_cmd("vec", 2, 0x8000, 0x7FFF).result, 0xFFFF8000)
        self.assertEqual(self.run_cmd("vec", 3, 0x8000, 0x7FFF).result, 0x00007FFF)

    def test_vector_xor_is_bitwise(self):
        self.assertEqual(self.run_cmd("vec", 4, 0xAAAA, 0x0FF0).result, 0xFFFFA55A)

    def test_tensor_signed_product_boundaries(self):
        self.assertEqual(self.run_cmd("tensor", 0, -32768, -32768).result,
                         0x40000000)
        self.assertEqual(self.run_cmd("tensor", 0, -32768, 32767).result,
                         0xC0008000)

    def test_tensor_mac_wraps_to_32_bits(self):
        self.assertEqual(self.run_cmd("tensor", 1, 32767, 32767, 0x7FFFFFFF).result,
                         0xBFFF0000)

    def test_invalid_opcodes_return_error_and_zero(self):
        for unit, op in (("vec", 7), ("tensor", 2), ("other", 0)):
            with self.subTest(unit=unit, op=op):
                self.assertEqual(self.run_cmd(unit, op, 3, 4),
                                 Completion(2, 0xA5, 1, 0))

    def test_client_and_tag_are_preserved(self):
        result = self.run_cmd("tensor", 0, 7, 9, client=3, tag=0x42)
        self.assertEqual(result, Completion(3, 0x42, 0, 63))

    def test_deterministic_randomized_arithmetic_properties(self):
        rng = random.Random(0x7E55E2A)
        for _ in range(1000):
            a = rng.randrange(-32768, 32768)
            b = rng.randrange(-32768, 32768)
            acc = rng.randrange(-(1 << 31), 1 << 31)
            client = rng.randrange(4)
            tag = rng.randrange(256)

            add = execute(Command(client, "vec", 0, tag, a, b))
            add_low = (a + b) & 0xFFFF
            expected_add = add_low | (0xFFFF0000 if add_low & 0x8000 else 0)
            self.assertEqual(add.result, expected_add)

            mul_low = execute(Command(client, "vec", 1, tag, a, b))
            low = (a * b) & 0xFFFF
            expected_low = low | (0xFFFF0000 if low & 0x8000 else 0)
            self.assertEqual(mul_low.result, expected_low)

            vmin = execute(Command(client, "vec", 2, tag, a, b))
            vmax = execute(Command(client, "vec", 3, tag, a, b))
            self.assertEqual(vmin.result, min(a, b) & 0xFFFFFFFF)
            self.assertEqual(vmax.result, max(a, b) & 0xFFFFFFFF)

            vxor = execute(Command(client, "vec", 4, tag, a, b))
            xor16 = (a & 0xFFFF) ^ (b & 0xFFFF)
            self.assertEqual(vxor.result, xor16 | (0xFFFF0000 if xor16 & 0x8000 else 0))

            product = execute(Command(client, "tensor", 0, tag, a, b))
            self.assertEqual(product.result, (a * b) & 0xFFFFFFFF)
            mac = execute(Command(client, "tensor", 1, tag, a, b, acc))
            self.assertEqual(mac.result, (acc + a * b) & 0xFFFFFFFF)
            for result in (add, mul_low, vmin, vmax, vxor, product, mac):
                self.assertEqual((result.client, result.tag, result.status), (client, tag, 0))


if __name__ == "__main__":
    unittest.main(verbosity=2)
