# x-commit

[![Tokens](https://img.shields.io/endpoint?url=https%3A%2F%2Fgist.githubusercontent.com%2FThatXliner%2Fcffd977aeb3539c0571ee27356d3a0b3%2Fraw%2Fx-commit-tokens.json)](https://github.com/ThatXliner/x-commit/blob/main/SKILL.md)

I created this because I didn't like how Claude committed files when I simply asked it to "create atomic commits." This skill codifies all the things I want.

## Features

- **Gitmoji + Conventional Commits** — combines [visual emoji shortcodes](https://gitmoji.dev/) (`:bug:`, `:sparkles:`) with [machine-parseable types](https://www.conventionalcommits.org/en/v1.0.0/) (`fix`, `feat`) in one format
- **Atomic commit enforcement** — splits changes by code dependency, not just "logical grouping," so `git revert` and `git bisect` always work cleanly
- **Why-not-what messaging** — teaches the agent to explain motivation in subjects and bodies instead of restating the diff
- **Pre-commit checklist** — lints, documentation updates, and AI plan file cleanup (never commit [Superpowers](https://github.com/obra/superpowers) docs) before every commit
- **Full gitmoji reference** — 30+ commonly used gitmoji with type pairings, plus a link to the complete spec

## Installation

Clone into your Claude Code skills directory:

```bash
git clone https://github.com/ThatXliner/x-commit.git ~/.claude/skills/x-commit
```

The skill is automatically discovered by Claude Code on next conversation start.

## Usage

The skill activates automatically when Claude is writing commit messages, staging changes, or reviewing commits. You can also trigger it explicitly with:

```
/x-commit
```

## License

MIT
