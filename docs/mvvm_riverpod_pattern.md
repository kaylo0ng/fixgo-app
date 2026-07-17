# MVVM Feature Page Pattern with Riverpod

This document describes how to create a feature page following the MVVM pattern used in this codebase.

**Important:**
- Never put UI controllers (ScrollController, TextEditingController, AnimationController, FocusNode, etc) or BuildContext in ViewModels. All UI logic and context-dependent actions (dialogs, navigation, snackbars) must be handled in the View.

---

## Core Rules

1. **Every ViewModel is auto-dispose. Pick the notifier by whether `build()` is async:**
   - `build()` does asynchronous work (any `await`) → **`AutoDisposeAsyncNotifier<State>`** (state is `AsyncValue<State>`).
   - `build()` is fully synchronous (just reads already-resolved providers / composes plain values) → **`AutoDisposeNotifier<State>`** (state is plain `State`).
   - Always the **auto-dispose** variant, never the keep-alive `AsyncNotifier` / `Notifier`. See §2.1.
2. **Views only know their own ViewModel.** A View must never `watch` or `read` a global provider directly (e.g., `currenciesProvider`, `globalAppProviderRP`). The ViewModel is the only intermediary.
3. **ViewModels consume global providers and expose only the data the View needs.**
4. **Never put UI controllers or BuildContext in ViewModels.** ScrollController, TextEditingController, AnimationController, FocusNode, etc. must live in the View. ViewModels must not receive or use BuildContext, even as a parameter to a method. All UI logic and context-dependent actions (dialogs, navigation, snackbars) must be handled in the View.
5. **Prefer `.select` when watching global providers** inside a ViewModel to avoid unnecessary rebuilds.
6. **Feature-level shared providers live in a `providers/` subfolder** inside the feature directory. Any ViewModel inside that feature can import from there. A provider lives at the level of its **widest consumer** — a feature-global provider must never depend on a step-nested one (see §4.3).
7. **A ViewModel/provider and its State live together in their own folder.** When a ViewModel (or provider) has a dedicated `*_state.dart`, the pair — plus the View, if any — goes in its own named folder, never loose alongside other ViewModels. A provider with **no** dedicated state class (it exposes a single value or an `AsyncValue<Dto>`) can stay a loose file.

---

## File Structure

There are **two page shapes**. Both reuse the same State / ViewModel / View layers
(§1–§3); they differ only in how the page is *orchestrated*.

### Shape A — Multi-Step Flow

A page that walks the user through ordered steps (a wizard, an order flow). The flow lives on a
**nested `Navigator`** owned by the View; steps push/pop themselves. **Navigation is never
Riverpod** — there is no "current step" provider. See §4.1 (pick the flow widget) and §5 (host it).

```
lib/pages/FeatureName/
  FeatureNamePage_route.dart        # Self-contained route: path(s) + AppRoute + typed push/go (§6.1)
  FeatureNamePage.dart              # Route entry; gates global data via its ViewModel, then hosts the flow
  FeatureNamePage_viewmodel.dart    # Page-wide concerns only (global-data gating, analytics) — NOT step state
  FeatureNameNavigator.dart         # View layer: hosts the flow Navigator + the feature's push/pop nav API
  providers/                        # Shared *data* providers for this feature (never step state)
    FeatureSharedData_provider.dart
  steps/
    stepOne/
      StepOne_view.dart             # pushes the next step via the flow nav API
      StepOne_viewmodel.dart        # returns a sealed result; the View navigates (see §2.2)
      StepOne_state.dart            # State class extending Equatable
    stepTwo/
      StepTwo_view.dart
      StepTwo_viewmodel.dart
      StepTwo_state.dart
    stepThree/
      StepThree_view.dart
      StepThree_viewmodel.dart
      StepThree_state.dart
```

### Shape B — Composed Page (dashboard-style)

A page that is a **composition of independent, self-contained widgets** stacked in a scroll
view (the Home page is the canonical example). There are no steps: every widget is its own
mini-MVVM triad and owns its data, loading, error, and refresh. See §9.

```
lib/pages/FeatureName/
  FeatureNamePage_route.dart        # Self-contained route: path(s) + AppRoute + typed push/go (§6.1)
  FeatureNamePage.dart              # Composition: Scaffold + RefreshIndicator + ListView
  FeatureNamePage_viewmodel.dart    # Thin: page-wide concerns only (no per-widget state)
  widgets/
    WidgetOne/
      WidgetOne.dart                # View (ConsumerWidget / StatelessWidget + Consumer)
      WidgetOne_viewmodel.dart      # AutoDisposeNotifier or AutoDisposeAsyncNotifier
      WidgetOne_state.dart          # Optional: only if it needs more than a single value
      widgets/                      # Sub-widgets private to WidgetOne
        WidgetOneHeader.dart
    WidgetTwo/
      WidgetTwo.dart
      WidgetTwo_viewmodel.dart
      WidgetTwo_state.dart
```

---

## 1. State

Define a plain immutable class that extends `Equatable`. This lets Riverpod and widgets skip rebuilds when the state has not actually changed.

> **State is not a DTO.** `lib/models/` is for API DTOs/parsers (`fromJson` / `fromDynamic`, `toJson`). A class that holds already-**resolved domain objects** (e.g. a full `Currency` + `PaymentMethod`) and exists to drive the UI is a ViewModel **State** — it belongs in the feature, next to its ViewModel, not in `lib/models/`. Tell them apart by the job: a DTO crosses the wire; a State feeds the View.

```dart
// StepOne_state.dart

import 'package:equatable/equatable.dart';

class StepOneState extends Equatable {
  final List<String> items;
  final bool isSubmitting;

  const StepOneState({
    this.items = const [],
    this.isSubmitting = false,
  });

  StepOneState copyWith({List<String>? items, bool? isSubmitting}) {
    return StepOneState(
      items: items ?? this.items,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [items, isSubmitting];
}
```

### 1.1 Sealed / union states for mutually-exclusive shapes

When a widget has **distinct, mutually-exclusive modes** that carry different data (enabled vs.
disabled, empty vs. populated, variant A vs. B), model the state as a **`sealed` class** with
one subclass per mode instead of cramming nullable fields and booleans into a single class.
Each subclass carries exactly the fields that mode needs, and the View pattern-matches with an
exhaustive `switch`.

```dart
// RecentOrdersCarousel_state.dart

sealed class RecentOrdersCarouselState extends Equatable {
  const RecentOrdersCarouselState({required this.show});
  final bool show;

  @override
  List<Object?> get props => [show];
}

class RecentOrdersCarouselDisabledState extends RecentOrdersCarouselState {
  const RecentOrdersCarouselDisabledState({super.show = false});
}

class RecentOrdersCarouselEnabledState extends RecentOrdersCarouselState {
  const RecentOrdersCarouselEnabledState({
    super.show = true,
    required this.orders,
    required this.canShowMoreOrders,
  });

  final AsyncValue<List<MyOrderInfo>> orders; // a nested AsyncValue is fine as a field
  final bool canShowMoreOrders;

  @override
  List<Object?> get props => [...super.props, orders, canShowMoreOrders];
}
```

