#!/usr/bin/env bash
# Plants a small Python package with a reported bug that its tests do not cover.
set -euo pipefail
mkdir -p durations tests
cat >durations/__init__.py <<'PY'
from .parse import parse_duration
PY
cat >durations/parse.py <<'PY'
import re

UNITS = {"h": 3600, "m": 60, "s": 1}


def parse_duration(text):
    """Seconds in a duration such as "90s", "5m" or "1h30m"."""
    total = 0
    for amount, unit in re.findall(r"(\d+)([hms])", text):
        total = int(amount) * UNITS[unit]
    return total
PY
cat >tests/__init__.py <<'PY'
PY
cat >tests/test_parse.py <<'PY'
import unittest

from durations import parse_duration


class ParseDurationTest(unittest.TestCase):
    def test_seconds(self):
        self.assertEqual(parse_duration("90s"), 90)

    def test_minutes(self):
        self.assertEqual(parse_duration("5m"), 300)


if __name__ == "__main__":
    unittest.main()
PY
printf '# durations\n\nParses durations such as `1h30m` into seconds.\n\nTests: `python3 -m unittest`\n' >README.md
git init -q && git add -A && git -c user.name=eval -c user.email=eval@localhost commit -q -m "feat: parse durations"
