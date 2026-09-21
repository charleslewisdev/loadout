#!/usr/bin/env bash
# Plants a small Python service in the eval workspace (the current directory).
set -euo pipefail
mkdir -p src
cat >src/greet.py <<'PY'
def greet(name):
    return f"Hello, {name}"
PY
cat >src/main.py <<'PY'
import argparse
import logging

from greet import greet


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("name")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO)
    print(greet(args.name))


if __name__ == "__main__":
    main()
PY
cat >src/client.py <<'PY'
import urllib.request


def fetch(url):
    with urllib.request.urlopen(url, timeout=10) as response:
        return response.read()


def get_status(url):
    body = fetch(url)
    return body.decode()
PY
cat >src/dates.py <<'PY'
from datetime import date


def parse_date(text):
    if not text:
        return None
    return date.fromisoformat(text)
PY
printf 'service: greeter\ntimeout: 30\nretries: 2\n' >config.yaml
printf '# Greeter\n\nA tiny service that greets people. It will recieve a name and print a greeting.\n' >README.md
