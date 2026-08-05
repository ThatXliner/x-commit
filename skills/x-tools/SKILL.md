---
name: x-tools
description: |
  Use modern CLI tools (rg, fd, sd, jq, bat) instead of grep, find, sed, and
  cat when shelling out. Use this skill whenever a task involves searching
  file contents, locating files by name, bulk find-and-replace across files,
  reading or querying JSON/YAML, or inspecting file contents from Bash.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Edit
---

# x-tools: Prefer modern CLI tools

Old POSIX tools are slow, ignore `.gitignore`, and have hostile syntax that invites quoting bugs. When you shell out for search, file discovery, bulk replacement, or structured data, use the modern replacement — unless it isn't installed.

## Step 0 — Probe once per session

Before the first substitution, run exactly one probe and remember the result for the rest of the session:

```bash
for t in rg fd sd jq bat; do command -v "$t" >/dev/null 2>&1 && echo "$t"; done
```

Anything that prints is available. Anything missing falls back to the POSIX column below, **silently** — do not tell the user a tool is missing, do not offer to install it, and do not stop to ask. Just use the fallback.

Do not re-probe. One probe covers the whole session.

## Step 1 — Check whether you need Bash at all

The built-in tools beat every CLI here, because they return structured results without a shell round-trip:

| Task | Use this, not Bash |
|---|---|
| Search file contents by pattern | **Grep** tool (it already runs ripgrep) |
| Find files by name or glob | **Glob** tool |
| Read a file, whole or partial | **Read** tool |
| Change text in a file you have read | **Edit** tool |

Reach for Bash only when the built-in tools genuinely can't do it: piping results into another command, counting or aggregating matches, replacing across many files at once, or querying structured data.

## Step 2 — The substitution table

| Instead of | Use | Fallback if missing |
|---|---|---|
| `grep -r X .` | `rg X` | `grep -rn X .` |
| `grep -rl X .` | `rg -l X` | `grep -rl X .` |
| `grep -ri X .` | `rg -i X` | `grep -rni X .` |
| `grep -r X --include='*.py'` | `rg X -g '*.py'` or `rg X -tpy` | `grep -rn --include='*.py' X .` |
| `find . -name '*.ts'` | `fd -e ts` | `find . -name '*.ts'` |
| `find . -type d -name node_modules` | `fd -td node_modules` | `find . -type d -name node_modules` |
| `find . -name X -exec CMD {} \;` | `fd X -x CMD` | `find . -name X -exec CMD {} \;` |
| `sed -i 's/a/b/g' file` | `sd 'a' 'b' file` | `perl -pi -e 's/a/b/g' file` |
| `cat file` | **Read** tool; `bat -pp file` only when piping | `cat file` |
| `python -c 'import json...'` | `jq '.field' file.json` | `python3 -c '...'` |

## Step 3 — Idioms worth knowing

- **rg and fd respect `.gitignore` by default.** That is usually what you want. To search ignored or hidden files, add `-u` (or `-uu` to also include binary-adjacent noise). Never hand-write `--glob '!node_modules'` — it is already excluded.
- **rg searches the current directory by default.** `rg pattern` is complete; `rg pattern .` is redundant.
- **`rg -l` then act.** To operate on matching files, use `rg -l pattern | xargs -r CMD` rather than a shell loop over `ls`.
- **`rg --files` lists every non-ignored file** — a fast substitute for `find .` when you want to pipe into another filter.
- **Fixed strings:** `rg -F` when the pattern contains regex metacharacters. This avoids the classic `grep` escaping mess.
- **Context:** `rg -C3` beats reading the whole file when you only need the surrounding lines.
- **`sd` takes plain regex, not sed's dialect** — no escaping `+`, `?`, or `(` `)`, and replacement groups are `$1`, not `\1`. It also does not need `-i`; it edits in place when given a file.
- **`sd` across many files:** `rg -l 'old' | xargs -r sd 'old' 'new'`. Show the user the file list from `rg -l` before running a destructive bulk replace.
- **`jq` over ad-hoc parsing.** Never grep JSON for a field. `jq -r '.a.b'` for raw output, `jq -e` when you want a nonzero exit on null/false.
- **`bat` only when a pager-free, syntax-highlighted dump helps a human.** Inside a pipeline always use `bat -pp` (plain, no pager) or it will hang waiting on a pager.

## Rules

1. Probe once, then never mention the probe or missing tools again.
2. Built-in Grep/Glob/Read/Edit outrank every CLI in this skill. Only shell out when they can't do the job.
3. Never disable `.gitignore` filtering unless the user is specifically looking for ignored files.
4. Before any bulk in-place replacement, list the affected files first and confirm with the user if more than a handful are touched.
5. If the user explicitly asks for `grep`, `find`, or `sed` — for example because they want a command to paste into a script that runs elsewhere — give them what they asked for. This skill governs your own tool use, not theirs.
