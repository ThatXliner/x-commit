# clean-code-refactoring

WIP!!!!

Part of the [**xtras**](../../README.md) plugin.

Turns a refactoring request into a safe, disciplined process. Refactoring means changing the *structure* of code without changing its *behavior*, and most refactoring failures come from violating that definition — so the skill enforces a workflow that makes behavior preservation checkable instead of hoped-for.

## The workflow

1. **Understand before touching** — read the code and its callers, name the smells explicitly (Long Method, Feature Envy, …) before changing anything.
2. **Establish a safety net** — run existing tests first; if none exist, write characterization tests that pin current behavior (including current bugs — fixing them is a separate change).
3. **Refactor in small, verified steps** — one named transformation at a time, tests between each.
4. **Review the result** — full suite, diff-check for accidental behavior changes, confirm the smell is actually gone.

Plus a smell → remedy quick-reference table, an anti-over-patterning section (function > module > class > pattern > framework), and on-demand reference files for smells, refactoring mechanics, design patterns, and clean-code principles.

## Safe by default: a red test suite stops the refactor

If the test suite is **already failing** before the refactor starts, the skill stops entirely and reports — it will not refactor, will not edit the failing test, and will not proceed with "the parts the tests do cover." A red suite means the safety net is broken, so any refactor on top of it is unverified by definition.

This wording is deliberately strict. In eval runs, a politer version of the rule lost to model reasoning like "this failure is a pre-existing product question, I'll just preserve current behavior" — which sounds sensible but means the refactor is unverified exactly where the code and the tests disagree.

**Want a more proactive skill?** If you'd rather the agent refactor anyway (preserving current behavior and flagging the failure), delete or soften the phase 2 item 1 passage in [`SKILL.md`](SKILL.md) — the one beginning "If any test fails before you start, **stop — do not refactor at all**." If you use this repo's eval suite, also remove the matching regression case at `.claude/skills/run-xtras/evals/clean-code/cases/stops-on-red-suite/`, which enforces the strict behavior.

## Evals

The skill's discipline rules are regression-tested by the repo's eval harness (`.claude/skills/run-xtras/`): behavior preservation (a deliberately pinned bug must survive the refactor), resisting over-patterning bait, writing characterization tests when none exist, and stopping on a red suite.

## Usage

The skill activates when you ask Claude to refactor, clean up, simplify, restructure, or modernize code, or when you ask which design pattern to apply.
