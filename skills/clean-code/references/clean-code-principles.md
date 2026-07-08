# Clean Code Principles: Naming, Functions, Errors, Tests, SOLID

Fine-grained rules for everyday code quality. These are defaults with stated exceptions, not laws — when a rule fights readability in a specific case, readability wins, and say why.

## Contents
1. Naming
2. Functions
3. Comments
4. Error handling
5. Objects, data, and boundaries
6. Tests
7. SOLID, with practical caveats
8. Formatting and mechanical hygiene

---

## 1. Naming

Names are the primary documentation. Budget real effort here; a rename is the cheapest high-impact refactor.

- **Reveal intent:** the name answers why it exists, what it does, how it's used. `elapsed_days` not `d`. If a name needs a comment, the name failed.
- **Match scope to length:** single letters are fine for 2-line loop indices; the wider the scope, the more descriptive the name. Inversely: the more *called* something is, the shorter and crisper it should be.
- **Parts of speech:** functions = verbs (`send_invoice`), predicates = questions (`is_expired`, `has_children`), classes/variables = nouns (`InvoiceSender`, `overdue_invoices`). Booleans read as assertions: `if user.is_active`, never `if flag`.
- **One word per concept:** don't mix `fetch`/`retrieve`/`get` for the same operation across a codebase; pick one. Conversely don't reuse one word for two concepts (`add` meaning both arithmetic and list-append).
- **No disinformation:** `account_list` that's a set; `Manager`/`Processor`/`Data`/`Info` suffixes that say nothing. Avoid encodings (Hungarian notation, `m_` prefixes) — the compiler and IDE know the types.
- **Searchable and pronounceable:** you'll grep for it and talk about it. `MAX_RETRIES` beats `7`; `generation_timestamp` beats `genymdhms`.
- **Domain terms:** use the ubiquitous language of the problem domain (`Policy`, `Claim`, `Premium` in insurance code) so code reads like the business.

## 2. Functions

- **Small, and one thing:** a function does one thing if you cannot extract another function from it with a meaningful name. Practical target: fits on a screen; most much smaller. "One thing" = one level of abstraction — don't mix policy (`if customer.is_vip`) with plumbing (`sock.send(bytes)`).
- **One level of abstraction per function**, and code reads top-down like a newspaper: high-level narrative first, details below (stepdown rule).
- **Arguments:** fewer is better (0–2 ideal, 3 needs justification, 4+ needs a parameter object). No boolean flags (split the function). No output arguments (return the result; mutate `self` only). Don't pass `null`/`None` deliberately — overload/split or use defaults.
- **No side-effect lies:** a function's name must admit everything it does. `check_password()` that also initializes a session is a lie; either rename honestly or split (Command–Query Separation: return a value XOR change state).
- **DRY, with judgment:** extract real duplication; leave incidental duplication (see code-smells.md → Duplicated Code) alone until the rule of three.
- **Prefer pure functions** for logic: same inputs → same output, no side effects. Push side effects (I/O, mutation, time, randomness) to the edges — a "functional core, imperative shell." This single habit does more for testability than any pattern.

## 3. Comments

- The best comment is the one made unnecessary by better names or extraction.
- **Delete:** commented-out code (version control remembers), redundant restatements (`i++ // increment i`), journal comments, noise (`// default constructor`), closing-brace markers (function too long — extract instead).
- **Keep and write:** *why* explanations (constraints, chosen trade-offs), warnings ("test takes 4 min; run before release"), links to specs/tickets/papers, legal headers, TODOs with owner/context, API docs on public interfaces, and clarification of genuinely unavoidable weirdness (e.g., working around a library bug — link the bug).
- A comment that must be updated when the code changes will eventually lie. Prefer structures that can't drift: assertions, tests, types.

## 4. Error handling

- **Exceptions/results over error codes and sentinel returns.** Returning `-1`/`null` for "not found" forces every caller into checking, and forgetting is silent. Raise, or return the language's Optional/Result type.
- **Don't return null / don't pass null:** return empty collections instead of null lists; use Special Case objects or Optional for absent values; validate at boundaries so the interior can assume non-null.
- **Fail fast and loudly** at the point of detection, with context in the message (what was expected, what was found, relevant IDs). Catch only where you can actually handle or add context.
- **Never swallow exceptions** (`except: pass`). At minimum log with context; usually re-raise or wrap.
- **Wrap third-party exceptions at the boundary** into your own exception types, so the whole codebase doesn't depend on a vendor's exception hierarchy.
- **Error handling is one thing:** a function that does real work *and* has intricate try/except plumbing does two things — extract the work into its own function; the try block's body becomes one call.
- **Use the type system where available:** make illegal states unrepresentable (enums instead of strings, non-empty types, Result types) — an error the compiler prevents needs no handler.

