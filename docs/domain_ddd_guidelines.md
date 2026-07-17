# Domain Layer Guidelines (DDD-lite) — Munchies

This document describes how to model the **domain layer** in Munchies. It is the companion to
[mvvm_riverpod_pattern.md](./mvvm_riverpod_pattern.md): that one covers the **presentation**
layer (View / ViewModel / State); this one covers the **domain** (entities, value objects,
services, ports). Read them together — they govern different layers and don't compete.

**Philosophy — DDD *lite*, not dogmatic DDD.**
Munchies is maintained by **one developer**, it's an **MVP**, and its backend is **Firebase**.
So the guiding rule is: **model deeply only where there are real business rules; everything else
is plain data.** The domain exists to protect *one* crown jewel — the consolidated grocery-list
calculation — and the handful of invariants that actually matter (a publishable recipe, a valid
quantity). Not to wrap every `String` in a class.

> If a layer or class doesn't protect an invariant or encapsulate a rule, **don't create it.**
> Ceremony without a rule is debt, not architecture.

---

## Core Rules

1. **The domain knows nothing about the outside world.** Zero imports of Flutter, Firebase,
   Riverpod, `http`, `SharedPreferences`, or any IO. If a file under `domain/` imports one of
   those, it's in the wrong layer. (Tolerated exception: `freezed_annotation` for union types —
   that's data codegen, not a framework.)
2. **Depth only with an invariant.** A concept is a Value Object / Entity / Service **only if it
   protects a rule.** No rule → a primitive or a plain data class/`record`.
3. **Domain errors are a `sealed Result<T>` / `sealed Failure`,** never `dartz`
   (`Either`/`Option`), and never exceptions for expected flow (§4).
4. **Data access is declared as a port** (an `I...Repository` interface) in `domain/`; the
   implementation lives in `infrastructure/` (§5). The domain depends on the abstraction, never
   the other way around.
5. **Equality that fits the type:** Value Objects and states compare **by value** (all their
   fields); Entities compare **by identity** (`id`). Everything immutable (§1, §2).
6. **DTO ≠ domain.** The Firestore JSON/`Map` and its parsing live in `infrastructure/`
   (mappers). The domain never sees `fromJson`/`toJson` (§7).
7. **Domain services are pure functions over the domain.** No app state, no `ref`, no IO. Domain
   objects in, a domain object out. They live in `domain/`, not `aplication/` (§3).

---

## Anatomy of the layer

```
lib/domain/
  core/
    units/            # Unit, Dimension, Quantity, UnitConverter  (VO + enums with behavior)
    value_objects/    # ONLY the ones that protect an invariant (Email, Password, ...)
    failures/         # sealed Failure per context (not one global junk drawer)
    result.dart       # sealed Result<T> (replaces dartz)
  food/               # Food (entity), FoodCategory, IFoodRepository (port)
  recipe/             # Recipe (aggregate root), RecipeIngredient, IRecipeRepository
  meal_plan/          # MealPlan (aggregate), PlannedRecipe
  shopping/           # ShoppingList, ShoppingItem, ShoppingListCalculator (domain service)
```

**Golden rule for placement:** a type lives in the **bounded context** whose language it speaks.
`Quantity` is cross-cutting → `core/units`. `Recipe` belongs to `recipe/`. A service that spans
contexts (the calculator uses recipe + food + shopping) lives in the context of its **output**
(`shopping/`, because it produces a `ShoppingList`).

---

## 1. Value Objects — only where there's an invariant

A **Value Object (VO)** wraps a value plus **the rule that makes it valid**, is immutable, and
compares by value. Create a VO **only** when there's an invariant worth protecting in a single
place.

**From the project — `Quantity`** (an amount + unit; the rule: `amount > 0`, and it knows how to
convert to its canonical unit). This is the model to follow: **lightweight, no `dartz`, the rule
lives inside it.**

```dart
// domain/core/units/quantity.dart  — a VO done right
class Quantity {
  final double amount;
  final Unit unit;
  const Quantity(this.amount, this.unit);

  bool get isValid => amount > 0;                       // the invariant, in one place
  double get canonicalAmount => amount * unit.factorToCanonical;

  Quantity copyWith({double? amount, Unit? unit}) =>
      Quantity(amount ?? this.amount, unit ?? this.unit);

  @override
  bool operator ==(Object other) =>                     // equality BY VALUE
      other is Quantity && other.amount == amount && other.unit == unit;
  @override
  int get hashCode => Object.hash(amount, unit);
}
```