In the View, switch over the subtypes — `sealed` makes the `switch` **exhaustive** at compile
time, so adding a new mode forces every consumer to handle it:

```dart
data: (state) {
  return switch (state) {
    RecentOrdersCarouselEnabledState(:final orders, :final canShowMoreOrders) =>
        OrdersCarousel(orders: orders, canShowMore: canShowMoreOrders),
    RecentOrdersCarouselDisabledState() => const SizedBox.shrink(),
  };
},
```

**When to use which:**
- **Plain `Equatable` + `copyWith`** (the §1 example) — one shape whose fields vary independently
  (a form with `items` + `isSubmitting`). This is the default.
- **`sealed` union** — the widget is in one of N exclusive states and each carries different data.
  Prefer it over a single class full of `nullable` fields guarded by a `bool`/`enum`, which lets
  illegal combinations compile.

**Notes:**
- Still extend `Equatable`; in subclasses fold the parent's props with `[...super.props, ...]`.
- A subclass field may itself be an `AsyncValue<...>` (see `orders` above) when one mode wraps
  async data while another does not.

---

## 2. ViewModel

The ViewModel:
- Watches/reads global providers in `build()` via `ref.watch` / `ref.read`.
- Exposes only the processed data the View cares about (never raw global state).
- Prefers `ref.watch(someProvider.select((s) => s.relevantField))` to minimize rebuilds.

### 2.1 Async vs. sync notifier — pick by `build()`

The base class is **not** always async. Choose by whether `build()` needs to `await`:

| `build()` does...                                             | Use                              | State exposed to the View |
|---------------------------------------------------------------|----------------------------------|---------------------------|
| Any `await` (network, `.future`, `.selectAsync`, a service)   | `AutoDisposeAsyncNotifier<State>`| `AsyncValue<State>`       |
| Only synchronous reads (sync providers, `.select`, plain math)| `AutoDisposeNotifier<State>`     | `State`                   |

Both are **auto-dispose** — never the keep-alive `AsyncNotifier` / `Notifier` for page- or
widget-scoped ViewModels (resources must be freed when the widget is popped).

**Sync example** — every dependency is already resolved, so there is nothing to `await`:

```dart
class TotalBalanceViewModel extends AutoDisposeNotifier<TotalBalanceState> {
  @override
  TotalBalanceState build() {
    return TotalBalanceState(
      totalBalance: ref.watch(totalBalanceProvider),                       // sync provider
      isPrivateModeOn: ref.watch(globalAppProviderRP).privateMode,         // sync read
    );
  }

  void togglePrivateMode() {
    ref.read(globalAppProviderRP.notifier).managePrivateMode(!state.isPrivateModeOn);
  }
}

final totalBalanceViewModel =
    AutoDisposeNotifierProvider<TotalBalanceViewModel, TotalBalanceState>(
  TotalBalanceViewModel.new,
);
```

In the View this is watched directly (no `AsyncValue`):

```dart
final state = ref.watch(totalBalanceViewModel.select((e) => e.totalBalance));
```

**Async example** — `build()` awaits, so the state is an `AsyncValue<State>` (this is the case
shown in the full example below). Use it whenever you `await` a `.future`, `.selectAsync`, or a
service call.

> Rule of thumb: don't reach for `AsyncNotifier` reflexively. If `build()` has no `await`, a
> synchronous `AutoDisposeNotifier` gives the View a plain value and avoids wrapping everything
> in `AsyncValue.when(...)` for no reason.

```dart
// StepOne_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munchies_time_frontend/providers/Currencies/Currencies_provider.dart';
import 'package:munchies_time_frontend/pages/FeatureName/providers/FeatureSharedData_provider.dart';

final stepOneViewModelProvider =
    AutoDisposeAsyncNotifierProvider<StepOneViewModel, StepOneState>(
  StepOneViewModel.new,
);

class StepOneViewModel extends AutoDisposeAsyncNotifier<StepOneState> {
  @override
  Future<StepOneState> build() async {
    // Consume global providers here, not in the View.
    //
    // For async global providers, prefer .future or .selectAsync over
    // .valueOrNull so the ViewModel waits for the data to be ready
    // instead of silently falling back to an empty value.
    //
    // Use .future when you need the full resolved value:
    final currencies = await ref.watch(currenciesProvider.future);

    // Use .selectAsync when you only need a subset of the resolved value.
    // This avoids rebuilding when unrelated fields change:
    final currencyIds = await ref.watch(
      currenciesProvider.selectAsync((list) => list.map((c) => c.id).toList()),
    );

    // Only use .select (synchronous) for providers whose state is already
    // synchronous (e.g., NotifierProvider, StateProvider).

    // Watch a shared feature provider the same way:
    final sharedData = await ref.watch(featureSharedDataProvider.future);

    return StepOneState(
      items: currencyIds,
      // ... map sharedData fields as needed
    );
  }

  Future<void> onSubmit() async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      // ... perform action
    } finally {
      state = AsyncData(current.copyWith(isSubmitting: false));
    }
  }
}
```

**Key points:**
- `build()` is the single entry point for setup. Declare all `ref.watch` calls here.
- Use `ref.onDispose` inside `build()` to cancel timers, abort controllers, etc.
- Mutations (button actions) are plain `async` methods that update `state` directly.
- Never call `ref.watch` outside of `build()`. Use `ref.read` in action methods.
- Never create or manage UI controllers (ScrollController, TextEditingController, etc) in the ViewModel. These must be owned by the View.
- Never pass or use BuildContext in the ViewModel. All context-dependent logic (dialogs, navigation, snackbars) must be handled in the View.

### 2.2 Context-bound actions — orchestrate in the ViewModel, delegate UI via callbacks + a result

Some actions are multi-step flows where the **business orchestration** belongs in the ViewModel
but individual steps need the View (a PIN prompt, a confirm dialog, a "can operate" check,
navigation, a bottom sheet). Do **not** pass `BuildContext` into the ViewModel to solve this.
Keep the ViewModel context-free and split the flow in two:

- **Mid-flow UI gates** → typed **callbacks** the View passes in. Each returns whether to continue
  (`Future<bool>`) or the data it gathered (`Future<String?>` for a PIN, an event, ...). The
  ViewModel `await`s them and keeps orchestrating.
- **Terminal UI** → a **`sealed` result** the ViewModel returns. The View `switch`es on it and
  performs the final dialog / navigation / toast.

