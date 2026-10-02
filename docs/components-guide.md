# DMS Plugin Components Guide

Always prefer built-in DMS primitives (`qs.Widgets`) over reinventing custom UI shapes, sliders, or popups.

---

## 1. Buttons

### `DankActionButton`
Use for compact, circular or square icon buttons in toolbars, headers, and bar widgets.

```qml
import qs.Common
import qs.Widgets

DankActionButton {
    buttonSize: Theme.buttonHeightS // 40px standard
    circular: true
    iconName: "volume_up"
    iconSize: Theme.iconSizeMedium  // 20px
    iconColor: Theme.surfaceText
    backgroundColor: Theme.surfaceContainerHigh
    tooltipText: I18n.tr("Adjust Volume")
    onClicked: root.toggleMute()
}
```

- For prominent/primary actions (e.g. Play/Pause toggle), set `backgroundColor: Theme.primary`, `iconColor: Theme.onPrimary`, and `iconSize: Theme.iconSize` (24px).
- For destructive actions (e.g. Delete, Stop), set `iconColor: Theme.error`.
- Avoid drawing custom canvas flowers or complex ad-hoc shapes for buttons.

### `DankButton`
Use for labeled text buttons with optional leading/trailing icons.

```qml
DankButton {
    text: I18n.tr("Save")
    iconName: "check"
    buttonHeight: Theme.buttonHeightS
    onClicked: root.save()
}
```

---

## 2. Dropdowns & Selection

### `DankDropdown`
Use for compact or expanded select menus. It handles popup window anchoring, blur, outside clicks, and keyboard focus automatically.

```qml
DankDropdown {
    width: parent.width
    height: Theme.buttonHeightS
    compactMode: true
    dropdownWidth: width
    emptyText: I18n.tr("Select preset…")
    options: root.presets.map(p => p.name)
    currentValue: root.currentPresetName
    onValueChanged: (val) => root.selectPreset(val)
}
```

- When using inline renaming alongside a dropdown, swap the dropdown with `DankTextField` conditionally (`visible: !root.renaming`).
- Do not construct custom `Rectangle` dropdown lists with manual `MouseArea` outside click backdrops.

---

## 3. Sliders

### `DankSlider`
Use for volume, brightness, size, or continuous numeric controls.

```qml
DankSlider {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width - (Theme.buttonHeightS * 2)
    minimum: 0
    maximum: 100
    value: root.volume
    showValue: true
    unit: "%"
    wheelEnabled: true
    onSliderValueChanged: (v) => {
        root.volume = v;
        root.applyVolume(v);
    }
}
```

- Standard track colors and primary fill are styled automatically by the DMS theme.
- Avoid building custom slider tracks with `MouseArea.onPositionChanged` unless a custom radial gauge is strictly required.

---

## 4. Text & Keycaps

### `StyledText`
Always use `StyledText` instead of standard QML `Text` for correct font rendering, line heights, and theme integration.

```qml
StyledText {
    text: I18n.tr("Active Sound")
    font.pixelSize: Theme.fontSizeMedium
    font.weight: Font.Medium
    color: Theme.surfaceText
    elide: Text.ElideRight
}
```

### `DankKeycap`
Use for displaying keyboard shortcuts in footers, tooltips, or hint rows.

```qml
DankKeycap {
    text: "Esc"
}
```

---

## 5. Settings Components

In `<Plugin>Settings.qml`, always organize settings inside `SettingsCard` using `qs.Modules.Settings.Widgets` or `shared/`:

- `PluginHeader`: Header banner for the settings page.
- `UsageGuide`: Always placed in the first `SettingsCard` after the header.
- `ToggleSettingPlus` / `ToggleSetting`: Boolean on/off settings.
- `SliderSettingPlus` / `SliderSetting`: Numeric adjustments with live preview.
- `SelectionSettingPlus` / `SelectionSetting`: Enumerated option selections.
