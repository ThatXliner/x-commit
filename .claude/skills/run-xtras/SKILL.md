---
name: run-xtras
description: |
  Run, test, and eval the xtras plugin skills (x-humanizer,
  clean-code-refactoring). Use when asked to run a skill, test or verify a
  skill change, add an eval case, or red-green build a skill. The driver
  launches each skill headlessly via claude -p in a throwaway workspace and
  grades the output with deterministic checks.
---

# Run / eval the xtras skills

This repo is a Claude Code plugin — there is no server or GUI to launch.
"Running" it means invoking a skill headlessly against a fixture and grading
what it produced. The driver at `.claude/skills/run-xtras/driver.sh` does
that end-to-end. All paths below are relative to the repo root.

## Prerequisites

Already on PATH on this machine (no install was needed): `claude` (2.1.197),
`node` (v22), `python3` (3.14).

## Run the evals (agent path — start here)

```bash
./.claude/skills/run-xtras/driver.sh                              # all cases
./.claude/skills/run-xtras/driver.sh x-humanizer                  # one skill
./.claude/skills/run-xtras/driver.sh clean-code stops-on-red-suite  # one case
```

Exit code = number of failed cases. Failing workspaces are kept and their
paths printed (inspect `claude-output.txt` and the modified files there);
passing workspaces are deleted unless `KEEP_WS=1`. `MODEL=haiku` iterates
faster but grades a different model than users actually run; results were
verified with the default (`sonnet`).

Per case, the driver: `mktemp` a workspace → symlink `skills/<name>` into
`ws/.claude/skills/` → `claude -p "<prompt>" --allowedTools ... --settings
'{"disableAllHooks": true}'` → grade:

- **x-humanizer** cases (`evals/x-humanizer/cases/*/input.md`): the skill
  rewrites `input.md` in place, then `evals/x-humanizer/check.mjs` applies
  deterministic checks — one per rule in the skill (fragments, staccato,
  em-dashes, one-sentence paragraphs, list-style runs, "not just" contrast
  frames, banned vocabulary).
- **clean-code** cases (`evals/clean-code/cases/*/`): `fixture/` is copied
  into the workspace, `prompt.txt` drives a full agentic refactor (Bash is
  allowed so it can run the tests), then the case's `check.sh` runs
  `unittest`, diffs files against the pristine fixture, and greps for
  structural expectations. Each case takes 2–5 minutes.

## Red-green a skill change

1. Add a case capturing the desired behavior: for x-humanizer, an `input.md`
   exhibiting the tell plus (if new) a check in `check.mjs`; for clean-code,
   `fixture/` + `prompt.txt` + `check.sh`.
2. **Baseline before spending model calls**: run the fixture's tests directly
   and run `check.mjs` on the raw input — the checker must flag it, or a
   later pass is meaningless. (This caught a wrong expected value in a
   fixture test before any model run.)
3. Run the case → confirm red.
4. Edit `skills/<name>/SKILL.md` → re-run → green.
5. Keep the case. It is now a regression eval.

## Run one skill ad hoc (no grading)

```bash
ws=$(mktemp -d) && mkdir -p "$ws/.claude/skills"
ln -s "$PWD/skills/x-humanizer" "$ws/.claude/skills/x-humanizer"
cp your-draft.md "$ws/input.md"
(cd "$ws" && claude -p "Use the x-humanizer skill to rewrite input.md in place. Do not ask questions; just rewrite the file." --model sonnet --allowedTools "Skill,Read,Write,Edit" --settings '{"disableAllHooks": true}')
cat "$ws/input.md"
```

## Human path

Install the plugin (`claude plugin marketplace add ThatXliner/claude-plugins`
then `claude plugin install xtras`) and use the skills interactively. Not
needed for eval work — the symlink trick loads the working-tree skill
directly, so you're always testing your local edits.

## Gotchas

- **Skills rationalize around weak rules.** "Stop if the suite is red" lost
  to "this failure looks like an unresolved product decision, I'll preserve
  behavior and proceed." Rules only held once the wording named and forbade
  that exact rationalization. When a case fails, read the agent's final
  report in `claude-output.txt` — the excuse it gives is the sentence your
  rule needs to preempt.
- **Re-punctuation masquerades as fixing.** x-humanizer turned "It's not
  just X. It's Y." into "It isn't just X; it's Y." and considered rule 2
  satisfied. Checks must target the frame/content, not just punctuation.
- **The skill's own examples are part of the prompt.** x-humanizer's
  Before/After example contained "not just about" — banned by the very rule
  being added. Grep the skill's examples when adding a ban.
- **`assertIn` substring traps:** `"median: 2"` also matches `"median: 2.5"`.
  Fixture tests assert against `splitlines()`, not the raw string.
- **Checks are heuristics:** "fragment" = sentence ≤ 3 words, "staccato" =
  two consecutive sentences ≤ 6 words. A legitimately terse sentence can
  trip them; prefer adjusting the fixture over loosening thresholds.
- clean-code checks `cmp` files against the pristine fixture to catch the
  agent quietly editing characterization tests.
- Nested `claude -p` inside a Claude Code session works fine on macOS.
- **One green run proves little.** Model output is nondeterministic; the
  rhythm case passed once, then failed the next run on the same rule. When
  a rule flakes, add a self-verification step to the skill ("before
  finishing, count sentences per paragraph") rather than re-rolling until
  green.
- **Checker fixes don't need model calls.** Failing workspaces are kept —
  after adjusting a check, re-grade the kept workspace directly
  (`cd <ws> && bash <case>/check.sh`, or `node check.mjs <ws>/input.md`)
  before re-running the model. Also: grep-based "did it report X" checks
  are brittle — agents say "mismatch" or "discrepancy" where you expected
  "failure." Inspect the transcript before blaming the skill.
- **Cost:** every case is a real model call and clean-code cases are
  multi-minute agentic sessions. Iterate on single cases, run the full
  suite only as a final gate.

## Troubleshooting

- Driver exits N > 0 with `FAIL` lines → N red cases, not an infra error.
  A `claude -p` crash is reported separately with the tail of its output.
- `stops-on-red-suite` fails on the grep check → the agent stopped but its
  report didn't mention the failure; read `claude-output.txt` before
  assuming the skill regressed.
- `claude-output.txt` says "You've hit your session limit · resets 12am" →
  plan usage limit, not a red case. Every eval is a real model call; wait
  for the reset and re-run just the affected cases.
- Arbitrary Bash commands in this repo get blocked by the commit-format
  hook → the prompt hook in `.claude/settings.json` regressed. Its prompt
  must explicitly say non-commit commands are allowed; "reject unless the
  message matches" alone makes the evaluator reject any Bash command.