### 1.1 When *not* to create a VO

If a value has no rule, it's a plain type. A recipe's `title` is a `String`; its rule (`3..80`
chars) lives in the aggregate's invariant (`Recipe.isPublishable`, §2), not in a `RecipeTitle`
VO. A `foodId` is a `String`. Don't wrap them.

| Create a Value Object when… | Keep it a primitive when… |
|-----------------------------|---------------------------|
| There's a validity rule (`amount > 0`, email format) | It's an identifier or free text with no rule (`id`, `note`) |
| The value bundles fields that travel together (`amount` + `unit`) | It's a single scalar with no behavior |
| You need behavior on the value (convert, format) | It's only read and displayed |

### 1.2 The no-`dartz` pattern — a smart constructor returning `Result`

When construction **can fail** (email, password), don't use the `Either`-based `ValueObject<T>`
inherited from the template. A **private constructor + a factory that returns `Result`** says the
same thing without `dartz`:

```dart
// domain/core/value_objects/email.dart  — proposed
class Email {
  final String value;
  const Email._(this.value);

  static Result<Email> create(String raw) {
    final v = raw.trim();
    if (!_regex.hasMatch(v)) return Err(InvalidEmail(v));   // §4
    return Ok(Email._(v));
  }

  static final _regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
}
```

The caller `switch`es over the `Result` (§4) — never a `.getOrCrash()` that blows up at runtime.

---

## 2. Entities and Aggregate Roots

An **Entity** has its own identity (`id`) and lifecycle; it compares **by `id`**, not by its
fields (two recipes with the same `id` are the same recipe, even if their steps differ). An
**Aggregate Root** is the entity that's the entry point to a cluster and the **owner of its
invariants**.

**From the project — `Recipe`** (an aggregate root; owner of the publishing rules):

```dart
// domain/recipe/recipe.dart
class Recipe {
  final String id;
  final String title;
  final int yieldServings;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  // ...
  const Recipe({ required this.id, required this.title, /* ... */ });

  /// Aggregate invariant: what makes a recipe publishable. RN-RECIPE-01..05.
  bool get isPublishable =>
      title.trim().length >= 3 &&
      title.trim().length <= 80 &&
      yieldServings > 0 &&
      ingredients.isNotEmpty &&
      ingredients.every((i) => i.isValid);

  @override
  bool operator ==(Object other) => other is Recipe && other.id == id;  // BY IDENTITY
  @override
  int get hashCode => id.hashCode;
}
```

**Rules:**
- The invariant lives on the aggregate (`isPublishable`), not scattered across the UI or the
  repository. The View **asks** (`recipe.isPublishable`); it doesn't reimplement the rule.
- Equality **by `id`** for entities; **by value** for VOs (§1) and for UI states (which are
  freezed — see the mvvm doc).
- The aggregate is the only door to its children: don't let other code assemble a `Recipe` in an
  illegal state by going around the root.

---

## 3. Domain services — pure functions

When a rule **doesn't belong to a single entity** (it spans several, or it's a computation), it's
a **domain service**: a pure class/function with no app state, no `ref`, no IO. Domain objects
in, a domain object out. It's the **most testable** thing in the project.

**From the project — `ShoppingListCalculator`** (the crown jewel: turns a plan into a
consolidated grocery list). Note: it touches neither Firebase nor Riverpod; it takes
already-resolved data and returns a `ShoppingList`.

```dart
// domain/shopping/shopping_list_calculator.dart
class ShoppingListCalculator {
  final UnitConverter _converter;
  const ShoppingListCalculator([this._converter = const UnitConverter()]);

  ShoppingList build({
    required List<PlannedEntry> planned,          // domain in
    required Map<String, Food> foodsById,
  }) {
    // scale by servings, convert to canonical, sum by foodId, humanize…
    return ShoppingList(items: items, unresolvedFoodIds: unresolved.toList()); // domain out
  }
}
```

> **⚠️ Pending fix in the repo:** today this service lives at
> `lib/aplication/shopping/shopping_list_calculator.dart`. It's **pure domain** (§3): it doesn't
> orchestrate providers and holds no app state → it should move to `lib/domain/shopping/`. Its
> being under `aplication/` is the symptom of the blurry line between "domain logic" and
> "application layer" that this document exists to draw.

