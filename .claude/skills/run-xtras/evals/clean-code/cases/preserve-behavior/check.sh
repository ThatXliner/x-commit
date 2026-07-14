#!/usr/bin/env bash
# Runs inside the eval workspace; $0 lives in the case directory.
case_dir="$(cd "$(dirname "$0")" && pwd)"
rc=0

if ! python3 -m unittest -q >/tmp/unittest.out 2>&1; then
  echo "  ✗ tests fail after refactor (behavior not preserved):"
  tail -5 /tmp/unittest.out | sed 's/^/  | /'
  rc=1
fi

if ! cmp -s test_stats.py "$case_dir/fixture/test_stats.py"; then
  echo "  ✗ test_stats.py was modified — characterization tests must stay untouched"
  rc=1
fi

ndefs=$(grep -c 'def ' stats.py)
if [ "$ndefs" -lt 3 ]; then
  echo "  ✗ stats.py was not restructured (only $ndefs function defs; expected the long method split up)"
  rc=1
fi

[ $rc -eq 0 ] && echo "  ✓ behavior preserved (incl. pinned bug), structure improved"
exit $rc
