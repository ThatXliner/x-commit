# x-tools

Part of the [**xtras**](../../README.md) plugin.

Upgrades Claude's shell habits. Instead of reaching for `grep -r`, `find`, `sed -i`, and `cat`, it uses `rg`, `fd`, `sd`, `jq`, and `bat` — tools that are faster, respect `.gitignore`, and have syntax that doesn't invite quoting bugs.

## How it works

**One probe per session.** A single `command -v` loop checks which of `rg`, `fd`, `sd`, `jq`, and `bat` exist. Whatever is missing falls back to the POSIX equivalent silently, so there's no nagging about installing things and no hard failure on a bare machine.

**Built-in tools come first.** Before any of this matters, the skill checks whether Bash is needed at all. Claude Code's Grep tool already runs ripgrep, Glob already handles file discovery, and Read/Edit already handle file contents. Shelling out is reserved for what those can't do: pipelines, aggregation, bulk replacement, and structured queries.

## The substitutions

| Instead of | Use |
|---|---|
| `grep -r X .` | `rg X` |
| `grep -r X --include='*.py'` | `rg X -tpy` |
| `find . -name '*.ts'` | `fd -e ts` |
| `sed -i 's/a/b/g' file` | `sd 'a' 'b' file` |
| `cat file` | Read tool, or `bat -pp` when piping |
| `python -c 'import json...'` | `jq '.field'` |

## Idioms it enforces

- `rg` and `fd` respect `.gitignore` by default, so hand-written `--glob '!node_modules'` exclusions are dead weight.
- `rg -F` for patterns containing regex metacharacters, which sidesteps the usual `grep` escaping mess.
- `rg -l pattern | xargs -r CMD` instead of shell loops over `ls`.
- `sd` uses plain regex with `$1` replacements rather than sed's dialect, and edits in place without `-i`.
- `jq` for anything JSON — never grep a JSON file for a field.
- `bat -pp` inside pipelines, because plain `bat` waits on a pager and hangs.

## Safety

Bulk in-place replacement lists the affected files before it touches them, and asks first when more than a handful are involved. If you explicitly ask for `grep`, `find`, or `sed` — say, because you want a command to paste into a script that runs somewhere else — you get what you asked for. The skill governs Claude's own tool use, not yours.

## Usage

The skill activates when a task involves searching file contents, locating files by name, bulk find-and-replace, querying JSON or YAML, or inspecting files from the shell.
