# Riverpod (v3.x)

`StateNotifier` and `StateNotifierProvider` are **removed** in Riverpod 3.x. Do not use them.

Use `Notifier<State>` + `NotifierProvider.autoDispose`:

```dart
final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(
  LoginController.new,
);

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState.initial(); // replaces constructor init

  Future<void> someAction() async {
    state = const LoginState.loading();
    // ...
  }
}
```

`AutoDisposeNotifier` does **not** exist. `autoDispose` is a property on the provider, not a class hierarchy.

Providers (non-controller) use `Provider<T>` or `FutureProvider<T>`:

```dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authApiProvider));
});
```

## Reading State in Widgets

**NEVER use `ref.read()` inside the `build()` method.** It breaks reactivity because it only reads the provider's value once and doesn't subscribe to changes.

Instead, always use `ref.watch()` inside `build()`:

```dart
// ❌ Bad — widget won't rebuild when state changes
@override
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.read(userProvider);
  return Text(user.name);
}

// ✅ Good — widget rebuilds reactively
@override
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.watch(userProvider);
  return Text(user.name);
}
```

Use `ref.read()` only in event handlers (e.g., `onPressed`), lifecycle hooks like `initState`, or inside a `Notifier` method where you need a one-shot read without subscribing.
