import QtQuick
import qs.Common
import qs.Widgets

DankTextField {
    cornerRadius: typeof Theme.fullRadius === "function" ? Theme.fullRadius(width, height) : (height / 2)
    normalBorderColor: Theme.outlineVariant ?? Theme.outlineMedium ?? Theme.outline
    focusedBorderColor: (Theme.focusRingWidth ?? 0) > 0 ? (Theme.focusRingColor ?? Theme.primary) : normalBorderColor
    borderWidth: Theme.outlineWidth ?? 1
    focusedBorderWidth: Math.max(borderWidth, Theme.focusRingWidth ?? 2)
    placeholderColor: Theme.surfaceTextSecondary ?? Theme.surfaceVariantText
    leftIconName: "search"
    hidePlaceholderOnFocus: false
    showClearButton: true
}