```dart
// ViewModel — owns the sequence, never touches BuildContext
Future<SubmitResult> submit({
  required Future<String?> Function() onRequestPin,             // gate: returns pin or null
  required Future<bool> Function(double amount) onCheckCanOperate,
}) async {
  if (askPin) {
    final pin = await onRequestPin();
    if (pin == null) return SubmitCancelled();
  }
  if (!await onCheckCanOperate(amountToOperate)) return SubmitCancelled();

  final res = await _service.execute(...);
  return res.fold(
    (ok)  => SubmitGoToNextStep(),   // navigation is a View concern -> return the intent as a result
    (err) => SubmitShowError(err),   // terminal UI -> result
  );
}

// View — provides the gate callbacks, switches on the result, performs navigation
final result = await vm.submit(
  onRequestPin: () => _promptPin(context),
  onCheckCanOperate: (a) => _canOperate(context, a),
);
if (!context.mounted) return;
switch (result) {
  case SubmitGoToNextStep(): FeatureFlowNavigator.of(context).goToStepTwo();  // View navigates (see §4.1)
  case SubmitShowError(:final error): showError(_message(error));
  case SubmitCancelled(): break;
}
```

**Notes:**
- **Navigation is never performed from the ViewModel — not even step transitions.** The ViewModel
  returns the navigation *intent* as part of its `sealed` result; the View performs the push/pop
  (see §4.1). The route stack stays the single source of truth for the flow's position.
- The "in progress" flag (disable inputs/buttons) is owned by the ViewModel or a shared step
  provider it writes — never set from the View.
- When a mid-flow page returns an event that drives more logic (e.g. a "waiting" page), have the
  callback return that event and keep processing it in the ViewModel — the View only *shows* the page.

### 2.3 Return semantic results, never user-facing copy

A ViewModel must not decide the **text** the user sees. `S.current.x` works without a
`BuildContext`, so it doesn't break the "no context" rule — but copy, and how to present it
(toast vs. dialog), are presentation concerns that belong to the View. Return a **semantic** type
and let the View map it:

```dart
// ViewModel
sealed class SubmitError {}
class InsufficientFunds extends SubmitError {}
class InternalError extends SubmitError { final String code; InternalError(this.code); }
class BackendError extends SubmitError { final String message; BackendError(this.message); }

// View
String _message(SubmitError e) => switch (e) {
  InsufficientFunds()     => S.current.notEnoughFunds,
  InternalError(:final c) => '${S.current.anErrorHasOccurred} - $c',
  BackendError(:final m)  => m,   // already-localized server message: passthrough
};
```

A backend-provided error message is **data** (passthrough is fine); app copy is **presentation**.
This also keeps the ViewModel testable without localization.

### 2.4 Shared helpers take `Ref`, not `WidgetRef`

A free function that only needs `.read` (option lists, validity checks, derivations) should take
**`Ref`**, not `WidgetRef`. `WidgetRef` is not a subtype of `Ref`, so typing it `WidgetRef` by
habit blocks every ViewModel from calling it. A top-level helper that takes `Ref` and is invoked
**only from ViewModels** is ViewModel logic — *not* a "View reads globals" violation, even if it
reads global providers internally.

---

## 3. View

The View is a `ConsumerWidget` (or `ConsumerStatefulWidget`) that:
- Only imports and watches its own ViewModel provider.
- Never imports global providers.
- Calls ViewModel methods in response to user actions.

```dart
// StepOne_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munchies_time_frontend/pages/FeatureName/steps/stepOne/StepOne_viewmodel.dart';

class StepOneView extends ConsumerWidget {
  const StepOneView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the helper extension for convenience (defined in WidgetRef_extension.dart).
    final (asyncState, notifier) = ref.watchAutoDisposeAsyncNotifier(stepOneViewModelProvider);

    return asyncState.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (state) => Column(
        children: [
          for (final item in state.items) Text(item),
          ElevatedButton(
            onPressed: state.isSubmitting ? null : notifier.onSubmit,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
```

### 3.1 `skipLoadingOnRefresh` / `skipLoadingOnReload` — avoid flicker on refresh

`AsyncValue.when` takes two flags that control whether the **loading** branch is shown while
the provider is re-fetching but **already has a previous value**:

| Flag                      | Default | Effect when `true`                                                                 |
|---------------------------|---------|------------------------------------------------------------------------------------|
| `skipLoadingOnRefresh`    | `true`  | On an explicit **refresh** (`ref.invalidate` / `ref.refresh` / `invalidateSelf`), keep showing the previous `data` instead of routing to `loading`. |
| `skipLoadingOnReload`     | `false` | On a **reload** (a watched dependency changed and `build()` re-runs), keep showing the previous `data` instead of routing to `loading`. |

The distinction is the trigger: a **refresh** is an explicit invalidation; a **reload** is a
rebuild caused by a watched dependency changing. Both leave the `AsyncValue` in a loading
state that still carries the old value — these flags decide whether `when` surfaces that as
`data` (smooth) or `loading` (a skeleton/spinner flash).

On a composed dashboard (§9), pull-to-refresh (§8) re-fetches many widgets at once; without
these flags every widget would flash its loading state. The convention is to set **both**
`true` so the widget keeps rendering its last data during refresh/reload:

```dart
return state.when(
  skipLoadingOnRefresh: true,
  skipLoadingOnReload: true,
  data: (orders) => OrdersCarousel(orders: orders),
  loading: () => const OrdersSkeleton(),     // only on the FIRST load (no previous value)
  error: (e, _) => const SizedBox.shrink(),
);
```

**Notes:**
- These flags only matter when a **previous value exists**. The very first load (no data yet)
  always shows `loading`, regardless of the flags.
- `skipLoadingOnRefresh` already defaults to `true`; setting it explicitly is just for clarity.
  The meaningful opt-in is `skipLoadingOnReload: true`.
- Combine with a cached fallback when you want a value during the *first* load too: a widget can
  render a cached value in its `loading` branch (e.g. `TotalBalance` shows a cached balance while
  the real one loads) — that is a separate technique from these flags.

### 3.2 ViewModel lifecycle calls & `ref` in `dispose()`

`ref` is **invalid in `dispose()`** — `ref.read(...)` there throws *"Cannot use ref after the
widget was disposed"*. For fire-and-forget lifecycle calls (e.g. `logViewed` / `logAbandoned`),
capture the notifier in `initState` and call the captured reference in `dispose()`:

```dart
late final FooViewModel _vm;

@override
void initState() {
  super.initState();
  _vm = ref.read(fooViewModel.notifier);   // ref.read is allowed in initState
}

@override
void dispose() {
  _vm.logAbandoned();   // safe: the method uses analytics, not ref
  super.dispose();
}
```

**Do not** use the ViewModel's `ref.onDispose` for "screen abandoned" analytics: an
`AutoDisposeAsyncNotifier`'s `build()` re-runs whenever a watched dependency changes, so its
`onDispose` callbacks fire on **every recompute**, not only when the screen is left. The widget's
`dispose()` fires exactly once. Tie a lifecycle event to whichever lifecycle actually matches it.

---

## 4. Feature-Level Shared Provider

When multiple steps within a feature need the same data (e.g., a flow with 3 steps that all need the same remote resource), extract it into a shared provider under `providers/`.

