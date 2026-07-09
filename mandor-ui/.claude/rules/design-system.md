# Design System

All UI must be built using the My Hero Design Language tokens and shared components. Never reach for raw Flutter primitives (`Colors`, `TextStyle(...)`, `BoxShadow(...)`) when a design-system equivalent exists.

---

## Tokens

| Concern | Class | File |
|---------|-------|------|
| Colors | `AppColors` | `lib/src/constants/colors.dart` |
| Typography | `AppTypography` | `lib/src/constants/typography.dart` |
| Shadows | `AppShadows` | `lib/src/constants/app_shadows.dart` |
| Icons | `AppIcons` | `lib/src/constants/app_icons.dart` |
| Flags | `AppFlags` | `lib/src/constants/app_flags.dart` |
| Images / logos | `AppAssets` | `lib/src/constants/app_assets.dart` |

Import all shared components from the barrel:
```dart
import 'package:mobile/src/common_widgets/common_widgets.dart';
```

---

## Colors — `AppColors`

```
primary            #CD0005   brand red (active/selected states, primary buttons)
onPrimary          #FFFFFF   text/icon on red surfaces
outline            #888888   borders, dividers, disabled secondary borders
surfaceDisabled    #B2B2B2   disabled button text/icon and disabled secondary border
tinted             #F5C5C6   tertiary button background
inputDisabledFill  #F2F2F2   disabled input field fill
```

Rules:
- Never use `Colors.red`, `Color(0xFFCD0005)`, etc. directly — always use `AppColors.*`.
- For black/white surfaces where no token exists, `Colors.white` and `Colors.black87` are acceptable.

---

## Typography — `AppTypography`

Typeface: **Figtree** (400 Regular, 700 Bold). Letter-spacing 0 throughout.

| Token | Size | Weight | Line-height |
|-------|------|--------|-------------|
| `displayLarge{Bold,Regular}` | 64 px | 700/400 | 1.2 |
| `displayMedium{Bold,Regular}` | 48 px | 700/400 | 1.2 |
| `displaySmall{Bold,Regular}` | 40 px | 700/400 | 1.2 |
| `headingLarge{Bold,Regular}` | 32 px | 700/400 | 1.2 |
| `headingMedium{Bold,Regular}` | 24 px | 700/400 | 1.4 |
| `headingSmall{Bold,Regular}` | 20 px | 700/400 | 1.4 |
| `bodyLarge{Bold,Regular}` | 16 px | 700/400 | 1.4 |
| `bodySmall{Bold,Regular}` | 14 px | 700/400 | 1.2 |
| `captionLarge{Bold,Regular}` | 12 px | 700/400 | 1.2 |
| `captionSmall{Bold,Regular}` | 10 px | 700/400 | 1.2 |

Usage:
```dart
Text('Hello', style: AppTypography.bodySmallBold)
// with color override:
Text('Hello', style: AppTypography.bodySmallRegular.copyWith(color: AppColors.outline))
```

Never call `GoogleFonts.figtree(...)` directly — use `AppTypography.*`.

---

## Shadows — `AppShadows`

| Token | Use for |
|-------|---------|
| `AppShadows.small` | Buttons, badges, slightly raised tiles |
| `AppShadows.medium` | Cards, list items, popups |
| `AppShadows.large` | Modals, popovers, floating panels |
| `AppShadows.bottomFix` | Navigation bar, bottom sheets (upward shadow) |

```dart
Container(
  decoration: BoxDecoration(boxShadow: AppShadows.medium),
)
```

---

## Icons — `MandorIcon` + `AppIcons`

```dart
MandorIcon(AppIcons.search, size: 20)
MandorIcon(AppIcons.close, size: 16, color: AppColors.outline)
```

- `MandorIcon` wraps `SvgPicture.asset` with an optional `ColorFilter`.
- Default size: 24 px. Pass `size` and `color` explicitly when context requires.
- All icon paths are constants on `AppIcons`. Never hardcode asset paths.

---

## Buttons — `MandorButton`, `MandorIconButton`, `MandorTextButton`

### Variants

| `MandorButtonVariant` | Background | Foreground | Use for |
|----------------------|------------|------------|---------|
| `primary` | `AppColors.primary` (red) | white | Main CTAs |
| `secondary` | transparent | `AppColors.primary` | Outlined CTAs |
| `tertiary` | `AppColors.tinted` (pink) | `AppColors.primary` | Low-emphasis CTAs |