**Rule — domain vs. application:**

| Belongs in `domain/` (domain service) | Belongs in `aplication/` (use case / ViewModel) |
|---------------------------------------|--------------------------------------------------|
| Pure: same inputs → same output | Orchestrates: calls repos, providers, side effects |
| Knows no `ref`, no IO `Future`s | Coordinates IO, handles `AsyncValue`, caches |
| The grocery calculation, unit conversion | "Fetch the plan's recipes and compute the list" |

---

## 4. Errors and results — `sealed Result<T>` (we retire `dartz`)

Munchies had been using `dartz` (`Either`, `Option`, `Unit`). We're **retiring it**: `dartz` is
effectively unmaintained, and its ergonomics (`fold`, `left`, `right`, `some`, `none`) are noise
next to what modern Dart already gives you with `sealed class` + exhaustive `switch` + nullables.

**The base type** (just one, in `domain/core/result.dart`):

```dart
sealed class Result<T> {
  const Result();
}
class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}
class Err<T> extends Result<T> {
  final DomainFailure failure;
  const Err(this.failure);
}
```

**Failures are `sealed` and per-context** — not one giant global drawer (see the anti-pattern).
Each bounded context declares its own:

```dart
// domain/core/failures/value_failure.dart
sealed class ValueFailure {
  final String failedValue;
  const ValueFailure(this.failedValue);
}
class InvalidEmail extends ValueFailure { const InvalidEmail(super.v); }
class ShortPassword extends ValueFailure { const ShortPassword(super.v); }
```

**Usage** — exhaustive `switch` (the compiler forces you to cover every case):

```dart
final result = Email.create(raw);
switch (result) {
  case Ok(:final value):    /* use value */
  case Err(:final failure): /* map to copy in the View (§2.3 of the mvvm doc) */
}
```

**Rules:**
- **Use `Result<T>` for operations that can fail in an expected way** (validation, a save the
  user should be able to retry).
- **Use `T?` (nullable) for "not found",** which is not an error: `Future<Recipe?> getById(id)`
  is correct as-is — `null` means "doesn't exist", full stop.
- **`throw` only for the genuinely exceptional** (a bug, an impossible state), never for expected
  business flow.
- The domain returns a **semantic `Failure`**, never a user-facing `String`. The View maps it to
  copy (see §2.3 of the mvvm doc). This keeps the domain testable without localization.

---

## 5. Ports — repository interfaces

The domain **declares what it needs** as an interface (`I...Repository`); `infrastructure/`
decides **how** (Firestore, local assets, cache). The domain never imports the implementation.

**From the project — clean and minimal:**

```dart
// domain/recipe/i_recipe_repository.dart
abstract interface class IRecipeRepository {
  Future<List<Recipe>> getAll();
  Future<Recipe?> getById(String id);   // T? = not found (not an error, §4)
}
```

**Rules:**
- Use `abstract interface class` (Dart 3): it declares a contract and forbids inheriting an
  implementation.
- The signature speaks the **domain's language** (`Recipe`, not `DocumentSnapshot`). Firestore
  must not leak into the port.
- If a method can fail in a way the user must handle, return `Result<T>` (§4); if it can only
  "not exist", return `T?`.
- **Don't invent anemic ports "just in case."** Declare a method the day a use case needs it.

---

## 6. Enums with behavior

A Dart `enum` can carry data and methods. Use it for **closed sets with behavior** instead of
loose constants plus `if` chains.

**From the project — `Unit`** (each unit knows its dimension and its canonical factor):

```dart
// domain/core/units/unit.dart
enum Unit {
  gram(symbol: 'g', dimension: Dimension.mass, factorToCanonical: 1),
  kilogram(symbol: 'kg', dimension: Dimension.mass, factorToCanonical: 1000),
  cup(symbol: 'cup', dimension: Dimension.volume, factorToCanonical: 240),
  // ...
  const Unit({required this.symbol, required this.dimension, required this.factorToCanonical});
  final String symbol;
  final Dimension dimension;
  final double factorToCanonical;

  static Unit? fromSymbolOrNull(String s) =>
      Unit.values.where((u) => u.symbol == s).firstOrNull;
}
```

The behavior lives **with** the data, and a `switch` over the enum is exhaustive. Prefer this to a
`Map<String, double>` of factors scattered elsewhere.

