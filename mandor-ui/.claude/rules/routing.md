# Routing

Uses [GoRouter](https://pub.dev/packages/go_router). Routes are defined in `lib/src/routing/routes.dart`.

- Do not use nested navigators where a parent redirects to its own child — this causes blank screens on pop.
- Split large route trees into per-feature files (e.g. `_auth_routes.dart`, `_home_routes.dart`).
