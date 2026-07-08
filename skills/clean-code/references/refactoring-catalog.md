# Refactoring Catalog: Safe Mechanics

Each transformation below is a named, behavior-preserving move with a recipe. The recipes matter: doing Extract Method "by feel" is how behavior changes sneak in. Between every numbered step, the code should compile and tests should pass. If your environment can run tests, run them at each checkpoint; if not, follow the recipe extra literally.

General rules for all transformations:
- **Use IDE/automated refactorings when available** (rename, extract, inline are mechanically safe in most IDEs and via language servers). Hand-editing is the fallback.
- **Keep the old thing working while building the new thing** (parallel change / expand–migrate–contract): add the new structure, migrate callers one by one, then delete the old. This turns a big risky step into many tiny safe ones.
- **Commit after each successful transformation** (or at least keep steps separable) so any step can be reverted alone.

## Contents
1. Composing methods: Extract Method, Inline Method, Extract Variable, Replace Temp with Query, Split Variable, Replace Method with Method Object
2. Moving features: Move Method, Move Field, Extract Class, Inline Class, Hide Delegate
3. Organizing data: Introduce Parameter Object, Replace Primitive with Object, Replace Magic Literal, Encapsulate Variable/Collection
4. Simplifying conditionals: Guard Clauses, Decompose Conditional, Consolidate Conditional, Replace Conditional with Polymorphism, Introduce Null Object
5. Simplifying APIs: Rename, Change Function Declaration, Replace Flag Argument, Separate Query from Modifier, Replace Constructor with Factory
6. Dealing with inheritance: Pull Up/Push Down, Replace Inheritance with Delegation, Collapse Hierarchy
7. Big-picture strategies: Strangler Fig, Branch by Abstraction, characterization tests for legacy code

---

## 1. Composing methods

### Extract Method (the workhorse)
Use when a fragment can be named. Recipe:
1. Create a new method named after **what** the fragment does (intent), not how.
2. Copy the fragment into it.
3. Scan the fragment for variables local to the source method:
   - Read-only inside fragment → pass as parameters.
   - Assigned inside fragment and used after → return it (if more than one, extract smaller pieces instead, or reconsider).
   - Used only inside fragment → declare inside the new method.
4. Replace the fragment in the source with a call. Compile/test.
**Danger points:** variables mutated in the fragment *and* used later; fragments containing early `return`/`break`/`continue` (restructure with guard clauses first).

### Inline Method / Inline Variable
The inverse — use when the indirection no longer adds meaning, or as prep before re-extracting along better seams. Recipe: verify the method isn't polymorphically overridden; replace each call with the body; delete. Inlining is also how you dismantle a Middle Man or Lazy Class.

### Extract Variable
Give a name to a subexpression in a complicated expression: `const isEligible = age >= 18 && country in EU && !banned`. Zero-risk if the subexpression has no side effects — check that first.

### Replace Temp with Query
A temp variable computed once and read many times → extract the computation into a method and call it. Prerequisite for Extract Method when temps tangle sections together. Only when the computation is side-effect-free and cheap (or cached).

### Split Variable
A variable assigned more than once for *different purposes* (e.g., `temp` reused) → one variable per purpose, each named for its purpose.

### Replace Method with Method Object
For a Long Method whose locals are too tangled for Extract Method: create a class; the method's locals become fields; the method becomes `run()` on the class; now extract freely inside the class without parameter-passing pain.

---

## 2. Moving features between objects

### Move Method
Use for Feature Envy. Recipe:
1. Check what the method references from its current class; if it uses current-class features too, decide whether to move those first or pass them in.
2. Copy the method to the target class; adjust `self`/`this` references (the envied object becomes `self`; the old host may become a parameter).
3. Turn the original into a delegating call to the new one. Compile/test.
4. Migrate callers to the new location; delete the delegator.

### Move Field
Similar recipe; encapsulate the field first (accessors) so the move touches one place.

### Extract Class
Use for Large Class, Data Clumps, Divergent Change. Recipe:
1. Decide the responsibility split; name the new class.
2. Create the new class; link from old to new (old holds an instance).
3. Move Field one at a time (test each); then Move Method one at a time, starting with lower-level methods.
4. Review interfaces; decide whether to expose the new class to callers or keep it internal.

### Inline Class
Inverse; fold a Lazy Class into its main user.

### Hide Delegate
For Message Chains: add `getCustomerCity()` on `Order` that internally does the chain; migrate callers; the caller no longer knows about `Customer`/`Address`. Don't overdo — every delegator you add turns the host toward Middle Man; prefer moving the *behavior* when possible.

---

## 3. Organizing data

### Introduce Parameter Object
1. Create a class/record for the clump (`DateRange(start, end)`). Prefer immutable.
2. Add the new parameter to the function alongside the old ones; pass it from each caller (expand).
3. Inside the function, switch reads to the object one field at a time; testing throughout (migrate).
4. Remove the now-unused individual parameters (contract).
5. Look for behavior to move onto the new object — that's where the real payoff is.

### Replace Primitive with Object (value object)
1. Create a class wrapping the primitive; validate in the constructor; make it immutable; give it equality by value.
2. Change the field/variable to hold the object; keep a `.value`/`toString` escape hatch so old code compiles.
3. Migrate operations on the raw value into methods on the object; shrink the escape hatch usage to the system boundary.

### Replace Magic Literal
Named constant near its domain (or enum member). Verify all occurrences of the literal actually mean the same thing before consolidating — two different 60s (seconds vs items-per-page) must become two constants.