---

## 7. DTO ≠ domain (mapping lives in infrastructure)

The domain **knows nothing about JSON or Firestore.** A `Map<String, dynamic>` crossing the wire
is a **DTO**, and its parsing (`fromMap`/`toMap`) is a **mapper** in `infrastructure/`.

```
infrastructure/recipe/
  recipe_mapper.dart          # Map<String,dynamic> <-> Recipe   (fromMap/toMap lives here)
  recipe_repository.dart      # implements IRecipeRepository over Firestore, using the mapper
```

- The domain (`Recipe`) has **no `fromJson`/`toJson`.** Add them and you've coupled the business
  model to the backend's shape — the day Firestore renames a field, the domain breaks.
- The mapper translates at the boundary: `imageUrl` from the `Map` → `Recipe.imageUrl`. If the
  backend sends an awkward shape, **normalize it in the mapper**, not by polluting the entity.
- Need an intermediate shape with `toJson` (e.g. to write to Firestore)? That's a DTO in
  `infrastructure/` (like `session/session_dto.dart`, `session/user_dto.dart`) — **not** in
  `domain/`.

---

## Summary Table

| Concept | Protects | Equality | Where it lives | May touch IO/framework? |
|---------|----------|----------|----------------|--------------------------|
| **Value Object** | One value's invariant | By value (all fields) | `domain/**` | No |
| **Entity / Aggregate** | A cluster's invariants | By `id` | `domain/<context>` | No |
| **Domain service** | A pure rule/computation | N/A (stateless) | `domain/<context>` | No |
| **Port (`I...Repository`)** | The data contract | N/A | `domain/<context>` | No (signature only) |
| **`Result` / `Failure`** | The outcome of something that can fail | By value | `domain/core` | No |
| **DTO + Mapper** | The backend's shape | N/A | `infrastructure/**` | Yes |
| **ViewModel / State** | A screen's state | State by value | `presentation/**` (see mvvm doc) | Yes (Riverpod) |

---

## Anti-Patterns to Avoid

- **Wrapping everything in Value Objects.** A `RecipeTitle`, `FoodId`, or `StepText` whose only
  "rule" is "it's a String" is ceremony. VO **only with an invariant** (§1.1). Munchies has
  exactly **one** domain jewel (the grocery calculation) and a handful of invariants — model
  those, not every field.

- **A global failure drawer holding another domain's concepts.** The current
  [`domain/core/failures/value.dart`](../../lib/domain/core/failures/value.dart) carries
  `invalidLicensePlate`, `invalidVehicleBrand`, `noPaymentMethodSelected`, `invalidPassenger`…
  rules from a **driver/payments** app inherited from the template. That **is not Munchies'
  domain.** Failures are `sealed` and **per-context** (an auth `ValueFailure` ≠ recipe failures),
  declaring only what Munchies actually uses.

- **`dartz` (`Either`/`Option`/`Unit`) for domain flow.** Unmaintained noise; use
  `sealed Result<T>` + `switch` + nullables (§4). The base `ValueObject<T>` with `Either` and
  `getOrCrash()` (which blows up at runtime) retires along with `dartz`.

- **Exceptions for expected flow.** A validation that fails or a retryable save returns a
  `Result`, it doesn't throw. `throw` is for the impossible.

- **A domain service living in `aplication/`.** `ShoppingListCalculator` is pure domain (§3): its
  home is `domain/shopping/`. `aplication/` is for orchestration with IO/`ref`.

- **`fromJson`/`toJson` on a domain entity.** It couples the business to the backend. Mapping
  lives in an `infrastructure/` mapper (§7).

- **The domain importing Flutter/Firebase/Riverpod.** If `domain/` imports `cloud_firestore`,
  `flutter/material.dart`, or `flutter_riverpod`, the dependency points the wrong way. The domain
  is the center: everything depends on it, it depends on nothing.

- **By-value equality on an entity (or by-`id` on a VO).** A `Recipe` compares by `id`; a
  `Quantity` by its fields. Mixing them up breaks sets, dedupe, and list `==`.

- **Reimplementing an aggregate invariant in the UI.** If the View computes
  `title.length >= 3 && ingredients.isNotEmpty` instead of asking `recipe.isPublishable`, the
  rule gets duplicated and drifts. The rule lives on the aggregate; the View asks.
```