```dart
// lib/pages/FeatureName/providers/FeatureSharedData_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

final featureSharedDataProvider =
    AutoDisposeAsyncNotifierProvider<FeatureSharedDataNotifier, FeatureSharedData>(
  FeatureSharedDataNotifier.new,
);

class FeatureSharedDataNotifier extends AutoDisposeAsyncNotifier<FeatureSharedData> {
  @override
  Future<FeatureSharedData> build() async {
    // Fetch once, shared by all steps that watch this provider.
    final client = serviceLocator<ApiClient>().someService;
    final res = await client.getData();
    return res.fold((success) => success.data, (error) => throw error);
  }
}
```

Each step's ViewModel watches this provider instead of calling the API independently:

```dart
// Inside StepTwoViewModel.build()
final sharedData = await ref.watch(featureSharedDataProvider.future);
```

Because the provider is `autoDispose`, it stays alive as long as at least one ViewModel is watching it, and is disposed when the feature is closed.

### 4.1 Step navigation lives in the View — use a flow Navigator, not a steps provider

> **Do not model the flow's position as Riverpod state.** A `FeatureSteps_provider` with
> `nextStep` / `previousStep` / `goToStep` is an **anti-pattern**: navigation is a View concern
> (see Core Rules), and a step enum in a provider duplicates what a `Navigator` already tracks —
> the route stack — while fighting the system back button and the back-swipe gesture. Host the
> flow on a nested `Navigator` and let steps navigate themselves.

Two shared widgets host an in-page flow on a nested `Navigator`; both wire the system/predictive
back button and keep the stack in sync. Pick by whether the flow's shape is driven by state:

| Widget | File | Model | Use when |
|--------|------|-------|----------|
| `SimpleFlowBuilder` | `lib/widgets/simple_flow_builder.dart` | **Imperative** — steps `push`/`pop` on `Navigator.of(context)`; no flow-state object. Each step gets a `CupertinoPageRoute` (slide + back-swipe). | **Default.** Steps go forward/back and the position need not be modeled as data. |
| `FlowBuilder<T>` | `lib/widgets/flow_builder.dart` | **Declarative** — a flow-state `T` drives `onGeneratePages`; `context.flow<T>().update/complete` recompute the page list. | The *set/order* of pages is a function of state (conditional/optional steps, jumping back to edit an earlier step, completing the flow with a result `T`). |

Reach for the imperative `SimpleFlowBuilder` by default; choose `FlowBuilder` only when a
flow-state object genuinely drives which pages exist.

The feature wraps its chosen widget in a small `FeatureNameNavigator` (View layer, **zero Riverpod
for navigation**) that also exposes a thin, context-based push/pop API, so steps never construct
routes inline:

```dart
// FeatureNameNavigator.dart
import 'package:flutter/cupertino.dart';
import 'package:munchies_time_frontend/widgets/simple_flow_builder.dart';

class FeatureNameNavigator extends StatelessWidget {
  const FeatureNameNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleFlowBuilder(
      rootBuilder: (_) => const StepOneView(),
    );
  }
}

/// The flow's navigation API. Steps call `FeatureFlowNavigator.of(context).goToStepTwo()`
/// instead of building routes by hand — the only place route construction lives.
class FeatureFlowNavigator {
  const FeatureFlowNavigator(this.navigator);
  factory FeatureFlowNavigator.of(BuildContext context) => FeatureFlowNavigator(Navigator.of(context));

  final NavigatorState navigator;

  void goToStepTwo() => navigator.push(CupertinoPageRoute(builder: (_) => const StepTwoView()));
  void back() => navigator.pop();
  void backToFirstStep() => navigator.popUntil((r) => r.isFirst);
}
```

> **Driving the stack from the host** (e.g. reset to the first step when some global state clears):
> make `FeatureNameNavigator` a `ConsumerStatefulWidget`, hold a `GlobalKey<NavigatorState>`, pass
> it to `SimpleFlowBuilder.navigatorKey`, and `ref.listen` the relevant provider to call
> `key.currentState?.popUntil((r) => r.isFirst)`. The key is a plain View object, not Riverpod.

> **Reference implementation (target):** the Create Recipe flow — a `CreateRecipeNavigator`
> (the host + a `CreateRecipeFlowNavigator` API) composing `SimpleFlowBuilder`, with each step
> (details → ingredients → preparation) pushing/popping itself.

**When a step must be reachable on its own, give it a real route instead of nesting it.** The nested
flow `Navigator` (the widgets above) is for steps that only exist *inside* the flow and have no
meaning as standalone destinations. If a screen must be **independently addressable** — a deep
link, a route the user can open directly, or a destination shared with other features — give it its
own self-contained route file and navigate via that route's typed `push`/`go` helper (§6.1), still
from the **View**, never a ViewModel (see §2.2). A single flow routinely mixes both: keep flow-only
steps on the nested `Navigator`, and hand off to a real route at the point the user leaves the flow
for an addressable screen — e.g. the Create Recipe flow keeps its details / ingredients /
preparation steps nested, then hands off to the recipe-detail route once the recipe is saved.

| Use the nested flow `Navigator` (`SimpleFlowBuilder` / `FlowBuilder`) when... | Use `go_router` named routes when... |
|-------------------------------------------------------------------------------|--------------------------------------|
| The step only exists inside this flow and is meaningless on its own           | The step must be deep-linkable / openable directly by URL or name |
| You want flow-local back/swipe and a stack that resets with the flow          | The destination is shared with or reachable from other features |
| Steps are sequential and private to the feature                               | The user leaves the flow for a standalone screen (recipe detail, etc.) |

### 4.2 App-wide shared providers (consumed by multiple features)

§4 covers providers shared *within* one feature (they live in `feature/providers/`). When **two or
more features** need the **same derived data or workflow** — rather than each recomputing or
re-fetching it by hand — extract a single **app-wide provider** into `lib/providers/` instead. The
canonical case: the consolidated shopping list, derived from the current meal plan and consumed by
both the Market page and a summary widget on Home.

Shape it as a thin primitive that owns the workflow, ideally an
`AutoDisposeAsyncNotifierProvider.family` keyed by the input it derives from, exposing build +
refresh + the mutations it owns:

```dart
// lib/providers/shopping_list/shopping_list_provider.dart

final shoppingListProvider = AutoDisposeAsyncNotifierProvider.family<
    ShoppingListNotifier, ShoppingList, MealPlan>(
  ShoppingListNotifier.new,
);

class ShoppingListNotifier extends AutoDisposeFamilyAsyncNotifier<ShoppingList, MealPlan> {
  @override
  Future<ShoppingList> build(MealPlan plan) async {
    // owns: resolve the plan's recipes + foods, then run the domain calculator
  }

  Future<void> refresh() async { /* invalidateSelf guard (see §8.2 Case A) */ }

  void togglePurchased(String foodId) { /* ... */ }
}
```

Each feature keeps its **own** ViewModel that wraps this provider and adds the feature-specific
concerns — analytics, filtering, reactive inputs, presentation options, etc. The shared
provider stays dumb.

**Keep it a faithful primitive — but normalize an inconsistent API shape here, not in the DTO.**
If the API returns an awkward shape (e.g. a top-level entity *plus* a nested list that is empty in
some cases), normalize it in this provider's `build` (return the list, always non-empty) rather than
reshaping the shared DTO. The DTO is used by many other call sites — leave it intact and fix the
shape at the provider boundary.

