# Widget / View Conventions

This document collects **View-level UI conventions** used across the app that are *not*
strictly part of the MVVM pattern (see [mvvm_riverpod_pattern.md](./mvvm_riverpod_pattern.md)
for state/ViewModel rules). These are conventions about how widgets expose and trigger
UI-only behavior such as opening sheets, dialogs, and full-screen routes.

---

## 1. `static Future<void> show(BuildContext context)` for sheets, dialogs and modal routes

Any widget that is meant to be presented modally (bottom sheet, dialog, or a pushed
full-screen page) exposes a **`static show`** method that fully encapsulates *how* it is
presented. Callers never build the route, sheet, or `showDialog`/`showModalBottomSheet`
boilerplate themselves — they just call `Widget.show(context)`.

**Why:**
- The presentation details (root navigator, sheet config, transition) live next to the
  widget that owns them, not scattered across every call site.
- Call sites stay a single, intention-revealing line.
- Refactoring how the widget is shown (sheet → dialog, etc.) touches one place.

### Example — bottom sheet

```dart
class TotalBalanceBreakdownSheet extends ConsumerWidget {
  const TotalBalanceBreakdownSheet({super.key});

  static Future<void> show(BuildContext context) async {
    return showEDBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (context, state) => const TotalBalanceBreakdownSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ...
  }
}
```

### Example — pushed full-screen route

```dart
class CompleteViewPreview extends ConsumerWidget {
  const CompleteViewPreview({super.key});

  static Future<void> show(BuildContext context) async {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const CompleteViewPreview()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ...
  }
}
```

### Call site

```dart
// A sheet/dialog/route is always opened the same way:
onTap: () => TotalBalanceBreakdownSheet.show(context),
onPress: () => CompleteViewPreview.show(context),
```

**Rules:**
- The `show` method is `static`, returns `Future<void>` (or the relevant result type), and
  takes `BuildContext` as its first parameter.
- All presentation config (`useRootNavigator`, sheet options, route type) lives **inside**
  `show`, never at the call site.
- This is a **View** concern. It belongs in the widget, and is consistent with the MVVM rule
  that all `BuildContext`-dependent logic (navigation, dialogs, sheets) is handled in the View
  — never in the ViewModel.

---

> Related: the `static Future<void> refresh(WidgetRef ref)` convention for pull-to-refresh
> is documented in [mvvm_riverpod_pattern.md §8](./mvvm_riverpod_pattern.md) because its
> implementation is tied to ViewModel/data-ownership rules