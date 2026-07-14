# x-commit

[![X-commit Tokens](https://img.shields.io/endpoint?url=https%3A%2F%2Fgist.githubusercontent.com%2FThatXliner%2Fcffd977aeb3539c0571ee27356d3a0b3%2Fraw%2Fx-commit-tokens.json)](https://github.com/ThatXliner/xtras/blob/main/skills/x-commit/SKILL.md)

Part of the [**xtras**](../../README.md) plugin.

I created this because I didn't like how Claude committed files when I simply asked it to "create atomic commits." This skill codifies all the things I want.

The only downside is that it does spend significantly extra tokens trying to separate code into clean atomic commits (even shelling out to [gah](https://github.com/ThatXliner/gah) if necessary) but in the long term that's typically better, is it not? It always takes more effort to do things the clean way. 

## Features

- **Gitmoji + Conventional Commits** — combines [visual emoji shortcodes](https://gitmoji.dev/) (`:bug:`, `:sparkles:`) with [machine-parseable types](https://www.conventionalcommits.org/en/v1.0.0/) (`fix`, `feat`) in one format
- **Atomic commit enforcement** — splits changes by code dependency, not just "logical grouping," so `git revert` and `git bisect` always work cleanly
- **Why-not-what messaging** — teaches the agent to explain motivation in subjects and bodies instead of restating the diff
- **Pre-commit checklist** — lints, documentation updates, and AI plan file cleanup (never commit [Superpowers](https://github.com/obra/superpowers) docs) before every commit
- **Full gitmoji reference** — 30+ commonly used gitmoji with type pairings, plus a link to the complete spec

## Pairs well with [gah](https://github.com/ThatXliner/gah)

x-commit enforces **atomic commits** split by code dependency — which often means staging only _part_ of a file. But `git add -p` is interactive, and agents can't drive interactive prompts.

[**gah**](https://github.com/ThatXliner/gah) (_Git Add Hunk, built for agents to use_) solves exactly this: non-interactive hunk-based staging. Stage specific hunks by index, content anchor, regex, or line range — no prompts required. Together they let an agent slice a messy working tree into clean, revertable commits.

### Installing gah

**CLI via Cargo:**

```bash
cargo install gah
```

**Claude Code Plugin:**

```bash
/plugin install ThatXliner/gah
```

Or manually:

```bash
mkdir -p .claude/skills
git clone https://github.com/ThatXliner/gah.git .claude/skills/gah
```

### Hook guard (recommended)

The skill includes a `PreToolUse` hook that validates commit messages follow the x-commit format before allowing them through. This prevents Claude from bypassing the skill when confirming a commit with a short reply like "yes".

To enable it globally, add this to your `~/.claude/settings.json`:

```jsonc
{
  // ...existing settings...
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "prompt",
            "if": "Bash(git commit:*)",
            "prompt": "If the command is NOT a `git commit`, allow it — this check only applies to commits. If it IS a git commit, extract its -m message and check it follows the x-commit skill conventions: the message MUST use the format `:gitmoji: type(scope): imperative description` (e.g. `:bug: fix(auth): prevent crash when session expires`). If the message does NOT match this format, block it and tell the model to invoke the x-commit skill first with /x-commit. If it DOES match, allow it. Command: $ARGUMENTS",
            "statusMessage": "Validating commit format..."
          }
        ]
      }
    ]
  }
}
```

## Usage

The skill activates automatically when Claude is writing commit messages, staging changes, or reviewing commits. You can also trigger it explicitly with:

```
/x-commit
```