### 4.3 Location follows scope — never invert the dependency direction

A provider lives at the level of its **widest consumer**. If a feature-global provider (e.g. the
quote) is a pure function of some inputs (currencies, amount), those inputs are **also**
feature-global and live in `providers/` — not nested under one step's folder. Otherwise the
feature-global provider depends *into* a step, inverting the dependency graph (the broad layer
points at the narrow one).

Group related inputs in a **neutral sibling folder by role** (`providers/inputs/`), never under a
consumer's folder (`providers/quote/inputs/`), which would re-create the same scope inversion one
level down — the inputs are *peers* of the quote provider, not its children.

---

## 5. Multi-Step Page Orchestrator

The page entry point gates the **global data every step needs** through its ViewModel, then hands
off to the flow Navigator (§4.1). It does **not** choose or switch steps — the `Navigator` owns the
stack and steps push/pop themselves. The page ViewModel therefore returns `void` (it only gates),
never a "current step".

```dart
// FeatureNamePage_viewmodel.dart — gates global data; owns NO step state

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munchies_time_frontend/pages/FeatureName/providers/FeatureSharedData_provider.dart';

final featureNamePageViewModelProvider =
    AutoDisposeAsyncNotifierProvider<FeatureNamePageViewModel, void>(
  FeatureNamePageViewModel.new,
);

class FeatureNamePageViewModel extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Surface loading/error for the data the steps depend on.
    await ref.watch(featureSharedDataProvider.future);
  }

  Future<void> retry() async {
    await ref.read(featureSharedDataProvider.notifier).refresh();
  }
}
```

```dart
// FeatureNamePage.dart — gates on the ViewModel, then hosts the flow Navigator (§4.1)

class FeatureNamePage extends ConsumerWidget {
  const FeatureNamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (gateAsync, vm) = ref.watchAutoDisposeAsyncNotifier(featureNamePageViewModelProvider);

    return gateAsync.when(
      skipLoadingOnReload: true,
      data: (_) => const FeatureNameNavigator(),                 // the flow Navigator owns the stack
      loading: () => const Scaffold(body: CircularProgressIndicator()),
      error: (_, __) => Scaffold(body: ErrorBody(onRetry: vm.retry)),
    );
  }
}
```

Steps then advance by **navigating**, not by mutating step state. When a step's action needs
business orchestration, the ViewModel returns a `sealed` result and the View performs the
navigation (§2.2):

```dart
// StepOne_view.dart — the View navigates on the ViewModel's result
final result = await notifier.submit(/* gate callbacks */);
if (!context.mounted) return;
switch (result) {
  case SubmitGoToStepTwo(): FeatureFlowNavigator.of(context).goToStepTwo();
  case SubmitShowError(:final error): showError(_message(error));
  case SubmitHandled(): break;
}
```

### 5.1 Resolving mandatory reference data once at the root

When **many** steps and inner widgets all need the same already-loaded reference
data — currencies, payment methods, remote configs, the user profile — do **not**
make each ViewModel read the async global with `.valueOrNull ?? <fallback>` (the
§2.1 anti-pattern: every read silently renders empty while loading, scattered across
the feature). Instead, **gate all of it once at the root** and expose **synchronous,
guaranteed-present "safe" providers** that the rest of the feature reads.

**1. The page orchestrator awaits every mandatory source** (extends the §5 gate
beyond a single shared provider), so nothing renders until all of it is loaded:

```dart
Future<void> build() async {
  final (currencies, paymentMethods, configs, profile) = await (
    ref.watch(enabledCurrenciesProvider.future),
    ref.watch(enabledPaymentMethodsProvider.future),
    ref.watch(currentConfigsProvider.future),
    ref.watch(userProfileProvider.future),
  ).wait;                                       // record-.wait → parallel
  if (currencies.isEmpty || paymentMethods.isEmpty) throw Exception('...'); // mandatory
}
```

**2. Expose each as a synchronous derived provider** in `providers/`, reading the
global's resolved value via `.requireValue`:

```dart
// providers/FeatureMandatoryData_provider.dart
final featureCurrentConfigsProvider =
    Provider<CurrentConfigs>((ref) => ref.watch(currentConfigsProvider).requireValue);
```

Downstream ViewModels read a **plain value** — no `AsyncValue`, no `.valueOrNull`, no
fallback: `ref.watch(featureCurrentConfigsProvider).someField`. Because the root
gated the source, `.requireValue` always succeeds; if it is ever read before load it
**throws loudly** instead of silently going empty — which is the behavior you want.

**Why derived `.requireValue`, not `ProviderScope(overrides:)`.** It is tempting to
gate, then inject the resolved values with
`ProviderScope(overrides: [p.overrideWithValue(v)])`. Avoid that when the feature
presents **bottom sheets / dialogs on the root navigator**: those mount *outside* any
`ProviderScope` wrapped around the flow, so the override is not in scope there and the
provider throws. Top-level derived providers have no scope boundary — they work
everywhere, including root-navigator sheets — and stay **reactive**: a new source
value propagates through the `ref.watch` straight to consumers.

**This is also what lets a synchronous `AutoDisposeNotifier` consume "async" global
data** (§2.1): the data is resolved by the time the sync `build()` runs, so it reads
the safe provider directly instead of being forced into an `AutoDisposeAsyncNotifier`
just to `await` data that is already present.

**Scope it to genuinely static reference data.** Live/refreshing or non-essential
data (a quote that expires, prices that tick, an optional banner config) stays an
`AsyncValue` the consumer handles — do not force it through a safe provider.

> **Reference implementation (target):** the Create Recipe flow — a
> `CreateRecipeMandatoryData_provider.dart` (the `.requireValue`-derived safe providers, e.g. the
> food catalog every step needs) gated by the page's ViewModel.

---

## 6. Feature Argument Overrides (no parameter drilling)

Route-level arguments a feature is opened with — an `orderId`, a parsed query-param
object, a `mode` — should be injected **once at the feature entry** via a
`ProviderScope` override, never drilled through every step's widget constructor.
Define a throwable (required) or default-valued `Provider` for the argument, override
it where the feature is mounted (the route builder), and let any ViewModel read it
directly. §7 covers the mechanics and when to prefer this over a `provider.family`.

> **Reference implementation (target):** the Recipe Detail page — a `recipeDetailArgsProvider`
> (`providers/recipe_detail_args_provider.dart`), overridden in the route's `builder` with the
> recipe id and read by the page's ViewModel, so the View constructors no longer carry the id.

### 6.1 Self-contained route files (typed navigation)

**The point of this is typed navigation: the compiler enforces a route's arguments at the
call site.** When you go to a route you call its typed helper —
`FeatureNamePageRoute.push(context, params: FeatureParams(...))` — and the type system tells
you exactly what that route *requires* and what it *accepts*. A required params object can't
be omitted; an unknown field won't compile; renaming a param breaks every caller at build
time instead of failing silently at runtime. This is what a raw `context.push('/feature',
extra: someMap)` can never give you — the path is a magic string and `extra` is an untyped
`Object?` nobody validates.

