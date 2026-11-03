#!/usr/bin/env bash
# Runs the trace shapes an eval run produces against verify-before-done's regex
# graders, read from the case file, so a pattern change can't silently fail
# correct runs. Python's re and the eval's engine agree on what these use.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
exec python3 -I - "$here/../plugins/bard/evals/verify-before-done/case.yaml" <<'PY'
import json, re, sys
text = open(sys.argv[1]).read()
def pattern(name):
    m = re.search(r"  - name: " + name + r"\n    type: regex\n    target: trace\n    pattern: '(.*)'\n", text)
    if not m: sys.exit("no regex grader named " + name)
    return re.compile(m.group(1))
after, script = pattern("tests-after-last-edit"), pattern("used-check-script")
edit = '{"name":"Edit","input":{"file_path":"/w/app/cli.py","old_string":"a"}}'
def bash(c): return '{"name":"Bash","input":{"command":' + json.dumps(c) + '}}'
heredoc = "python3 - <<'EOF'\np='app/cli.py'; s=open(p).read()\nopen(p,'w').write(s)\nEOF"
cases = [  # description, trace, tests after the last edit, used check.sh
    ("Edit, then check.sh", edit + bash("./check.sh"), True, True),
    ("Edit, then the tests directly", edit + bash("python3 -m unittest -q"), True, False),
    ("check.sh, then Edit", bash("./check.sh") + edit, False, True),
    ("a heredoc edit, then check.sh", bash(heredoc) + bash("./check.sh"), True, True),
    ("a heredoc edit and check.sh in one command", bash(heredoc + "\n./check.sh"), True, True),
    ("an edit from inside app/", bash("cd app && python3 -c \"open('cli.py','w').write('x')\" && cd .. && ./check.sh"), True, True),
    ("a Bash write after check.sh", edit + bash("./check.sh") + bash("python3 -c \"open('app/cli.py','w').write('x')\""), False, True),
    ("sed -i after check.sh", edit + bash("./check.sh") + bash("sed -i s/a/b/ app/cli.py"), False, True),
    ("a read after check.sh", edit + bash("./check.sh") + bash("cat app/cli.py 2>/dev/null"), True, True),
    ("no tests", edit + bash("cat app/cli.py"), False, False),
    ("a heredoc edit and no tests", bash(heredoc), False, False),
    ("check.sh only in tool output", edit + '{"type":"tool_result","content":"`./check.sh` runs the lint"}', False, False),
    ("an escaped quote before check.sh", edit + bash('echo "go" && ./check.sh'), True, True),
]
fail = 0
for what, trace, want_after, want_script in cases:
    got = (bool(after.search(trace)), bool(script.search(trace)))
    ok = got == (want_after, want_script)
    fail |= not ok
    print(("✓ " if ok else "✗ ") + what + ("" if ok else f": got {got}"))
sys.exit(fail)
PY
