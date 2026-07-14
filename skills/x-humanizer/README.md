# x-humanizer

[![X-humanizer Tokens](https://img.shields.io/endpoint?url=https%3A%2F%2Fgist.githubusercontent.com%2FThatXliner%2Fcffd977aeb3539c0571ee27356d3a0b3%2Fraw%2Fx-humanizer-tokens.json)](https://github.com/ThatXliner/xtras/blob/main/skills/x-humanizer/SKILL.md)

Part of the [**xtras**](../../README.md) plugin.

Rewrites AI-generated text so it reads like a considered essay instead of a marketing blog post. It targets rhythm, sentence mechanics, and the stock frames and vocabulary that mark text as machine-written.

## Rules

- **No rhetorical fragments** — every sentence stands grammatically complete on its own. "It's not a promise. It's a confession." becomes "It isn't a promise so much as a confession."
- **No staccato pairs/triples** — short sentences belonging together get joined with a semicolon, a comma-and-conjunction, or a subordinate clause.
- **No one-line punchline paragraphs** — each paragraph develops a thought across multiple sentences, including the closing paragraph.
- **No em-dashes as dramatic pauses** — where a comma, parenthesis, or "because" clause does the same work more quietly, use that.
- **No list-style sentences** — "There's X. There's Y. There's Z." becomes a real list or a single sentence with parallel clauses.
- **Sentences finish their own thought** — no sentence relies on the next to complete it.
- **No "not just X but Y" contrast frames** — re-punctuating "It's not just X. It's Y." into a semicolon version doesn't fix it; the frame itself is the tell. The sentence gets recast to state the stronger claim directly.
- **No stock AI vocabulary** — delve, tapestry, game-changer, seamless, leverage-as-a-verb, "In today's …", "It's important to note", "In conclusion", and similar throat-clearing get replaced with plainer language or deleted.

A mandatory final check re-counts sentences per paragraph before finishing, because the most common failure mode is a long, comma-joined sentence left standing as its own paragraph.

## The read-aloud test

Read any single sentence in isolation. It should stand up grammatically and feel complete on its own. If it only works because of what comes before or after, rewrite it.

## What it preserves

Keeps the argument, the structure, and the voice. Changes only the rhythm and sentence mechanics.

## Example

**Before:**
> AI assistants are changing everything. Not incrementally. Fundamentally. The way we write code, compose emails, and even think through problems — it's all shifting. It's not just about saving time. It's about reimagining what's possible.
>
> This is exciting. It's also terrifying.

**After:**
> AI assistants are changing everything, not incrementally but fundamentally. The way we write code, compose emails, and even think through problems is all shifting, and the point is less the time saved than the change in what is possible. This is exciting, and it is also terrifying.

## Usage

The skill activates when you ask Claude to humanize, edit, or review text for AI tells.
