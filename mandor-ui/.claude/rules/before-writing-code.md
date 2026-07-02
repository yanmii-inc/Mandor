# Before Writing Any Code

Introduce no redundancy. Search the codebase before creating anything new:

1. **Exact match** — reuse as-is.
2. **Similar match** — enhance if it's a natural extension; create new if
   behaviors would diverge.
3. **No match** — only then create something new.

Check these locations first:

- `lib/src/common_widgets/` — shared UI components
- `lib/src/utils/extensions/` — Dart extensions
- `lib/src/constants/` — constants and theme values
- `lib/src/common/data/` — repositories, mappers, data sources
- `lib/src/common/domain/` — entities and use cases