## 5. Objects, data, and boundaries

- **Tell, don't ask:** instead of interrogating an object's state and deciding outside (`if account.balance > amount: account.balance -= amount`), tell it what to do (`account.withdraw(amount)`) and let it enforce its own invariants.
- **Law of Demeter:** talk to your immediate collaborators, not to strangers reached through them (see Message Chains).
- **Objects vs. data structures — pick per situation:** objects hide data behind behavior (easy to add new types, hard to add new operations); data structures expose data with logic elsewhere (easy to add operations, hard to add types). DTOs/records at boundaries are proper data structures; don't half-and-half (public fields *and* business methods).
- **Immutability by default:** value objects, config, messages between components — immutable unless there's a measured reason. Mutation limited in scope is the root fix for a whole family of bugs.
- **Boundaries:** wrap third-party APIs in your own thin interface (Adapter) so the dependency is quarantined and swappable; convert external primitives/DTOs into domain types at the edge, once.

## 6. Tests (as they relate to refactoring)

- Tests are what make refactoring possible at all; keep them as clean as production code — test rot ends refactoring.
- **Structure:** Arrange-Act-Assert (Given/When/Then); one logical assertion/concept per test; descriptive names stating scenario and expectation (`test_withdraw_beyond_balance_raises_insufficient_funds`).
- **F.I.R.S.T.:** Fast (or they won't be run each step), Independent (no ordering), Repeatable (no flaky time/network), Self-validating (pass/fail, no manual inspection), Timely.
- **Test behavior through public interfaces, not implementation details** — tests coupled to private structure break on every refactor and train people to skip testing. If a refactor breaks many tests without changing behavior, the *tests* were wrong.
- Test doubles: prefer real objects, then fakes; use mocks for verifying interactions at boundaries (did we send the email?), not for wiring convenience. Over-mocked tests pass while the system is broken.
- For legacy code without tests: characterization tests first (see refactoring-catalog.md §7).

## 7. SOLID, with practical caveats

- **S — Single Responsibility:** a module has one reason to change (one stakeholder/axis of change). Diagnostic: describe the class in one sentence without "and." Caveat: don't fragment into confetti — dozens of two-line classes are their own smell; responsibilities are discovered from actual change patterns, not guessed upfront.
- **O — Open/Closed:** design hot spots so new variants are added by adding code (new strategy/subclass/handler), not editing a switch in five places. Caveat: applies to *proven* axes of variation; pre-building extension points everywhere is Speculative Generality.
- **L — Liskov Substitution:** subtypes must be usable wherever the supertype is, honoring its contract (no strengthened preconditions, weakened postconditions, or surprise exceptions). Violations show up as `isinstance` checks and Refused Bequest; the fix is usually delegation instead of inheritance.
- **I — Interface Segregation:** clients shouldn't depend on methods they don't use; prefer several small role interfaces over one fat one. In duck-typed languages this happens naturally — just avoid demanding a huge object when you use two attributes.
- **D — Dependency Inversion:** policy code depends on abstractions; construction happens at the composition root and is passed in. Caveat: an interface with exactly one implementation and no test-double need is ceremony — invert the dependencies that hurt (I/O, time, network, randomness), not everything.

## 8. Formatting and mechanical hygiene

- Use the ecosystem's auto-formatter and linter (black/ruff, prettier, gofmt, rustfmt); never hand-argue style the tool settles. Adopt them in a dedicated commit, separate from logic changes.
- **Vertical organization:** related code close together; callee below caller; variables near first use; blank lines between concepts.
- Follow the codebase's existing conventions over your preferences — consistency beats local perfection. When conventions are actively harmful, propose the change; don't unilaterally mix styles.
- Keep files focused; when a file needs a scrollbar map to navigate, it's usually a Large Class/module in disguise.