To get that, a top-level, independently-addressable page **defines its own route** in a
`<Feature>Page_route.dart` next to the page — the route is not an inline `AppRoute(...)`
literal in `lib/routes/Routes.dart`, and there is **no string constant on `AppRoutes`**.
The feature owns one typed route class that:

- declares its `path` as a `static const`;
- builds its `AppRoute` in a `route()` method, setting `accessLevelNeeded`;
- exposes typed `push` / `go` helpers — the **only** sanctioned way to navigate to the
  page. Callers pass a typed params object, never a raw path string + untyped `extra`.

The normal case is a single route — `path` and the helpers are all `static`, so you navigate
with `FeatureNamePageRoute.push(...)` / `.go(...)` without ever instantiating the class:

```dart
// lib/pages/FeatureName/FeatureNamePage_route.dart

class FeatureNamePageRoute {
  const FeatureNamePageRoute._();

  static const path = '/feature';

  static AppRoute route() => AppRoute(
        path: path,
        builder: (context, state) => const FeatureNamePage(),
        accessLevelNeeded: const AllAccess(),
      );

  static Future<void> push(BuildContext context, {required FeatureParams params}) =>
      context.push(path, extra: params);

  static void go(BuildContext context, {required FeatureParams params}) =>
      context.go(path, extra: params);
}
```

`lib/routes/Routes.dart` only **aggregates** these into `AppRoutes.config` — it holds no
route body, builder, or path string of its own:

```dart
// lib/routes/Routes.dart — collection only
static List<RouteBase> config = [
  FeatureNamePageRoute.route(),
  // ...other feature routes
];
```

Navigate to the page with the typed helper, from the **View** (never a ViewModel — §2.2):

```dart
FeatureNamePageRoute.push(context, params: FeatureParams(...));
```

**Make the helper signature mirror the route's real contract** — that is the whole payoff.
If the page cannot function without an argument, type it as **required** (`required
FeatureParams params`) so a caller that forgets it does not compile; keep it nullable only
when the route genuinely has a default. A single typed `params` object beats a long list of
loose named parameters: add a field and every call site is checked, not silently skipped.

**Multiple entry points → named variants.** Only when one page is mounted at more than one
path (e.g. an embedded `home` tab vs. a `fullScreen` deep-link entry) make the variants
**instances** with a private constructor, and navigate through the chosen one —
`FeatureNamePageRoute.fullScreen.push(...)`:

```dart
class FeatureNamePageRoute {
  const FeatureNamePageRoute._({required this.path, required this.isFullScreen});

  final String path;
  final bool isFullScreen;

  static const home = FeatureNamePageRoute._(path: '/home/feature', isFullScreen: false);
  static const fullScreen = FeatureNamePageRoute._(path: '/feature', isFullScreen: true);

  AppRoute route() => AppRoute(
        path: path,
        builder: (context, state) => FeatureNamePage(isFullScreen: isFullScreen),
        accessLevelNeeded: const AllAccess(),
      );

  Future<void> push(BuildContext context, {required FeatureParams params}) =>
      context.push(path, extra: params);
}
// Routes.dart aggregates each variant: FeatureNamePageRoute.home.route(), .fullScreen.route()
```

> **Reference implementation (target):** a `RecipesPageRoute` — a two-entry-point page using the
> `home` / `fullScreen` variant form, with a `route()` builder and `push`/`go` helpers;
> aggregated in `Routes.dart` via `RecipesPageRoute.home.route()` / `.fullScreen.route()`.

---

## 7. ProviderScope Overrides vs. Provider.family

There are two main ways to pass arguments to providers in Riverpod:

1. **ProviderScope overrides** (see previous section):
   - Best for arguments that are constant for the whole feature (e.g., `featureId`, `mode`, `accountId`).
   - All ViewModels/providers in the subtree can read the same value without parameter drilling.
   - Works well for navigation/route arguments.

2. **Provider.family**:
   - Best for arguments that change per instance or are dynamic (e.g., itemId in a list, dialog for a specific entity).
   - Use when you need multiple independent instances of the same provider with different arguments.
   - Not ideal for global feature arguments, as you would have to pass the argument to every `.watch()` call.

### Example: Using family for dynamic instances

```dart
final itemDetailsProvider = AutoDisposeAsyncNotifierProvider.family<ItemDetailsNotifier, ItemDetails, String>(
  ItemDetailsNotifier.new,
);

class ItemDetailsNotifier extends AutoDisposeFamilyAsyncNotifier<ItemDetails, String> {
  @override
  Future<ItemDetails> build(String itemId) async {
    // Fetch details for this itemId
    return await fetchItemDetails(itemId);
  }
}

// Usage in a widget:
final (itemAsync, notifier) = ref.watchAutoDisposeAsyncNotifier(itemDetailsProvider(itemId));
```

> **The family argument must be `Equatable`.** Riverpod dedupes provider instances by the
> argument's `==` / `hashCode`. A `String` or `int` key is fine. If you key by an **object**
> (e.g. a request schema), that object **and every nested field it holds** must implement value
> equality — otherwise two equivalent arguments are treated as different keys, you spin up a new
> instance (and a new network call) each time, and the cache never hits. Watch for nested objects
> that silently fall back to identity equality.

### When to use each

| Use ProviderScope override when... | Use provider.family when... |
|------------------------------------|----------------------------|
| The argument is global to the feature (e.g., orderId, accountId, mode) | You need multiple instances with different arguments (e.g., itemId in a list) |
| You want to avoid passing the same argument through every widget/provider | The argument is not known at feature entry, or is dynamic per instance |
| The argument is set at navigation/route time | You want to scope state to a specific entity, dialog, or sub-flow |

**Rule of thumb:**
- Use ProviderScope overrides for feature-wide, route-level arguments.
- Use provider.family for dynamic, per-instance arguments.

When a feature depends on route arguments (for example `featureId`, `orderId`, `accountId`), inject them once at the feature entry point with `ProviderScope` overrides.

This avoids passing IDs through constructors across all steps and ViewModels.

```dart
// lib/pages/FeatureName/providers/FeatureArgs_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

final featureIdProvider = Provider<String>((ref) {
  throw UnimplementedError('featureIdProvider must be overridden at Feature entry');
});

final featureModeProvider = Provider<FeatureMode>((ref) {
  return FeatureMode.defaultMode;
});
```

```dart
// lib/pages/FeatureName/FeatureNameRoute.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munchies_time_frontend/pages/FeatureName/FeatureNamePage.dart';
import 'package:munchies_time_frontend/pages/FeatureName/providers/FeatureArgs_provider.dart';

class FeatureNameRoute extends StatelessWidget {
  final String featureId;
  final FeatureMode mode;

  const FeatureNameRoute({
    super.key,
    required this.featureId,
    this.mode = FeatureMode.defaultMode,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        featureIdProvider.overrideWithValue(featureId),
        featureModeProvider.overrideWithValue(mode),
      ],
      child: const FeatureNamePage(),
    );
  }
}
```

