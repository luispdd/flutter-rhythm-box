# UI Theme Specification: Warm Amber Template

Common Flutter application theme template utilizing the Warm Amber palette and Material 3 design tokens.

## Palette & Design Tokens

| Token | Hex Value | Color Preview / Description | Role |
| :--- | :--- | :--- | :--- |
| `kBgDark` | `0xFF0C0A09` | Deep charcoal / near black | Scaffold background |
| `kSurface` | `0xFF1C1917` | Dark stone surface | Cards, App Bars, Dialogs, Container surfaces |
| `kAmber` | `0xFFF59E0B` | Warm amber | Primary accent, active slider tracks, key interactions |
| `kAmberDark` | `0xFFD97706` | Deep amber | Secondary accent, emphasis states |
| `kAmberLight` | `0xFFFBBF24` | Bright gold / amber light | Highlighting, hover/focus accents |
| `kTextPrimary` | `0xFFFAFAF9` | Off-white / stone white | Primary typography, headers, icons |
| `outline` | `0xFF292524` | Muted stone border | Borders, dividers, subtle outlines |

## Theme Specification

- **Material Version**: Material 3 (`useMaterial3: true`)
- **Brightness**: Dark (`Brightness.dark`)
- **Scaffold Background**: `kBgDark` (`0xFF0C0A09`)
- **Color Scheme**:
  - `primary`: `kAmber` (`0xFFF59E0B`)
  - `onPrimary`: `Colors.white`
  - `secondary`: `kAmberDark` (`0xFFD97706`)
  - `surface`: `kSurface` (`0xFF1C1917`)
  - `onSurface`: `kTextPrimary` (`0xFFFAFAF9`)
  - `outline`: `Color(0xFF292524)`
- **AppBar Theme**:
  - `backgroundColor`: `kSurface`
  - `elevation`: `0`
  - `centerTitle`: `false`
  - `titleTextStyle`: `fontSize: 20`, `fontWeight: FontWeight.w500`, `color: kTextPrimary`, `letterSpacing: 0.3`
- **Slider Theme**:
  - `activeTrackColor`: `kAmber`
  - `inactiveTrackColor`: `Colors.white.withValues(alpha: 0.10)`
  - `thumbColor`: `Colors.white`
  - `overlayColor`: `kAmber.withValues(alpha: 0.20)`
  - `trackHeight`: `4`
  - `thumbShape`: `RoundSliderThumbShape(enabledThumbRadius: 8)`
- **Dialog Theme**:
  - `backgroundColor`: `kSurface`
  - `shape`: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))`

## Dart Reference Implementation

```dart
import 'package:flutter/material.dart';

// ─── Warm Amber Palette ───
const Color kBgDark = Color(0xFF0C0A09);
const Color kSurface = Color(0xFF1C1917);
const Color kAmber = Color(0xFFF59E0B);
const Color kAmberDark = Color(0xFFD97706);
const Color kAmberLight = Color(0xFFFBBF24);
const Color kTextPrimary = Color(0xFFFAFAF9);

/// Builds the complete app theme used by [MaterialApp].
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBgDark,
    colorScheme: const ColorScheme.dark(
      primary: kAmber,
      onPrimary: Colors.white,
      secondary: kAmberDark,
      surface: kSurface,
      onSurface: kTextPrimary,
      outline: Color(0xFF292524),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: kTextPrimary,
        letterSpacing: 0.3,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: kAmber,
      inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
      thumbColor: Colors.white,
      overlayColor: kAmber.withValues(alpha: 0.20),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
```

## Usage Guidelines

1. **Theme Application**: Wire `buildAppTheme()` directly to `MaterialApp.theme` and `MaterialApp.darkTheme` in `lib/main.dart` or the root widget.
2. **Component Alignment**:
   - Containers and cards should use `kSurface` with borders styled using `Theme.of(context).colorScheme.outline`.
   - Actionable interactive elements (e.g. active step buttons, play buttons, selected indicators) should utilize `kAmber` / `kAmberDark`.
   - Typography should default to `kTextPrimary` or `Theme.of(context).colorScheme.onSurface`.
