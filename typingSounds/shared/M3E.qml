pragma Singleton
import QtQuick
import qs.Common

QtObject {
    // ── M3E Motion Durations ────────────────────────────────────────────────
    readonly property int spatialFastMs: Theme.expressiveDurations?.expressiveFastSpatial ?? Theme.mediumDuration
    readonly property int spatialDefaultMs: Theme.expressiveDurations?.expressiveDefaultSpatial ?? Theme.mediumDuration
    readonly property int spatialSlowMs: Theme.expressiveDurations?.expressiveSlowSpatial ?? Theme.longDuration
    readonly property int effectsFastMs: Theme.expressiveDurations?.expressiveFastEffects ?? Theme.shorterDuration
    readonly property int effectsMs: Theme.expressiveDurations?.expressiveEffects ?? Theme.shortDuration
    readonly property int effectsSlowMs: Theme.expressiveDurations?.expressiveSlowEffects ?? Theme.mediumDuration

    // ── M3E Motion Bezier Curves ────────────────────────────────────────────
    readonly property var curveFastSpatial: Theme.expressiveCurves?.expressiveFastSpatial ?? [0.42, 1.67, 0.21, 0.9, 1, 1]
    readonly property var curveDefaultSpatial: Theme.expressiveCurves?.expressiveDefaultSpatial ?? [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property var curveSlowSpatial: Theme.expressiveCurves?.expressiveSlowSpatial ?? [0.39, 1.29, 0.35, 0.98, 1, 1]
    readonly property var curveFastEffects: Theme.expressiveCurves?.expressiveFastEffects ?? [0.31, 0.94, 0.34, 1, 1, 1]
    readonly property var curveEffects: Theme.expressiveCurves?.expressiveEffects ?? [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property var curveSlowEffects: Theme.expressiveCurves?.expressiveSlowEffects ?? [0.34, 0.88, 0.34, 1, 1, 1]

    // ── Grouped List & Connected Button Geometry ────────────────────────────
    readonly property real outerR: Theme.groupedListOuterRadius ?? (Theme.cornerRadiusL ?? 16)
    readonly property real innerR: Theme.groupedListInnerRadius ?? (Theme.cornerRadiusXS ?? 6)
    readonly property real groupGap: Theme.groupedListGap ?? 2

    // ── Hover & Press Shape Morphing Radii ──────────────────────────────────
    readonly property real pressRadiusXXS: Theme.cornerRadiusXXS ?? 4
    readonly property real pressRadiusXS: Theme.cornerRadiusXS ?? 6
    readonly property real pressRadiusS: Theme.cornerRadiusS ?? 8
    readonly property real hoverRadiusM: Theme.cornerRadiusM ?? 10
    readonly property real tileIdleRadius: Theme.cornerRadiusL ?? 16
    readonly property real tileHighlightedRadius: Theme.cornerRadiusLIncreased ?? 20
    readonly property real tileHoverRadius: Theme.cornerRadiusXL ?? 24

    // ── Hover & Press Interaction Scales ────────────────────────────────────
    readonly property real tilePressScale: 0.96
    readonly property real rowPressScale: 0.97
    readonly property real iconBtnPressScale: 0.93
    readonly property real pinHoverScale: 1.08
    readonly property real pinHiddenScale: 0.6

    // ── Morphing Icon Pill & Switcher Metrics ───────────────────────────────
    readonly property real tileIconPillWidth: 34
    readonly property real tileIconPillActiveWidth: 42
    readonly property real tileIconPillHeight: 28
    readonly property real rowIconPillWidth: 28
    readonly property real rowIconPillActiveWidth: 34
    readonly property real rowIconPillHeight: 26
    readonly property real activeBlendFactor: 0.18
    readonly property real switcherActiveRatio: 0.68

    // ── Shape Morphing Helpers ──────────────────────────────────────────────
    function tileRadius(pressed, hovered, highlighted) {
        if (pressed)
            return pressRadiusS;
        if (hovered)
            return tileHoverRadius;
        return highlighted ? tileHighlightedRadius : tileIdleRadius;
    }

    function iconPillRadius(pressed, hovered, height) {
        if (pressed)
            return pressRadiusXS;
        if (hovered)
            return hoverRadiusM;
        return height / 2;
    }
}
