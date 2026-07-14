---
name: clean-code-refactoring
description: Refactor code safely using clean code principles and design patterns. Use this skill whenever the user asks to refactor, clean up, simplify, restructure, modernize, or "improve" existing code; whenever they complain code is messy, hard to read, hard to test, duplicated, or "spaghetti"; whenever they ask which design pattern to apply; and during code review when suggesting structural improvements. Also use after writing new code
---

# Clean Code Refactoring

This skill turns a refactoring request into a safe, disciplined process. Refactoring means changing the *structure* of code without changing its *behavior*. Most refactoring failures come from violating that definition — sneaking in behavior changes, taking steps too big to verify, or applying a pattern the code didn't need.

## The core workflow

Follow these phases in order. Do not skip phase 1 or 2 even under time pressure — they are what make the rest safe.

### Phase 1 — Understand before touching

1. Read the code you were asked to refactor AND its callers. A function's ugliness often lives in how it's used, not how it's written.
2. State (to yourself or the user) what the code currently does, including edge cases and error behavior. If you can't state it, you can't preserve it.
3. Identify the smells present. Use the table below. Name them explicitly — "this has a Long Method and Feature Envy" — because the smell determines the remedy. Don't refactor on vague aesthetic discomfort.

### Phase 2 — Establish a safety net

1. Check whether tests exist and run them to confirm they pass *before* changing anything. If any test fails before you start, **stop — do not refactor at all**. Report the failure and end the turn. This holds even when the failure looks pre-existing, unrelated to your target, or like an open product question you could "work around" by preserving current behavior: a red suite means the safety net is broken, so any refactor on top of it is unverified by definition. Do not edit the failing test to make it pass, and do not proceed with a partial refactor of "the parts the tests do cover." Resume only after the user resolves the failure.
2. If no tests exist, write characterization tests first: tests that pin down current behavior (including current bugs — preserve them unless told otherwise; fixing bugs is a separate change). Cover the happy path, edge cases, and error paths of the code you'll touch.
3. If tests are impossible (no runtime available, user declines), say so explicitly, lower your ambition, and prefer the smallest mechanical transformations from `references/refactoring-catalog.md` — the ones safe enough to do by inspection.

### Phase 3 — Refactor in small, verified steps

1. One transformation at a time. Extract a method, run tests. Rename, run tests. Never batch five structural changes into one untested leap.
2. Each step should leave the code compiling and passing. If a step breaks things, revert it rather than patching forward.
3. Never mix refactoring with behavior changes or bug fixes in the same step. If you discover a bug mid-refactor, note it, finish the structural step, then raise it with the user.
4. Prefer the boring, named transformation from the catalog over an improvised rewrite. Rewrites lose behavior; catalog moves preserve it.

### Phase 4 — Review the result

1. Re-run the full test suite.
2. Diff-check yourself: is every change structural? Any behavior difference is a defect unless the user asked for it.
3. Confirm the original smell is actually gone and you haven't introduced a new one (e.g., extracting so aggressively that you created Shotgun Surgery, or adding a pattern where a function would do).
4. Summarize for the user: smells found → transformations applied → what improved, in plain language.

## Smell → remedy quick reference

Diagnose first, then apply. Full detection heuristics and worked remedies are in `references/code-smells.md`; step-by-step mechanics for each transformation are in `references/refactoring-catalog.md`.

| Smell | Telltale sign | Primary remedy |
|---|---|---|
| Long Method | Doesn't fit on a screen; comments marking "sections" | Extract Method per section; each comment is a candidate name |
| Large Class | Many unrelated fields/methods; "Manager"/"Util" name | Extract Class along responsibility seams |
| Duplicated Code | Same logic in 2+ places (even if not textually identical) | Extract Method/Function, then Pull Up if across siblings |
| Long Parameter List | 4+ params, or booleans steering behavior | Introduce Parameter Object; Replace Flag Argument with separate functions |
| Feature Envy | Method mostly reads another object's data | Move Method to the data it envies |
| Data Clumps | Same group of variables travels together | Extract Class/value object for the clump |
| Primitive Obsession | Strings/ints for domain concepts (money, IDs, emails) | Replace Primitive with value object |
| Switch/if-chain on type | Same conditional repeated in multiple places | Replace Conditional with Polymorphism (Strategy/State) — only if repeated |
| Shotgun Surgery | One change forces edits in many files | Move/Inline until the concept lives in one place |
| Divergent Change | One class changes for many unrelated reasons | Extract Class per reason-to-change (SRP) |
| Message Chains | `a.getB().getC().getD()` | Hide Delegate, or move behavior to the end of the chain |
| Speculative Generality | Unused hooks, params, abstract layers "for later" | Inline/delete; Collapse Hierarchy |
| Comments explaining *what* | Comment restates the code | Extract Method or Rename so the code says it; keep only *why* comments |
| Dead Code | Unreachable or unused members | Delete (version control remembers) |
| Mutable global/shared state | Hidden inputs, order-dependent behavior | Encapsulate; pass dependencies explicitly |
| Nested conditionals | Arrow-shaped code, deep indentation | Guard clauses; Decompose Conditional; early returns |

## Design patterns: when and when not

Patterns are remedies for *recurring* structural problems — not decoration. The most common failure mode of less experienced refactoring (human or model) is **over-patterning**: introducing Strategy, Factory, and Observer where a plain function and a dict would do. Rules of thumb:

- Reach for a pattern only after you can name the smell it fixes and the smell has occurred more than once.
- Prefer the simplest thing: function > module > class > pattern > framework.
- In languages with first-class functions (Python, JS/TS, Kotlin, modern Java), many GoF patterns collapse into passing a function. Strategy is often just a callback; Command is often just a closure. Say so instead of building class hierarchies.
- If applying a pattern adds more lines than it removes *and* there's only one implementation, it's speculative generality. Don't.

When a pattern is genuinely warranted, read `references/design-patterns.md` for selection guidance, minimal implementations, and the smell each pattern answers.

## Naming, functions, and everyday cleanliness

For the fine-grained rules — naming, function size and shape, arguments, error handling, comments, formatting — read `references/clean-code-principles.md`. Apply these opportunistically during any refactor ("leave the campsite cleaner"), but keep such cleanups in their own small steps.

## Reference files — read on demand, not all upfront

- `references/code-smells.md` — full smell catalog: detection heuristics, examples, remedy mapping. Read when diagnosing in Phase 1.
- `references/refactoring-catalog.md` — mechanics of each named transformation (Extract Method, Move Method, Introduce Parameter Object, etc.) with safe step-by-step recipes. Read during Phase 3.
- `references/design-patterns.md` — pattern selection table, minimal modern implementations, anti-pattern warnings. Read only when the smell table points at a pattern.
- `references/clean-code-principles.md` — naming, functions, comments, error handling, tests, SOLID with practical caveats. Read when polishing or when the user asks about principles.

## Scope discipline

Refactor what was asked plus the immediate campsite — not the whole codebase. If you notice larger problems (architecture, missing tests elsewhere), report them as recommendations rather than expanding the change. Large diffs are hard to review and hard to trust; several small reviewed refactors beat one heroic one.
