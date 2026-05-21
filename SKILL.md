---
name: x-commit
description: Use when committing code — writing commit messages, staging, or reviewing commits before push.
---

# Commit Messages

## Core Principle

Commit msg = for person reading `git log` 6 months later. Tell **why** change exists — diff shows *what*/*how*.

## Pre-Commit

1. **Stage selectively** — `git status` + `git diff` first. Never `git add -A` / `git add .`.
   - **Prior context:** only `git add` files from current task. Leave other unstaged/untracked changes alone.
   - **No prior context (e.g. bare `/commit`):** stage all, **unless** incomplete features (half-written code, TODO stubs, broken imports). Warn user, commit only complete stuff. If user insists, commit what they ask.
   - IT IS IMPERATIVE YOU NEVER COMMIT THINGS THAT ARE NOT MENTIONED IN THE CURRENT CONVERSATION
2. **Lint** — all linters pass. No `git commit --no-verify`.
3. **Docs** — update docs/architecture files in same commit. If doc changes too big, split to separate commit.
4. **NEVER commit AI plan files** (`docs/superpowers/` etc.) — those are ephemeral agent guidance, not project docs.
5. **Check atomicity** (see below).

## Atomic Commits

**Try to split into as many atomic commits as possible.** If there is a list of features (e.g. "Implemented X, Y, and Z types"), split each one into a separate commit.

**IT IS ABSOLUTELY IMPERATIVE THAT IF YOU EVER SAY "+" OR "and" OR ANYTHING SIMILAR IN A COMMIT MESSAGE (or your description of it would include that), SPLIT IT INTO MULTIPLE COMMITS.**

**Split by motivation, not subsystem.** Different *whys* = different commits. Same *why* = same commit. "Fix X, Fixed Y" = 2 commits. "Build X, needs A+B+C" = 1 commit if the code won't work without A+B+C; 3 commits if A, B, and C can exist independently. "Crash recovery + its error reporting" = 2 commits. "Fix typo + add feature" = 2 commits.

**Don't merge by code proximity.** Same function/file ≠ same commit if different problems. Interleaved changes → `git add -p` or commit one feature first, then other. Trap: "shared infrastructure / same loop" ≠ same why.

**Single commit needs VERY good reason.** ALWAYS prefer splitting the code hunks into as many commits as possible.

## Format

`:gitmoji: type(scope): imperative description`

GitHub shortcode + Conventional Commits. Prefer specific gitmojis (`:passport_control:` not `:sparkles:`, `:rocket:` not `:wrench:`).

### Gitmoji Ref

| Gitmoji | Use |
|---------|-----|
| :sparkles: | New feature |
| :bug: | Bug fix |
| :ambulance: | Critical hotfix |
| :recycle: | Refactor |
| :fire: | Remove code/files |
| :zap: | Perf |
| :memo: | Docs |
| :white_check_mark: | Tests |
| :arrow_up: / :arrow_down: | Dep upgrade/downgrade |
| :lock: | Security |
| :boom: | Breaking change |
| :pencil2: | Typo |
| :lipstick: | UI/style |
| :art: | Code style |
| :wrench: | Config |
| :construction_worker: | CI/build |
| :truck: | Move/rename |

Niche gitmojis: https://gitmoji.dev/

### Type vs Gitmoji

Independent but related. Gitmoji can be more specific than type: `:ambulance: fix(auth):` — general `fix` type, specific `:ambulance:` emoji.

## Subject Line

1. **≤50 chars** (hard: 72, excluding gitmoji shortcode)
2. **Imperative** — "add", "fix", "remove"; not "added", "fixes", "removed"
3. **lowercase after `:`** — `:bug: fix(auth): handle null user`
4. **No period**
5. **Say why** — diff shows what. "what" OK only if self-explanatory (`:pencil2: fix(docs): correct "recieve" → "receive"`)

```
# BAD: says what
:bug: fix(auth): add null check before accessing user.email
# GOOD: says why
:bug: fix(auth): prevent crash when user session expires

# BAD: wrong gitmoji + type
:sparkles: feat(deps): upgrade React to 19.0
# GOOD
:arrow_up: build(deps): upgrade React to 19.0
```

## Body

Only when subject alone doesn't explain **why**. Use for: bugs, non-obvious decisions, breaking changes, wide blast radius. Skip for obvious changes.

- Blank line after subject
- Explain motivation/context, not diff play-by-play

```
:bug: fix(orders): prevent duplicate submissions on double-click

Users creating duplicate orders clicking Submit before first request
completed. Debouncing insufficient — slow network extended vulnerable window.

Disable button on first click, re-enable on error. Chose this over
request deduplication for immediate visual feedback.
```

## Running Commit

**Never heredocs (`cat <<'EOF'`).** Bash quoting + heredocs = syntax errors + token waste. Use: `git commit -m "subject\n\nbody"`.
