# Design Patterns for Refactoring

A pattern is a *target* you refactor toward when a specific smell recurs — never a starting point. This file: a selection table, then per-pattern guidance with the smell it answers, the minimal modern implementation, and the trap to avoid. Examples use Python/TypeScript-flavored pseudocode; translate idioms to the codebase's language.

**The prime directive:** in languages with first-class functions, prefer the functional equivalent when the pattern would otherwise be a one-method class. A pattern earns a class hierarchy only when implementations carry state, multiple related methods, or need discovery/registration.

## Selection table

| You observe | Consider | Functional shortcut |
|---|---|---|
| Same type-conditional repeated in several places | Strategy / State | dict of functions; passing a function |
| Object construction logic duplicated / conditional | Factory Function, Builder | plain function returning the object |
| Complex object with many optional parts | Builder | keyword args / options object with defaults |
| Need to add behavior to objects without subclass explosion | Decorator | function wrapping (higher-order function) |
| Incompatible interface you don't own | Adapter | wrapper function |
| Subsystem with a hairy multi-step API | Facade | a module exposing 2–3 functions |
| Many parts must react when something changes | Observer / pub-sub | list of callbacks |
| Behavior varies by object lifecycle phase | State | enum + dispatch table (simple cases) |
| Requests need queuing/undo/logging as data | Command | closures in a list |
| Same algorithm skeleton, differing steps | Template Method | function taking step-functions (Strategy wins in modern code) |
| Traversal over a container without exposing internals | Iterator | language generators/iterators — built in |
| One instance, global access | Singleton | ⚠️ usually a smell — see below |
| Interchangeable families of related objects | Abstract Factory | module of factory functions |
| Tree of parts treated uniformly | Composite | recursive data type |
| Expensive object stand-in / access control | Proxy / lazy | memoized function, `functools.cached_property` |

## Creational

### Factory Function / Factory Method
**Smell answered:** construction conditionals duplicated across callers; callers knowing concrete classes they shouldn't.
**Minimal form:** a plain function `make_parser(format) -> Parser` containing the *one* legitimate switch. All other switches on `format` should have been replaced by polymorphism pointing at this factory.
**Trap:** `FooFactoryImpl` classes wrapping a single `new Foo()`. If there's no conditional logic and one concrete type, call the constructor.

### Builder
**Smell answered:** telescoping constructors (many optional params), or multi-step construction with invariants.
**Minimal form:** in Python/TS, keyword arguments with defaults or an options object usually suffice. Use a real Builder when construction is stepwise, order matters, or you want an immutable result assembled gradually (`QueryBuilder().where(...).orderBy(...).build()`).
**Trap:** builders for objects with 3 fields.

### Singleton
**Smell answered:** genuinely-one resource (process-wide config, connection pool).
**Trap — read this twice:** Singleton is the most misapplied pattern. It creates hidden global mutable state, order-dependent bugs, and untestable code. Refactoring *away* from singletons (to explicit dependency injection: create once at the entry point, pass down) is far more common than refactoring toward them. If you need one instance, create one instance in `main` and pass it.

## Structural

### Adapter
**Smell answered:** Alternative Classes with Different Interfaces; integrating a third-party API into your interface.
**Minimal form:** a thin class (or function) that implements *your* interface and translates calls to *theirs*. Keep it dumb — no business logic in adapters.

### Facade
**Smell answered:** callers performing the same awkward multi-step dance with a subsystem (which is Duplicated Code + Message Chains).
**Minimal form:** a module/class exposing the few high-level operations callers actually want; the subsystem stays accessible for advanced use.
**Trap:** facades that grow into God Classes. One facade per use-case cluster.

