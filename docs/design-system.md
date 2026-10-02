# DMS Plugins Design System & Tokens Guide

This document defines the visual design standards and token system for DankMaterialShell (DMS) plugins.
Always use `Theme` tokens (`import qs.Common`). Never hardcode pixel values, arbitrary colors, or magic numbers.

---

## 1. Button & Control Sizing (`Theme.buttonHeight*`)

Use these standard button height tokens for all buttons, icon buttons, dropdowns, and interactive controls:

| Token | Pixels | Role & Usage | Recommended Components | Icon Size |
| :--- | :--- | :--- | :--- | :--- |
| `Theme.buttonHeightXXS` | `28px` | Micro actions, table/list inline actions, tag chips | `DankActionButton`, `TagChip` | `Theme.iconSizeSmall` (16px) |
| `Theme.buttonHeightXS` | `32px` | Compact chip buttons, secondary card actions, filter chips | `DankFilterChips`, `DankButton` (size: "s") | `Theme.iconSizeSmall` (16px) |
| `Theme.buttonHeightS` | `40px` | **Default standard** for toolbars, header actions, preset bars, compact inputs | `DankActionButton`, `DankDropdown` (compactMode) | `Theme.iconSizeMedium` (20px) |
| `Theme.buttonHeightM` | `56px` | Prominent bottom bars, floating action buttons (FAB), primary modal actions | `DankButton` (size: "m"), bottom bar container | `Theme.iconSize` (24px) / `Theme.iconSizeLarge` (32px) |

### Sizing Principles:
- **Default to `Theme.buttonHeightS` (40px)** for bar and popout action buttons.
- Pair `DankDropdown` (`compactMode: true` has a default height of 40px) with `DankActionButton` using `buttonSize: Theme.buttonHeightS`.
- For bottom control bars or prominent floating actions, use `Theme.buttonHeightM` (56px) for the container and `Theme.buttonHeightS` (40px) for standard actions.

---

## 2. Icon Sizing (`Theme.iconSize*`)

Match icons to their containing buttons or labels:

| Token | Pixels | Usage Context |
| :--- | :--- | :--- |
| `Theme.iconSizeSmall` | `16px` | Inside `XXS`/`XS` buttons, inline text badges, keyboard hint items |
| `Theme.iconSizeMedium` | `20px` | Inside `S` (40px) action buttons, standard list item icons |
| `Theme.iconSize` | `24px` | Standard standalone icons, prominent actions (e.g. Play/Pause toggle) |
| `Theme.iconSizeLarge` | `32px` | Hero icons, modal headers, large feature indicators |

---

## 3. Spacing Scale (`Theme.spacing*`)

Never use arbitrary margins or paddings:

| Token | Pixels | Standard Usage |
| :--- | :--- | :--- |
| `Theme.spacingXXS` | `2px` | Micro-gaps between keycaps, badge padding, thin dividers |
| `Theme.spacingXS` | `4px` | Compact button padding, tight element gaps |
| `Theme.spacingS` | `8px` | Space between related controls, inside cards |
| `Theme.spacingM` | `12px` | Standard modal/panel padding, row layouts, container margins |
| `Theme.spacingL` | `16px` | Section margins, card boundaries, outer content gutters |
| `Theme.spacingXL` | `24px` | Major section separators, prominent dialog margins |

---

## 4. Corner Radius Scale (`Theme.cornerRadius*`)

| Token | Value | Typical Application |
| :--- | :--- | :--- |
| `Theme.cornerRadiusXS` | `4px` | Small badges, sub-chips, tooltip indicators |
| `Theme.cornerRadiusSmall` (`cornerRadiusS`) | `8px` | Action buttons, list/grid delegate hover shapes |
| `Theme.cornerRadius` (`cornerRadiusM`) | `12px` | Standard cards, dropdown menus, popovers |
| `Theme.cornerRadiusLarge` (`cornerRadiusL`) | `16px` | Main plugin modals (`DankModal`), dialog hosts |
| `Theme.cornerRadiusFull` | `9999px` | Circular action buttons (`circular: true`), pills, search bars |

---

## 5. Typography Scale (`Theme.fontSize*`)

Always render text using `StyledText` (not raw `Text`):

| Token | Approx Size | Usage Context |
| :--- | :--- | :--- |
| `Theme.fontSizeSmall` | `12px` | Footers, keyboard hints, badges, secondary captions |
| `Theme.fontSizeMedium` | `14px` | Standard body text, button labels, grid item descriptions |
| `Theme.fontSizeLarge` | `16px` | Search bar input text, section headers, modal subtitles |
| `Theme.fontSizeXLarge` | `20px` | Dialog titles, prominent summary indicators |
| `Theme.fontSizeXXLarge` | `28px` | Large numbers, countdown clocks, metrics display |

- UI font family: `Theme.defaultFontFamily`
- Monospace font family: `Theme.defaultMonoFontFamily` (for shortcuts, commands, keycaps)

---

## 6. Surface & Color Roles

DMS creates depth through tonal elevation rather than heavy drop shadows:

| Role | Token | Typical Use | Paired Foreground Token |
| :--- | :--- | :--- | :--- |
| **Surface** | `Theme.surface` / `Theme.hostSurface` | Modal, popout, or window background | `Theme.surfaceText` / `Theme.onSurface` |
| **Container** | `Theme.surfaceContainer` | Cards, panels, grouped content | `Theme.surfaceText` |
| **Interactive** | `Theme.surfaceContainerHigh` | Inactive buttons, chips, search inputs | `Theme.surfaceText` |
| **Hover / Selected** | `Theme.surfaceContainerHighest` | Hovered items, active sub-chips | `Theme.surfaceText` |
| **Primary Accent** | `Theme.primary` | Active toggles, key actions, sliders | `Theme.onPrimary` |
| **Destructive** | `Theme.error` | Delete, stop, reset, clear actions | `Theme.onError` |
| **Subdued** | `Theme.surfaceVariant` | Borders, subtle dividers, muted tracks | `Theme.surfaceVariantText` |

**State Opacities via `Theme.withAlpha()`:**
- Never concatenate raw rgba strings (`"rgba(255, 255, 255, 0.1)"`).
- Always use `Theme.withAlpha(color, opacity)`.
- Hover overlay: `Theme.withAlpha(Theme.surfaceText, 0.08)` or `Theme.withAlpha(Theme.primary, 0.12)`.
