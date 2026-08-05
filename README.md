# xtras

[![X-commit Tokens](https://img.shields.io/endpoint?url=https%3A%2F%2Fgist.githubusercontent.com%2FThatXliner%2Fcffd977aeb3539c0571ee27356d3a0b3%2Fraw%2Fx-commit-tokens.json)](skills/x-commit/README.md)
[![X-humanizer Tokens](https://img.shields.io/endpoint?url=https%3A%2F%2Fgist.githubusercontent.com%2FThatXliner%2Fcffd977aeb3539c0571ee27356d3a0b3%2Fraw%2Fx-humanizer-tokens.json)](skills/x-humanizer/README.md)

**xtras** bundles my Claude Code skills into one plugin. It currently ships:

- **[x-commit](skills/x-commit/README.md)** — commit the way I want, not the way Claude defaults to: gitmoji + conventional commits, atomic enforcement, why-not-what messaging.
- **[x-humanizer](skills/x-humanizer/README.md)** — strip the AI tells out of generated prose by fixing rhythm and sentence mechanics.
- **[x-tools](skills/x-tools/README.md)** — reach for `rg`, `fd`, `sd`, and `jq` instead of `grep`, `find`, and `sed`, with silent fallback when they aren't installed.

## Installation

```bash
claude plugin marketplace add ThatXliner/claude-plugins
claude plugin install xtras
```

## License

MIT
