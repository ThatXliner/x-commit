# Code Smells: Detection and Remedies

A smell is a symptom, not a verdict. Each entry gives: how to detect it, why it hurts, the remedy, and when to leave it alone. Diagnose by reading the code *and* its change history/callers where available — many smells (Shotgun Surgery, Divergent Change) are only visible across changes, not in a single file.

## Contents
1. Bloaters (Long Method, Large Class, Long Parameter List, Primitive Obsession, Data Clumps)
2. Object-orientation abusers (Switch Statements, Refused Bequest, Temporary Field, Alternative Classes)
3. Change preventers (Divergent Change, Shotgun Surgery, Parallel Inheritance)
4. Dispensables (Comments, Duplicated Code, Dead Code, Speculative Generality, Lazy Class, Data Class)
5. Couplers (Feature Envy, Inappropriate Intimacy, Message Chains, Middle Man)
6. Other frequent smells (nested conditionals, flag arguments, mutable shared state, magic values, god functions in scripts)

---

## 1. Bloaters

### Long Method
**Detect:** Method needs scrolling; contains blank-line "paragraphs" or comments labeling sections; has multiple levels of abstraction (business rules next to string formatting); you need the word "and" to describe what it does.
**Why it hurts:** Can't be understood, tested, or reused in parts; hides duplication.
**Remedy:** Extract Method for each section — the section comment is usually the new method's name. If extracted pieces share lots of local variables, consider Replace Method with Method Object (turn the method into a class whose fields are the former locals), or first Split Variable / Replace Temp with Query to reduce coupling between sections.
**Leave alone:** A long but flat, single-abstraction-level sequence (e.g., a declarative config builder) can be clearer than ten one-line methods.

### Large Class / God Class
**Detect:** Many fields used by disjoint subsets of methods; the class name is vague (`Manager`, `Processor`, `Util`, `Helper`, `Common`); imports from many unrelated domains; it's the file everyone has merge conflicts in.
**Remedy:** Find responsibility seams: group fields with the methods that use them. Extract Class for each cohesive group; Extract Superclass/Subclass only if there's a genuine is-a relationship. For `Util` grab-bags, relocate each function next to the data it operates on.
**Leave alone:** A class can be legitimately large if cohesive (e.g., a parser). Judge by cohesion, not line count.

### Long Parameter List
**Detect:** 4+ parameters; callers pass `null`/`None` for some; several params always travel together; boolean parameters.
**Remedy:**
- Params that travel together → Introduce Parameter Object (often reveals a missing domain concept).
- Param derivable from another → Replace Parameter with Query (let the method compute it).
- Boolean flag steering two behaviors → split into two well-named functions.
**Leave alone:** Pure functions in math/data code where all params are genuinely independent; adding an object just to shorten the signature can hide dependencies.

### Primitive Obsession
**Detect:** `str` for emails/currencies/IDs; `float` for money; parallel constants like `STATUS_ACTIVE = 1`; validation of the same string format scattered around.
**Remedy:** Replace Primitive with Value Object: a small immutable type that validates on construction (`Money`, `EmailAddress`, `UserId`). Then move the behavior that manipulated the primitive into the new type. Related constants → enum.
**Leave alone:** At system boundaries (JSON in/out) primitives are fine; convert to value objects at the boundary, once.

### Data Clumps
**Detect:** The same 2–4 variables appear together in multiple signatures or as grouped fields (`start_date, end_date`; `host, port, timeout`). Test: delete one of them mentally — do the others lose meaning? Then they're a clump.
**Remedy:** Extract Class/value object (`DateRange`, `ConnectionConfig`). Then look for behavior that belongs on it (`range.overlaps(other)`).

---

## 2. Object-orientation abusers

### Switch Statements / repeated type conditionals
**Detect:** The *same* `switch`/`if-elif` chain on a type code or enum appears in more than one place; adding a new case means hunting down every chain.
**Remedy:** Replace Conditional with Polymorphism — one class/strategy per case — or, in dynamic/functional languages, a dispatch table (dict mapping case → function).
**Leave alone:** A *single* switch, especially in a factory or at a system boundary, is fine and often clearer than a class hierarchy. The smell is *repetition* of the conditional, not its existence. Pattern-matching languages (Rust, Scala, modern Python `match`) make exhaustive switches safe — the compiler/linter finds missing cases.