### Encapsulate Variable / Encapsulate Collection
Wrap direct access behind functions so you can later move/validate/monitor it. For collections: return copies or read-only views; provide `add_x`/`remove_x` methods rather than exposing the mutable list — otherwise callers mutate state the owner can't see.

---

## 4. Simplifying conditional logic

### Replace Nested Conditional with Guard Clauses
1. Identify the exceptional/edge conditions.
2. For each, add an early `return`/`raise` at the top.
3. The remaining main path un-indents to the function body level. Order guards from most fundamental (null/invalid input) to most specific.

### Decompose Conditional
Extract the condition into a predicate function (`isEligibleForRefund(order)`) and each branch into an intention-named function. The `if` line then reads like a sentence.

### Consolidate Conditional Expression
Several conditions with the same result → combine with `and`/`or` into one named predicate. Only when they truly represent one idea.

### Replace Conditional with Polymorphism
Use only when the same conditional over types recurs in multiple places. Recipe (via Strategy — see design-patterns.md for shape):
1. Create the class hierarchy or strategy set: one type per branch.
2. Copy each branch body into the corresponding type's method.
3. Replace the conditional with a polymorphic call; the *construction-time* decision of which type to instantiate may keep a single switch (that's fine — it's now in exactly one place, typically a factory).
In dynamic languages a dict-of-functions dispatch table achieves the same with less ceremony.

### Introduce Null Object / Special Case
Repeated `if x is None`/`if (x == null)` checks for the same fallback behavior → a `NullCustomer`/`UnknownUser` object implementing the interface with default behavior. Use when the *fallback behavior* is uniform; if each caller handles absence differently, keep explicit checks (or use the language's Optional/Maybe).

---

## 5. Simplifying method calls and APIs

### Rename (variable/method/class)
The highest-value cheapest refactor. Recipe for public members without IDE support: add new name delegating to old → migrate callers → deprecate/delete old. Names should say intent; if you can't name it, you don't understand it yet — that's diagnostic information.

### Change Function Declaration (add/remove parameter, reorder)
Use the expand–migrate–contract pattern: introduce the new signature as a new function (or with defaults), migrate callers, remove the old. Never break all callers at once in a shared codebase.

### Replace Flag Argument with Explicit Functions
`book(customer, true)` → `bookPremium(customer)` + `bookRegular(customer)`, both delegating to a private parameterized implementation if they share most logic.

### Separate Query from Modifier (Command–Query Separation)
A function that returns a value *and* changes state → split into a query (no side effects, returns value) and a command (side effects, returns nothing). Callers that need both call both. Makes call sites honest and code testable.

### Replace Constructor with Factory Function
When construction logic grows (choosing subtypes, caching, validation variants), move it to a named factory. Also enables Replace Conditional with Polymorphism to keep its one legitimate switch.

---

## 6. Dealing with inheritance

### Pull Up Method/Field
Identical members in siblings → move to the superclass. If similar-but-not-identical, first make them identical (rename, parameterize), then pull up.

### Push Down Method/Field
Member only relevant to some subclasses → push it to those subclasses (fixes partial Refused Bequest).

### Replace Inheritance with Delegation
When the subclass uses little of the parent or isn't a true is-a: give the class a field holding the former parent, implement the needed methods as delegating calls, drop the inheritance. (Classic case: `Stack extends Vector` — a Stack *has* storage, it isn't a Vector.)

### Collapse Hierarchy
Parent and child no different enough to justify two classes → merge them. Common cleanup after Speculative Generality.

### Extract Superclass / Extract Interface
Two classes share behavior → Extract Superclass and Pull Up. Callers need only a slice of a class → Extract Interface/Protocol for that slice (Interface Segregation in practice).

---

## 7. Big-picture strategies

### Preparatory refactoring
Before implementing a feature in awkward code: first refactor so the feature becomes easy ("make the change easy — warning: this may be hard — then make the easy change"). Keep the refactor and the feature as separate steps/commits.

### Characterization tests (for untested legacy code)
1. Find a seam — a place you can observe behavior (return values, outputs, state changes).
2. Write a test asserting something trivially wrong (`assert result == "XXX"`), run it, and copy the *actual* value into the assertion. The current behavior, bugs included, is the spec.
3. Cover the paths you're about to disturb: happy path, boundaries, error paths. Coverage tools show what you've pinned.
4. If the code can't even be instantiated in a test (hard-wired dependencies), do the minimal dependency-breaking move first: extract the dependency behind a parameter or overridable method, keeping the default behavior identical.

### Strangler Fig
For replacing a large module/system: build the new implementation alongside, route traffic/calls to it incrementally (feature flag, adapter, proxy), and delete the old when nothing routes there. Never big-bang rewrite a live system.

### Branch by Abstraction
For long-running restructures on a shared codebase: introduce an abstraction over the old implementation, migrate callers to the abstraction, build the new implementation behind it, flip, remove the old. The build stays green throughout — no long-lived branches.

---

## If you cannot run tests

Ranked by safety for by-inspection refactoring:
1. Rename (IDE/LSP-assisted), Extract Variable of pure expressions, deleting provably dead code
2. Extract Method of side-effect-free fragments; guard clauses replacing symmetric if/else
3. Introduce Parameter Object via expand–migrate–contract
4. Anything involving inheritance, moved state, or reordered side effects — **avoid without tests**; propose it to the user with the caveat instead of doing it.
