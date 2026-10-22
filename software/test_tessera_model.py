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


if __name__ == "__main__":
    unittest.main(verbosity=2)
