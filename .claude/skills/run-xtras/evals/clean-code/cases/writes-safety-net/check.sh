#!/usr/bin/env bash
# Runs inside the eval workspace.
case_dir="$(cd "$(dirname "$0")" && pwd)"
rc=0

if ! ls test*.py >/dev/null 2>&1; then
  echo "  ✗ no characterization tests were written before refactoring"
  rc=1
elif ! python3 -m unittest -q >/tmp/unittest.out 2>&1; then
  echo "  ✗ tests fail after refactor:"
  tail -5 /tmp/unittest.out | sed 's/^/  | /'
  rc=1
fi

if cmp -s size_fmt.py "$case_dir/fixture/size_fmt.py"; then
  echo "  ✗ size_fmt.py unchanged — no refactoring happened"
  rc=1
fi

[ $rc -eq 0 ] && echo "  ✓ safety net written, duplication refactored, tests pass"
exit $rc
