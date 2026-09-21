#!/usr/bin/env bash
# Plants a small command-line tool whose check script runs a lint and the tests.
set -euo pipefail
mkdir -p app tests
cat >app/__init__.py <<'PY'
PY
cat >app/cli.py <<'PY'
import argparse

BANNER = "report v1.2"


def build_parser():
    parser = argparse.ArgumentParser(prog="report")
    parser.add_argument("path")
    return parser


def main(argv=None):
    args = build_parser().parse_args(argv)
    print(BANNER)
    with open(args.path) as handle:
        print(sum(1 for _ in handle), "lines")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
cat >tests/__init__.py <<'PY'
PY
cat >tests/test_cli.py <<'PY'
import contextlib
import io
import tempfile
import unittest

from app.cli import main


class MainTest(unittest.TestCase):
    def run_main(self, *args):
        with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as handle:
            handle.write("a\nb\n")
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            main([*args, handle.name])
        return out.getvalue()

    def test_prints_banner_and_count(self):
        self.assertEqual(self.run_main(), "report v1.2\n2 lines\n")


if __name__ == "__main__":
    unittest.main()
PY
cat >check.sh <<'SH'
#!/usr/bin/env bash
# Byte-compiles every module (the lint) and runs the tests.
set -euo pipefail
python3 -m compileall -q app tests
python3 -m unittest -q
SH
chmod +x check.sh
printf '# report\n\nCounts lines in a file.\n\n## Checks\n\n`./check.sh` runs the lint and the tests.\n' >README.md
git init -q && git add -A && git -c user.name=eval -c user.email=eval@localhost commit -q -m "feat: line counter"