### Decorator
**Smell answered:** subclass explosion for feature combinations (`BufferedCompressedEncryptedStream...`); adding cross-cutting behavior (retry, logging, caching) to existing objects.
**Minimal form:** wrapper implementing the same interface, delegating plus extra behavior. For functions, a higher-order wrapper (Python's `@decorator` is this pattern for callables).
**Trap:** deep decorator stacks that make debugging archaeology; more than ~3 layers, reconsider.

### Composite
**Smell answered:** client code special-casing "single item" vs "group of items."
**Minimal form:** `Leaf` and `Group` implement the same interface; `Group` holds children and forwards/aggregates. Natural for trees: UI nodes, expressions, org charts, file systems.

### Proxy
**Smell answered:** need lazy loading, access control, or remote access behind the real object's interface.
**Minimal form:** same-interface wrapper deciding when/whether to touch the real object. For pure laziness, a memoized accessor is enough.

## Behavioral

### Strategy
**Smell answered:** the repeated switch on "which algorithm/policy" (see code-smells.md → Switch Statements). The single most useful refactoring pattern.
**Minimal form:**
```python
# dict-of-functions strategy — often all you need
SHIPPING = {"standard": lambda o: 5.0,
            "express":  lambda o: 5.0 + 0.1 * o.weight,
            "free":     lambda o: 0.0}
cost = SHIPPING[order.shipping_type](order)
```
Promote to classes when strategies carry configuration/state or several related methods.
**Trap:** one strategy interface with one implementation = Speculative Generality.

### State
**Smell answered:** behavior conditional on a status field, with the same status-switch in many methods, plus scattered transition logic.
**Minimal form:** one class per state implementing the same interface; the context delegates to its current state object; transitions return/set the next state. For simple cases, an enum + transition table (`{(state, event): next_state}`) is clearer.
**Signal it's warranted:** you find yourself drawing the state diagram to understand the code.

### Observer / Pub-Sub
**Smell answered:** the subject directly calling update methods on an ever-growing hard-wired list of dependents (Shotgun Surgery when adding a listener).
**Minimal form:** subject keeps a list of callbacks; `subscribe(fn)`, `notify(event)`. Use the platform's event system when one exists.
**Trap:** observer chains firing observers → un-debuggable cascades; keep event flow shallow and one-directional. Remember unsubscription (leaks).

### Command
**Smell answered:** needing operations as *data* — undo/redo stacks, job queues, macro recording, audit logs.
**Minimal form:** closures appended to a list; for undo, pairs of `(do, undo)` closures or objects with `execute()/undo()`.
**Trap:** commandifying calls that never need queuing or undo — that's just indirection.

### Template Method vs. Strategy
Both handle "same skeleton, varying steps." Template Method uses inheritance (abstract base defines skeleton, subclasses fill steps); Strategy uses composition (skeleton function receives step functions/objects). **Default to Strategy/composition** — inheritance couples the variant to the base and Refused Bequest follows. Template Method remains fine for framework hooks where subclassing is the established idiom.

### Chain of Responsibility
**Smell answered:** a pile of `if can_handle: handle` blocks where handlers should be pluggable (middleware, validation pipelines).
**Minimal form:** a list of handlers; iterate until one handles it (or compose middleware-style, each wrapping the next).

### Visitor
**Smell answered:** many distinct operations over a *stable* object structure (AST: type-check, pretty-print, optimize), where adding operations shouldn't touch node classes.
**Trap:** the trade is explicit — Visitor makes new operations cheap and new node types expensive. If the type set changes often, plain methods (or pattern matching, which subsumes Visitor in Rust/Scala/modern Python) are better. This is the pattern most often applied where it doesn't belong; require a genuinely stable hierarchy.

### Null Object / Special Case
See refactoring-catalog.md §4. Use when absence has uniform default behavior; prefer Optional/Maybe types when the language provides them.

## Principles behind the patterns (use as tiebreakers)

- **Composition over inheritance.** Inheritance is the strongest coupling a language offers; reach for it last, and only for true is-a with Liskov-safe substitution.
- **Program to an interface, not an implementation** — but only introduce the interface when a second implementation (or a test double need) actually exists.
- **Dependency inversion, concretely:** high-level policy code should receive its dependencies (passed into constructors/functions), not construct them. Construction concentrates in `main`/composition root. This one habit makes most code testable and most patterns easy to introduce later.
- **Rule of three / YAGNI:** duplication twice is tolerable; abstraction on the third occurrence, when its true shape is visible. The wrong abstraction is more expensive than duplication.
- **Reversibility:** prefer the design that's easiest to change your mind about. A function is easier to promote to a class than a class hierarchy is to demote to a function.
