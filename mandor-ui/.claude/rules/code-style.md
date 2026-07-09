# Code Style

## Formatting

- Two-space soft tabs.
- Use line breaks before each parameter when a method has more than two parameters or exceeds line length.
- Always use a trailing comma after the last parameter.

## Widgets

Add widget keys to every screen widget for testability:

```dart
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  static const _key = 'SignInKey';
  static const scaffoldKey = Key('scaffold.$_key');
  static const emailTextFieldKey = Key('emailTextField.$_key');
}
```

Split large widget trees into small, separate widget **classes** — not helper methods. Use `StatelessWidget` instead of function widgets to improve performance.
- **Good:** `_HeadingWidget`, `_BodyWidget` as separate `StatelessWidget` subclasses.
- **Bad:** `_headingWidget()`, `_bodyWidget()` as private methods returning `Widget`.

Add `const` before widgets wherever possible.

Never hardcode colors, font sizes, or text styles — use `Theme.of(context)` or `lib/src/constants/`.

Use `setState` for ephemeral local UI state (e.g. toggle visibility). Use Riverpod for anything involving business logic, shared state, or state that persists beyond the widget.
