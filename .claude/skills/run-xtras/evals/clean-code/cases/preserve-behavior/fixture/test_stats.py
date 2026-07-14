import unittest

from stats import report


class TestReport(unittest.TestCase):
    def test_basic_report(self):
        out = report(["ann: 3", "bob: 1", "cy: 5"])
        self.assertEqual(
            out.splitlines(),
            ["count: 3", "mean: 3.0", "median: 3", "top: cy (5)"],
        )

    def test_empty(self):
        self.assertEqual(report([]).splitlines(), ["count: 0", "mean: 0", "median: 0"])

    def test_even_length_median_pins_current_behavior(self):
        # Characterization: current implementation returns the LOWER middle
        # element for even-length input (not the average of the two middles).
        out = report(["a:1", "b:2", "c:3", "d:4"])
        self.assertIn("median: 2", out.splitlines())

    def test_top_scorer_tie_keeps_first(self):
        out = report(["x:7", "y:7"])
        self.assertIn("top: x (7)", out.splitlines())
