# AGENTS.md

This file provides guidance to AI coding assistants when working with code in this repository.

## Commands

```bash
flutter pub get
flutter analyze
dart format lib/ test/
flutter test
flutter test test/path/to/test_file.dart
dart run build_runner build --delete-conflicting-outputs
dart run slang
```

Always run with a flavor and `API_URL` — never without one. See `.claude/rules/flavoring.md`.

---

## Design System

All UI uses My Hero Design Language tokens and shared components. No raw Flutter primitives (`Colors.*`, `TextStyle(...)`, `BoxShadow(...)`) when a design-system equivalent exists.

Tokens: `AppColors`, `AppTypography`, `AppShadows`, `AppIcons`, `AppFlags`, `AppAssets` in `lib/src/constants/`. Components: `MandorButton`, `MandorIconButton`, `MandorTextButton`, `MandorInput`, `MandorIcon`, `showMandorTimePicker`, `MandorFieldForceMainAppBar`, `MandorFieldForceDetailAppBar`, `MandorFieldForceHeaderIconButton`, `MandorMainAppBar`, `MandorDetailAppBar` in `lib/src/common_widgets/`.

See `.claude/rules/design-system.md`.

---

## Architecture

Four layers: **Presentation** / **Application** / **Domain** / **Data**. State management is Riverpod throughout — no BLoC, GetX, or Provider.

Feature-First for presentation/application, Layer-First for domain/data shared across features.

See `.claude/rules/architecture.md` for full structure, repository split, DTO patterns, and API class conventions.

---

## Before Writing Code

Search before creating. Check `common_widgets/`, `utils/extensions/`, `constants/`, `common/data/`, `common/domain/` first.

See `.claude/rules/before-writing-code.md`.

---

## Naming

Snake\_case files, PascalCase classes. Suffixes: `_screen`, `_controller`, `_state`, `_widget`, `_response`, `_request`. Domain entities have no suffix.

See `.claude/rules/naming.md` for the full table.

---

## Code Style

Two-space indent, trailing commas, line-break each param after 2+ params. Widget keys on every screen. Split large trees into classes, not helper methods. Use stateless widget instead of function widget to improve performance. No hardcoded colors or text styles.

See `.claude/rules/code-style.md`.

---

## Riverpod (v3.x)

`StateNotifier`/`StateNotifierProvider` are removed. Use `Notifier<State>` + `NotifierProvider.autoDispose`. `AutoDisposeNotifier` does not exist. NEVER use `ref.read()` inside `build()` methods.

See `.claude/rules/riverpod.md`.

---

## Result\<T\> and Error Handling

All repository methods return `Result<T>`. Never throw raw exceptions to the UI. Always import `config.dart` directly in files calling `.when()` / `.maybeWhen()` — extension methods are not transitively imported.

See `.claude/rules/error-handling.md` for `NetworkExceptions` variants and usage patterns.

---

## Localization

Uses slang. Base locale: Indonesian (`id`). Run `dart run slang` after editing any `.i18n.json`. Mark unwired strings with `.hardcoded`.

See `.claude/rules/localization.md`.

---

## Flavoring

Three flavors: `dev`, `qas`, `prd`. Runtime access via `F.appFlavor` / `F.title`. API URL injected via `--dart-define=API_URL=...` — never hardcoded.

See `.claude/rules/flavoring.md`.

---

## Routing

Uses GoRouter. Routes in `lib/src/routing/routes.dart`. No nested navigators where a parent redirects to its own child.

See `.claude/rules/routing.md`.

---

## Security and Logging

No `print()` or `debugPrint()` — use `log()` from `dart:developer`. No sensitive data in `SharedPreferences` — use `flutter_secure_storage` or Hive. Every caught error must be logged.

See `.claude/rules/security-and-logging.md`.

---

## Generated Sources

`*.freezed.dart`, `*.g.dart`, `translations.g.dart` — never edit manually, always commit.

See `.claude/rules/generated-sources.md`.

---

## Scope Discipline

When implementing a task (feature, bug fix, or refactor), **change only the files and lines that the task requires**. Do not improve, clean up, or restructure unrelated code in the same set of changes — even if the surrounding code looks like it could be better.

Specifically prohibited unless the task explicitly asks for it:

- Moving providers from data-layer files to controller files
- Adding new return-type enums (`FooFailure`, `BarFailure`) to controllers that only need a one-line auth fix
- Changing method signatures (e.g. `Future<void>` → `Future<FooFailure?>`) on methods the task doesn't touch
- Removing `config.dart` imports or restructuring `Result<T>.when()` call sites in files that only need a `devUserId` replacement
- Extracting or inlining widget helpers, renaming providers, or adding intermediate abstractions in files adjacent to the change

**The test:** if reverting the change would break the task but not break any existing tests, it belongs in the task. If reverting it would leave everything else working exactly as before, it is out of scope.

Out-of-scope changes will be reverted.
