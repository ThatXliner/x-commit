import unittest

from discount import price_with_discount


class TestDiscount(unittest.TestCase):
    def test_rates(self):
        self.assertEqual(price_with_discount(100, "regular"), 100)
        self.assertEqual(price_with_discount(100, "member"), 90.0)
        self.assertEqual(price_with_discount(100, "vip"), 80.0)
        self.assertEqual(price_with_discount(100, "employee"), 70.0)

    def test_unknown_type_raises(self):
        with self.assertRaises(ValueError):
            price_with_discount(100, "alien")
