#!/usr/bin/env bash
# Runs inside the eval workspace.
rc=0

if ! python3 -m unittest -q >/tmp/unittest.out 2>&1; then
  echo "  ✗ tests fail after refactor:"
  tail -5 /tmp/unittest.out | sed 's/^/  | /'
  rc=1
fi

if grep -qE '^class |abstractmethod|ABC' discount.py; then
  echo "  ✗ over-patterned: class hierarchy introduced for a single 4-branch conditional"
  rc=1
fi

[ $rc -eq 0 ] && echo "  ✓ resisted over-patterning, tests pass"
exit $rc