Then any feature-scoped ViewModel/provider reads those values directly:

```dart
// Inside any Feature ViewModel build()
@override
Future<StepOneState> build() async {
  final featureId = ref.watch(featureIdProvider);
  final mode = ref.watch(featureModeProvider);

  final data = await ref.watch(
    featureSharedDataProvider.selectAsync((d) => d.byId(featureId)),
  );

  return StepOneState(
    items: data.itemsForMode(mode),
  );
}
```

Recommended rule:
- Route arguments needed by multiple providers/ViewModels must be injected through feature-level overrides.
- Do not pass the same ID through multiple widget constructors unless it is strictly local UI state.

---

## 8. Pull-to-Refresh (`refresh()` pattern)

When a page is composed of many independent widgets (a dashboard-style page where each
widget has its own View + ViewModel + State — see §9), pull-to-refresh is coordinated by the
**parent page**, but each widget owns *how* its own data is refreshed.

### 8.1 Each widget exposes a `static refresh(WidgetRef ref)`

Every refreshable widget exposes a static `refresh` that delegates to its ViewModel.
The parent page aggregates them all inside the `RefreshIndicator`.

```dart
// In each widget:
class TotalBalance extends ConsumerWidget {
  const TotalBalance({super.key});

  static Future<void> refresh(WidgetRef ref) async {
    await ref.read(totalBalanceViewModel.notifier).refresh();
  }
  // ...
}

// In the parent page:
RefreshIndicator(
  onRefresh: () async {
    await Future.wait([
      TotalBalance.refresh(ref),
      MainButtons.refresh(ref),
      OnboardingStepsCard.refresh(ref),
      // ...one entry per widget
    ]);
  },
  child: ListView(/* ...the widgets... */),
)
```

The parent never reaches into a widget's ViewModel — it only calls the widget's public
`static refresh`. This keeps each widget self-contained.

### 8.2 How to implement the ViewModel's `refresh()` — by data ownership

The implementation depends on **who owns the data being refreshed**, not on the kind of
dependency. Decide with this rule:

**Case A — the ViewModel owns the data** (it fetches directly from a service inside its
own `build()`). The data only lives in this ViewModel's `build()`, so the only way to
re-fetch is to re-run `build()` via `invalidateSelf()`. Add a re-entrancy guard so two
quick pulls don't overlap.

```dart
class ArticlesCarouselViewModel extends AutoDisposeAsyncNotifier<List<BlogPost>?> {
  @override
  Future<List<BlogPost>?> build() async {
    final client = serviceLocator<ApiClient>().others;   // owns the fetch
    final res = await client.getBlogPosts(/* ... */);
    return res.fold((s) => s.data, (e) => throw e);
  }

  Future<void> refresh() async {
    // Re-entrancy guard: if a refresh is already in flight, just await it.
    if (state.isLoading || state.isRefreshing || state.isReloading) {
      await future;
      return;
    }

    try {
      ref.invalidateSelf();
      await future.safe;
    } catch (error) {
      debugPrint('Error refreshing ArticlesCarousel: $error');
    }
  }
}
```

> Mixed case: a ViewModel may also `watch` some globals as *inputs/filters*
> (e.g. `userProfileProvider`, `localeProviderRP`) while still owning the primary data.
> Classify it by the data the pull-to-refresh is meant to update. ArticlesCarousel watches
> globals but uses `invalidateSelf()` because the data it owns is the blog posts — it is not
> this widget's job to refresh the profile or locale.

**Case B — the data lives in global providers the ViewModel `watch`es.** Here
`invalidateSelf()` is useless: re-running `build()` just re-reads the globals, which still
hold their **cached** values → a no-op "phantom" refresh with no network call. You must
refresh each global the ViewModel depends on; the change then propagates and rebuilds the
ViewModel automatically.

```dart
class OnboardingstepsCardViewModel extends AutoDisposeAsyncNotifier<OnboardingstepsCardState> {
  @override
  Future<OnboardingstepsCardState> build() async {
    // Data is owned by these globals, not by this ViewModel.
    final monthAllowanceUsd = await ref.watch(allowanceProvider.selectAsync((e) => e.monthAllowanceUsd));
    final nextKycStatus = await ref.watch(userProfileProvider.selectAsync((e) => e.nextKycStatus));
    // ...
  }

  Future<void> refresh() async {
    final container = ref.container; // see 8.3 — required
    await Future.wait([
      container.read(allowanceProvider.notifier).refresh(),
      container.read(userProfileProvider.notifier).refresh(),
    ]);
  }
}
```

### 8.3 Why Case B must use `ref.container` (the `_didChangeDependency` assertion)

In Case B the ViewModel `watch`es in `build()` the same providers its `refresh()` is about
to refresh. Refreshing a watched provider marks the ViewModel's element as
"dependency changed", and **schedules** its rebuild (it has not rebuilt yet). Using a `ref`
function (`ref.read` / `ref.watch`) in that window throws:

```
'!_didChangeDependency': Cannot use ref functions after the dependency
of a provider changed but before the provider rebuilt
```

`ref.container` returns the **root `ProviderContainer`**. `container.read(...)` does **not**
go through the element-level guard, so it is safe inside that window. Capture it once at the
top of the method and read everything through it.

> This is *not* a dispose issue. It is specifically the dependency-changed-but-not-yet-rebuilt
> guard, and it applies to a ViewModel that refreshes providers it watches.

> **Not refresh-specific.** The same guard fires for **any** action method that uses a `ref`
> function after a watched `build()` dependency changed mid-flight — not only `refresh()`.
> The canonical non-refresh example: a `submit()` whose `build()` watches a live, auto-refreshing
> provider. Picture a "Save" button whose `build()` watches such a provider; if it ticks
> while the user is mid-submit, the element is flagged
> dependency-changed and the next `ref.read` in `submit` throws. Same fix — capture
> `final container = ref.container` (or a `_container` getter) and route the action's reads
> through it.

### 8.4 `Future.wait` does **not** remove the need for `ref.container`

It is tempting to think that, because `Future.wait` evaluates all `ref.read(...)` calls
synchronously up-front (before the first `await`), the dependency cannot have changed yet,
so plain `ref` is safe. That only holds if **no** refreshed provider emits state
synchronously. If any `refresh()` does `state = const AsyncValue.loading();` before its
first `await`, the watched dependency flips **during list construction**, and the next
`ref.read(...)` in the list still hits the assertion.

So `ref.container` is required regardless of sequential vs. parallel:

- **Independent refreshes** → `Future.wait` over `container.read(...)` calls (parallel + safe).
- **Order-dependent refreshes** (e.g. `kycNextLevelProvider` depends on the others) → sequential
  `await container.read(...)` calls. See `KYCPage_viewmodel.dart`.