### Refused Bequest
**Detect:** Subclass overrides inherited methods to throw / no-op; uses only a sliver of the parent's interface.
**Remedy:** Replace Inheritance with Delegation (the subclass wasn't an is-a), or push the unwanted members down so the hierarchy reflects reality.

### Temporary Field
**Detect:** Fields that are only set/meaningful during one operation, `null` otherwise; "context" fields set before calling a method.
**Remedy:** Extract Class (method object) holding those fields for the duration of the operation, or just pass them as parameters.

### Alternative Classes with Different Interfaces
**Detect:** Two classes do the same job with different method names (`send()` vs `dispatch()`), so callers can't swap them.
**Remedy:** Rename/adapt until interfaces match, extract a common interface/protocol; use Adapter if you don't own one of them.

---

## 3. Change preventers

### Divergent Change
**Detect:** One class is edited for many unrelated reasons — look at commit history: "if we add a payment type we edit X; if we change the report format we also edit X."
**Remedy:** Extract Class per reason-to-change. This is the Single Responsibility Principle applied concretely: one class = one reason to change.

### Shotgun Surgery
**Detect:** The inverse — one conceptual change requires small edits in many files (adding a field means touching 9 places).
**Remedy:** Move Method/Move Field to gather the scattered logic into one home; Inline Class if fragments are too small to stand alone. Consolidate the knowledge behind one function/module so future change is one edit.

### Parallel Inheritance Hierarchies
**Detect:** Every time you subclass `Shape` you must also subclass `ShapeRenderer`.
**Remedy:** Make one hierarchy reference the other so only one needs extending; often one hierarchy collapses into data or strategies.

---

## 4. Dispensables

### Duplicated Code
**Detect:** Identical or *structurally* similar logic in multiple places (same shape, different variable names counts). Highest-priority smell — duplication is where bugs get fixed in one copy and survive in others.
**Remedy:**
- Same class → Extract Method.
- Sibling classes → Extract Method then Pull Up Method; if only the middles differ, Form Template Method or pass the differing part as a function.
- Unrelated classes → Extract into a shared function/module, or Extract Class.
**Leave alone (important):** Incidental duplication — code that looks alike but serves different concepts that will evolve independently (e.g., two validation rules that happen to be identical today). Merging incidental duplication couples unrelated things; the "wrong abstraction" is costlier than duplication. Rule of three: tolerate the second occurrence, refactor on the third — by then you can see the true shape of the abstraction.

### Comments (as deodorant)
**Detect:** Comments explaining *what* a block does; commented-out code; comments contradicting the code.
**Remedy:** Extract Method named after the comment; Rename Variable/Method until the comment is redundant; delete commented-out code (version control keeps it). Keep comments that explain *why* — constraints, gotchas, links to specs/bugs — those are valuable.

### Dead Code
**Detect:** Unreferenced functions, unreachable branches, unused params, obsolete feature flags. Use the language's static analysis where possible (`vulture`, `ts-prune`, compiler warnings, coverage).
**Remedy:** Delete. Check for dynamic access (reflection, string dispatch, external callers of a public API) before deleting exported symbols.

### Speculative Generality
**Detect:** Abstract class with one subclass; interface with one implementation; unused hook params ("we might need it"); `AbstractSingletonProxyFactoryBean`-style layering.
**Remedy:** Collapse Hierarchy, Inline Class, Remove Parameter. Add abstraction when the second real use arrives, not before.

### Lazy Class / Data Class
**Detect:** A class that doesn't earn its keep, or one that's only getters/setters while its logic lives elsewhere.
**Remedy:** Lazy → Inline Class. Data class → Move Methods that manipulate its data into it (fixes the Feature Envy on the other side). Exception: DTOs at boundaries and record/dataclass types are *supposed* to be data-only.

---

## 5. Couplers

### Feature Envy
**Detect:** A method whose body mostly calls getters/fields of *another* object. Count references: more to `other` than to `self`/`this` → envy.
**Remedy:** Move Method to the envied class; if only part of the method envies, Extract that part first, then move it. "Put behavior with the data it uses."
**Leave alone:** Deliberate separations like visitors, serializers, mappers — their whole job is to read another object's data.

### Inappropriate Intimacy
**Detect:** Two classes reaching into each other's internals; bidirectional references; friend-class access.
**Remedy:** Move Method/Field to sort belongings; Change Bidirectional Association to Unidirectional; extract the shared part into a third class both use.

### Message Chains
**Detect:** `order.getCustomer().getAddress().getCity()` — the caller knows the whole object graph, so any structural change breaks it (Law of Demeter violation).
**Remedy:** Hide Delegate (`order.getCustomerCity()`), or better, move the behavior that needs the city to where the city lives.
**Leave alone:** Fluent builders and pipeline/stream chains return *themselves or transformed values*, not navigate a structure — they're fine.

### Middle Man
**Detect:** A class where most methods just forward to another object.
**Remedy:** Remove Middle Man — let callers talk to the real object — unless the indirection exists deliberately (facade over an unstable API, decorator adding behavior).

---

## 6. Other frequent smells

### Deeply nested conditionals ("arrow code")
**Remedy:** Guard clauses / early returns for the exceptional paths first; Decompose Conditional (extract condition and branches into named functions); flatten `else` after `return`. In loops: `continue` early instead of nesting the body.

### Flag arguments
`render(data, true)` — unreadable at the call site. Split into `renderForPrint(data)` / `renderForScreen(data)`, or accept an enum whose name reads at the call site.

### Mutable shared/global state
**Detect:** Module-level mutable variables, singletons with state, functions whose result depends on call order.
**Remedy:** Encapsulate the variable behind functions; then thread it as an explicit parameter or injected dependency; make value types immutable. This is often the prerequisite that makes code testable at all.

### Magic numbers/strings
Replace Magic Literal with a named constant — but only when the name adds meaning (`SECONDS_PER_DAY`, not `SEVEN = 7`).

### God function in scripts
Procedural scripts with one 300-line `main`. Same cure as Long Method: extract phases (`load_config`, `fetch`, `transform`, `report`) so each is testable; keep `main` as a readable table of contents.

---

## Prioritizing when everything smells

1. **Duplication** and **dead code** first — cheap wins that shrink the problem.
2. **Whatever blocks the current task** — refactor the code you're about to change (preparatory refactoring: "make the change easy, then make the easy change").
3. **Change preventers** (Shotgun Surgery, Divergent Change) — these compound cost over time.
4. Cosmetics (naming, formatting) continuously, in tiny separate steps.
Skip refactoring entirely for code that works, never changes, and nobody reads.