### Sizes

| `MandorButtonSize` | H-padding | V-padding | Label style |
|-------------------|-----------|-----------|-------------|
| `defaultSize` | 16 px | 12 px | `bodySmallBold` |
| `small` | 12 px | 8 px | `captionLargeBold` |

### Usage

```dart
// Labeled button
MandorButton(
  label: 'Simpan',
  variant: MandorButtonVariant.primary,
  size: MandorButtonSize.defaultSize,
  prefixIcon: MandorIcon(AppIcons.check, size: 16),
  onPressed: _onSave,
)

// Icon-only square button (8 px radius)
MandorIconButton(
  icon: MandorIcon(AppIcons.refresh, size: 16),
  variant: MandorButtonVariant.secondary,
  size: MandorButtonSize.small,
  onPressed: _onRefresh,
)

// Text-only, no background
MandorTextButton(label: 'Batal', onPressed: _onCancel)
```

Rules:
- Disabled state: pass `onPressed: null` — never use a separate `enabled` flag.
- Full-width button: `isFullWidth: true` on `MandorButton`.
- Never use Flutter's `ElevatedButton`, `OutlinedButton`, or `FilledButton` — use design-system variants.

---

## Input — `MandorInput`

```dart
MandorInput(
  label: 'Email',
  hint: 'Enter your email',
  controller: _controller,
  suffixIcon: Padding(
    padding: const EdgeInsets.all(12),
    child: MandorIcon(AppIcons.eye, size: 20),
  ),
)
```

| Parameter | Default | Notes |
|-----------|---------|-------|
| `labelSize` | `medium` (14 px) | `small` = 12 px, `large` = 16 px |
| `enabled` | `true` | `false` fills with `inputDisabledFill` |
| `isError` | `false` | `true` draws red 2 px border + red text |
| `maxLines` / `minLines` | 1 / null | Set both > 1 for multiline |

Border rules: disabled = grey 1 px, normal = grey 1 px, focused = red 2 px, error = red 2 px.

Icons passed as `prefixIcon` / `suffixIcon` must include their own padding (12 px all sides).

---

## Time Picker — `showMandorTimePicker`

Use the helper function — never `showTimePicker` (Material default) directly.

```dart
final time = await showMandorTimePicker(
  context: context,
  initialTime: TimeOfDay.now(),
  title: 'Pilih Waktu',
  use24HourFormat: true,
  onConfirm: (t) => setState(() => _time = t),
);
```

Returns `Future<TimeOfDay?>` — null if the user dismisses without confirming.

---

## App Bars

### Field Force (red background)

```dart
// Dashboard
MandorFieldForceMainAppBar(
  badgeText: 'JKP0131844',
  actionIcons: [MandorFieldForceHeaderIconButton(icon: AppIcons.refresh, onPressed: _onRefresh)],
  syncLabel: 'Sinkronisasi Data',
  onSync: _onSync,
)

// Sub-page
MandorFieldForceDetailAppBar(
  title: 'Detail Kunjungan',
  onBack: () => context.pop(),
  storeCode: 'JK300004313',
  storeName: 'Nama Toko',
  storeType: 'GT',
  actionLabel: 'Simpan',
  onAction: _onSave,
)
```

### Mandor (white background)

```dart
// Dashboard
MandorMainAppBar(
  greeting: 'Halo, Andrew',
  title: 'Mandoring Dashboard',
  actions: [MandorButton(...), MandorIconButton(...)],
)

// Sub-page — only title + back. Contextual info (user name, date label,
// prev/next nav) belongs in the screen's presentation layer below the app bar.
MandorDetailAppBar(
  title: 'Buat Jadwal',
  onBack: () => context.pop(),
)
```

All app bar classes implement `PreferredSizeWidget` — pass directly to `Scaffold.appBar`.

---

## Adding New Design System Components

1. Create the widget file in `lib/src/common_widgets/`.
2. Export it from `lib/src/common_widgets/common_widgets.dart`.
3. Add token constants to the appropriate file in `lib/src/constants/`.
4. Add a demo section to `lib/src/pages/demo/` and register it in `demo.dart`.
5. Never duplicate a token that already exists — check `AppColors`, `AppTypography`, `AppShadows` first.