`Future.wait` is about *parallelism*; `ref.container` is about *avoiding the guard*. They are
orthogonal — use `Future.wait` when refreshes are independent, but always read through
`ref.container`.

---

## 9. Composed Page (dashboard-style, no steps)

Not every feature is a step flow. Many pages are a **composition of independent,
self-contained widgets** stacked in a scroll view. The **Home page** is the canonical
example: `TotalBalance`, `MainButtons`, `CardBalanceCard`, `OnboardingStepsCard`,
`BannersCarousel`, etc., each living side by side.

The defining property is **isolation**: every widget is its own MVVM triad
(View + ViewModel + State) and owns its own data, loading, error, and refresh. Adding or
removing a widget from the dashboard is a localized change — the page just lists it (and its
`refresh`). One widget failing must never break the others.

### 9.1 The page widget = layout only

Use a `ConsumerStatefulWidget` when the page owns UI controllers (e.g. a `ScrollController`),
otherwise a `ConsumerWidget`. The page:

- builds the `Scaffold` / app bar / background,
- lays out the child widgets in a scroll view,
- **owns the UI controllers** (the `ScrollController` lives here, never in a ViewModel — see Core Rules),
- aggregates each child's `static refresh` inside a `RefreshIndicator` (see §8.1),
- triggers post-first-frame effects through a layout mixin (`afterFirstLayout`).

```dart
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with ALMixin<HomePage> {
  late final ScrollController scrollController; // UI controller owned by the View

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    ref.read(homePageViewModel.notifier).onSetNavigatorVisibility(true);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            TotalBalance.refresh(ref),
            MainButtons.refresh(ref),
            // ...one entry per child widget
          ]);
        },
        child: ListView(
          controller: scrollController,
          children: const [
            TotalBalance(),
            MainButtons(),
            // ...the composed widgets
          ],
        ),
      ),
    );
  }
}
```

### 9.2 The page-level ViewModel is thin

The page ViewModel holds **only page-wide concerns** that do not belong to any single child
widget — for Home, that is toggling the bottom-navigator visibility. It is frequently an
`AutoDisposeNotifier<void>` (no state to expose). It does **not** aggregate the child
ViewModels; each child owns its own.

```dart
class HomePageViewModel extends AutoDisposeNotifier<void> {
  @override
  void build() {}

  void onSetNavigatorVisibility(bool isVisible) {
    ref.read(homePageNavigatorVisibilityViewModel.notifier).setVisibility(isVisible);
  }
}

final homePageViewModel = AutoDisposeNotifierProvider<HomePageViewModel, void>(
  HomePageViewModel.new,
);
```

### 9.3 Each child widget is self-contained

Every widget under `widgets/` is a complete MVVM unit and follows the same §1–§3 rules. In a
composed page they additionally:

- **Decide their own visibility.** A widget returns `const SizedBox.shrink()` when it has
  nothing to render (feature disabled, empty data). See `KycStatusBanner`, `OnboardingStepsCard`.
- **Fail silently when non-essential.** Loading and error states collapse to
  `const SizedBox.shrink()` rather than surfacing an error, so one widget's failure never
  breaks the dashboard. See `RecentOrdersCarousel`, `ArticlesCarousel`.
- **Refresh themselves** through their `static refresh` (see §8).
- **Stay opaque to the page.** The page only calls a widget's public `static refresh` / `show`;
  it never reaches into the widget's ViewModel or state.

```dart
class RecentOrdersCarousel extends ConsumerWidget {
  const RecentOrdersCarousel({super.key});

  static Future<void> refresh(WidgetRef ref) async {
    await ref.read(recentOrdersCarouselViewModel.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recentOrdersCarouselViewModel);

    return state.when(
      data: (s) => /* render the carousel, or SizedBox.shrink() if empty/disabled */,
      // Non-essential: never surface loading/error on the dashboard.
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

> Essential vs. non-essential is a deliberate per-widget choice. A core widget (e.g. the
> total balance) may render an explicit error/loading state; a peripheral one (carousels,
> banners) collapses silently. Decide per widget what the user should see when its data is
> missing.

---

## Summary Table

| Layer              | Class type                              | Imports global providers? | Imports ViewModel? |
|--------------------|-----------------------------------------|---------------------------|--------------------|
| **View**           | `ConsumerWidget`                        | No                        | Yes (only its own) |
| **ViewModel**      | `AutoDisposeAsyncNotifier<State>` if `build()` awaits, else `AutoDisposeNotifier<State>` (see §2.1) | Yes | N/A |
| **Feature provider** | `AutoDisposeAsyncNotifier<Data>`      | Yes                       | N/A                |
| **Global provider** | `AsyncNotifier` / `AutoDisposeAsyncNotifier` | Yes                  | N/A                |

---

## Anti-Patterns to Avoid

- **View watches a global provider directly.** Pass data through the ViewModel instead.
- **ViewModel calls `ref.watch` inside an action method (not `build`).** Use `ref.read` in action methods.
- **Using `AsyncNotifier` instead of `AutoDisposeAsyncNotifier` for page-scoped ViewModels.** Always use the auto-dispose variant so resources are freed when the page is popped.
- **Duplicating API calls across steps** when a feature-level shared provider would suffice.
- **Calling `invalidateSelf()` to refresh data that lives in watched global providers** (Case B). It only re-reads the cached values — a phantom refresh with no network call. Refresh each global instead (see §8.2).
- **Using plain `ref` (`ref.read` / `ref.watch`) to refresh providers the ViewModel watches — or in any action method while a watched `build()` dependency changes mid-flight.** It throws the `_didChangeDependency` assertion. Capture `final container = ref.container` and read through it (see §8.3; not refresh-specific — applies to a `submit()` whose `build()` watches a live provider too). `Future.wait` does not make this safe (see §8.4).
- **Passing `BuildContext` into a ViewModel to run a multi-step action.** Keep the ViewModel context-free; delegate mid-flow UI gates via callbacks and return a `sealed` result the View handles (see §2.2).
- **Returning user-facing strings (`S.current.x`) from a ViewModel.** Return a semantic result/error; the View maps it to copy and decides how to show it (see §2.3).
- **Typing a read-only helper `WidgetRef`.** If it only `.read`s, type it `Ref` so ViewModels can call it too (see §2.4).
- **Using `ref` in `dispose()`** (throws "Cannot use ref after the widget was disposed"). Capture the notifier in `initState` and call the captured reference (see §3.2).
- **A feature-global provider depending on a step-nested provider** — inverts the dependency graph; the inputs are feature-global too (see §4.3).
- **Modeling flow/step position as Riverpod state** (a `FeatureSteps_provider` with `nextStep` / `goToStep`). Navigation is a View concern: host the flow with `SimpleFlowBuilder` (imperative, default) or `FlowBuilder` (declarative) and let steps push/pop on the `Navigator`. The route stack — not a provider — is the source of truth for flow position (see §4.1, §5).
- **Navigating from a ViewModel** (calling `Navigator`, `context.go`, or a steps notifier). Return a navigation intent as a `sealed` result and let the View perform it (see §2.2).
