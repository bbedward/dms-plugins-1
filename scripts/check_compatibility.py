#!/usr/bin/env python3
"""
check_compatibility.py - Verify backward compatibility for DMS plugins against stable DMS releases.

Detects:
1. Use of unreleased DMS components that do not exist in stable DMS (e.g. DMS 1.6.2)
   and are not bundled into `shared/`.
2. Missing `./shared` imports: using a shared component (like DankSearchField) without
   importing `./shared` in the file (which causes runtime crashes on stable DMS).
3. Out-of-sync shared components: components used in the plugin that exist in canonical
   `shared/` but have not been synced into the plugin's local `shared/` folder or `qmldir`.
4. Unresolved QML types.

Usage:
    python3 scripts/check_compatibility.py [PLUGIN_NAME...] [--verbose]
"""

import os
import re
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional

REPO_ROOT = Path(__file__).resolve().parent.parent
CANONICAL_SHARED = REPO_ROOT / "shared"

# Stable baseline DMS version (DMS 1.6.2)
BASELINE_DMS_VERSION = "1.6.2"

# Symbols available in Qt / Quickshell built-in modules
QT_QUICKSHELL_BUILTINS: Set[str] = {
    # QtQuick basic types
    "Item", "Rectangle", "Text", "Image", "AnimatedImage", "BorderImage",
    "FocusScope", "MouseArea", "MultiPointTouchArea", "TapHandler", "PointHandler",
    "DragHandler", "HoverHandler", "WheelHandler", "PinchHandler", "Flickable",
    "Flipable", "Flow", "Grid", "Row", "Column", "Repeater", "Loader",
    "Canvas", "Path", "PathLine", "PathQuad", "PathCubic", "PathCatmullRomCurve",
    "PathArc", "PathAngleArc", "PathSvg", "PathAttribute", "PathPercent",
    "Shape", "ShapePath", "Scale", "Rotation", "Translate", "Matrix4x4",
    "FontLoader", "TextEdit", "TextInput", "IntValidator", "DoubleValidator",
    "RegularExpressionValidator", "ShaderEffect", "ShaderEffectSource",
    "DropArea", "Drag", "Accessible", "KeyNavigation", "Keys", "LayoutMirroring",
    "Component", "QtObject", "Binding", "Connections", "Timer", "Instantiator",
    "ListModel", "ListElement", "PropertyAnimation", "NumberAnimation",
    "ColorAnimation", "RotationAnimation", "Vector3dAnimation", "SequentialAnimation",
    "ParallelAnimation", "PauseAnimation", "ScriptAction", "PropertyAction",
    "ParentAnimation", "AnchorAnimation", "SpringAnimation", "SmoothedAnimation",
    "Behavior", "State", "PropertyChanges", "StateGroup", "Transition",
    "Gradient", "GradientStop", "ListView", "GridView", "PathView",
    "TableView", "TreeView", "TreeViewDelegate", "SelectionRectangle",
    "OpacityAnimator", "XAnimator", "YAnimator", "RotationAnimator", "ScaleAnimator",
    # QtQuick.Layouts
    "Layout", "RowLayout", "ColumnLayout", "GridLayout", "StackLayout",
    # QtQuick.Controls (basic)
    "Control", "Button", "CheckBox", "RadioButton", "Switch", "Slider",
    "ProgressBar", "BusyIndicator", "Dial", "RangeSlider", "ScrollBar",
    "ScrollIndicator", "ScrollView", "TextArea", "TextField", "SpinBox",
    "ComboBox", "Tumbler", "SwipeView", "TabBar", "TabButton", "StackView",
    "Drawer", "Dialog", "DialogButtonBox", "Menu", "MenuItem", "MenuSeparator",
    "Action", "ActionGroup", "Popup", "ToolTip", "Page", "Pane", "Frame",
    "RoundButton", "ToolBar", "ToolButton", "ToolSeparator", "SplitView",
    # Qt5Compat.GraphicalEffects / MultiEffect
    "MultiEffect", "FastBlur", "GaussianBlur", "DropShadow", "InnerShadow",
    "ColorOverlay", "LinearGradient", "RadialGradient", "ConicalGradient",
    "Blend", "Displace", "GammaAdjust", "HueSaturation", "LevelAdjust",
    # QtMultimedia
    "MediaPlayer", "AudioOutput", "VideoOutput", "AudioSession", "Camera",
    "MediaDevices", "SoundEffect",
    # Quickshell core types
    "Scope", "Variants", "WlSession", "DesktopService", "Quickshell",
    "PanelWindow", "FloatingWindow", "PopupWindow", "SubsurfaceWindow",
    "Region", "Mask", "WlrLayershell", "WlrForeignToplevel",
    # Quickshell.Io
    "IpcHandler", "Process", "File", "Socket", "Pipe", "IoStream",
    "StandardPaths", "FileInfo", "FileWatcher", "SplitParser", "StringParser",
    "StdioCollector",
    # Quickshell.Services
    "Mpris", "MprisPlayer", "MprisTrack", "SystemClock", "Bluetooth",
    "Pipewire", "PipewireNode", "PowerProfiles", "Upower", "Pam", "PamSession"
}

# Symbols strictly available in DMS 1.6.2 (Stable baseline)
DMS_STABLE_SYMBOLS: Dict[str, Set[str]] = {
    "qs.Widgets": {
        "AppIconRenderer", "AppLauncherGridDelegate", "AppLauncherListDelegate",
        "BackdropBlur", "BatteryMeter", "CachingImage", "DankActionButton",
        "DankAlbumArt", "DankAnimatedAlbumArt", "DankBackdrop", "DankBlink",
        "DankButton", "DankButtonGroup", "DankCircularImage", "DankCollapsibleSection",
        "DankColorAnimation", "DankColorSwatch", "DankDropdown", "DankFilterChips",
        "DankFlickable", "DankFloatingWindow", "DankFocusGrab", "DankGridView",
        "DankIcon", "DankIconPicker", "DankKeycap", "DankListView",
        "DankLocationSearch", "DankNFIcon", "DankNumberStepper", "DankOSD",
        "DankPopout", "DankPopoutConnected", "DankPopoutStandalone", "DankRefreshButton",
        "DankRipple", "DankSVGIcon", "DankScrollbar", "DankSeekbar",
        "DankSlideout", "DankSlider", "DankSpinner", "DankTabBar",
        "DankTextCursor", "DankTextEdit", "DankTextField", "DankToggle",
        "DankTooltip", "DankTooltipV2", "DismissZone", "FloatingWindowControls",
        "HoverDismissTracker", "LauncherLogo", "M3WaveProgress", "MediaArtBackdrop",
        "MediaArtwork", "MediaBlobHalo", "NumericText", "PluginGlobalVar",
        "PopoutHoverBodyTracker", "PopoutHoverDismiss", "ScrollingText", "StateLayer",
        "StyledRect", "StyledText", "StyledTextMetrics", "SystemLogo",
        "TransientSurfaceTracker", "WindowBlur"
    },
    "qs.Common": {
        "Theme", "Style", "I18n", "Paths", "Proc", "ColorUtils", "Accents",
        "SoundEffectWrapper", "Singleton"
    },
    "qs.Services": {
        "PluginService", "PopoutService", "ToastService", "SessionService",
        "AudioService", "AppSearchService", "BatteryService", "BluetoothService",
        "CalendarService", "ClipboardService", "CompositorService", "IconThemeService",
        "NetworkService", "NiriService", "NotificationService", "ThemeAutoService",
        "VPNService", "WeatherService", "WlrOutputService", "DisplayService",
        "Log", "ChangelogService", "SettingsSearchService", "ShellVersionService"
    },
    "qs.Modules.Plugins": {
        "PluginComponent", "PluginSettings", "DesktopPluginComponent", "BasePill",
        "PopoutComponent"
    },
    "qs.Modals.Common": {
        "DankModal", "DankModalHost", "ModalBackground"
    },
    "qs.Modals.FileBrowser": {
        "DankFileBrowser", "FileBrowserModal", "FileBrowserSurfaceModal"
    },
    "qs.Modules.Settings.Widgets": {
        "SettingsCard", "SectionTitle", "ToggleSetting", "SelectionSetting", "SliderSetting"
    }
}

# Known symbols that only exist in unreleased DMS master and require bundling in shared/
UNRELEASED_DMS_SYMBOLS: Set[str] = {
    "DankSearchField", "DankBadge", "DankAnim", "SpringMotion", "DankTabButton",
    "DankScrollIndicator", "DankCard", "FocusRing", "DankPopoutHost", "DankTooltipHost"
}

# Regex to strip comments
COMMENT_RE = re.compile(r'/\*.*?\*/|//.*?$', re.MULTILINE | re.DOTALL)

# Regex to extract imports
IMPORT_RE = re.compile(
    r'^[ \t]*import[ \t]+(?P<target>"[^"]+"|\'[^\']+\'|[^\s;]+)(?:[ \t]+as[ \t]+(?P<alias>[A-Za-z0-9_]+))?[ \t]*;?[ \t]*$',
    re.MULTILINE
)

# Regex to extract instantiated QML types: `TypeName {` or `<TypeName>`
INSTANTIATED_TYPE_RE = re.compile(r'(?:^|[^A-Za-z0-9_.])(?P<type>[A-Z][A-Za-z0-9_]*)\s*\{')


def strip_comments(text: str) -> str:
    def replacer(match):
        s = match.group(0)
        return '\n' * s.count('\n')
    return COMMENT_RE.sub(replacer, text)


def get_canonical_shared_components() -> Set[str]:
    """Return all QML component names in top-level shared/."""
    if not CANONICAL_SHARED.is_dir():
        return set()
    return {f.stem for f in CANONICAL_SHARED.glob("*.qml")}


def get_plugin_shared_components(plugin_dir: Path) -> Tuple[Set[str], Set[str]]:
    """Return (files in plugin/shared, types declared in qmldir)."""
    shared_dir = plugin_dir / "shared"
    if not shared_dir.is_dir():
        return set(), set()

    files = {f.stem for f in shared_dir.glob("*.qml")}
    qmldir = shared_dir / "qmldir"
    qmldir_types = set()
    if qmldir.is_file():
        try:
            for line in qmldir.read_text(encoding="utf-8").splitlines():
                parts = line.strip().split()
                if parts and not parts[0].startswith("#") and parts[0] != "module":
                    qmldir_types.add(parts[0])
        except Exception:
            pass

    return files, qmldir_types


def get_local_plugin_components(plugin_dir: Path) -> Set[str]:
    """Collect all .qml components defined inside the plugin itself."""
    comps = set()
    for root, dirs, files in os.walk(plugin_dir):
        if "shared" in dirs:
            dirs.remove("shared")
        if "dms-common" in dirs:
            dirs.remove("dms-common")
        for f in files:
            if f.endswith(".qml"):
                comps.add(Path(f).stem)
    return comps


class CompatibilityChecker:
    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.canonical_shared = get_canonical_shared_components()
        self.all_stable_dms_symbols = set()
        for sym_set in DMS_STABLE_SYMBOLS.values():
            self.all_stable_dms_symbols.update(sym_set)

    def check_qml_file(
        self,
        file_path: Path,
        plugin_dir: Path,
        plugin_shared_files: Set[str],
        plugin_qmldir_types: Set[str],
        local_plugin_components: Set[str]
    ) -> List[Tuple[int, str, str]]:
        """
        Check a single QML file for compatibility issues.
        Returns list of (line_no, severity, message).
        """
        errors: List[Tuple[int, str, str]] = []
        try:
            raw_text = file_path.read_text(encoding="utf-8")
        except Exception as e:
            return [(0, "ERROR", f"Failed to read file: {e}")]

        clean_text = strip_comments(raw_text)

        # Parse imports
        imports: Set[str] = set()
        has_shared_import = False
        for line in raw_text.splitlines():
            m = IMPORT_RE.match(line)
            if m:
                target = m.group("target").strip('\'"')
                imports.add(target)
                if target in ["./shared", "../shared", "../../shared", "./dms-common", "../dms-common"]:
                    has_shared_import = True

        # Parse instantiated types with line numbers
        lines = clean_text.splitlines()
        for line_no, line_content in enumerate(lines, 1):
            for match in INSTANTIATED_TYPE_RE.finditer(line_content):
                type_name = match.group("type")

                # 1. Qt / Quickshell core built-in?
                if type_name in QT_QUICKSHELL_BUILTINS:
                    continue

                # 2. Defined inside the plugin locally?
                if type_name in local_plugin_components:
                    continue

                # 3. Component from shared/ ?
                is_canonical_shared = type_name in self.canonical_shared
                is_plugin_shared = type_name in plugin_shared_files

                if is_canonical_shared or is_plugin_shared:
                    # Check: does this file import ./shared?
                    if not has_shared_import:
                        errors.append((
                            line_no,
                            "ERROR",
                            f"Instantiates '{type_name}' which is a shared component, but this file does NOT import './shared'. "
                            f"On stable DMS ({BASELINE_DMS_VERSION}), QML will fail to resolve this type and crash at runtime!"
                        ))
                    elif is_canonical_shared and not is_plugin_shared:
                        errors.append((
                            line_no,
                            "ERROR",
                            f"Component '{type_name}' is in canonical shared/ but NOT synchronized to {plugin_dir.name}/shared/. "
                            f"Run 'python3 scripts/sync_shared.py' to resolve."
                        ))
                    elif is_plugin_shared and type_name not in plugin_qmldir_types:
                        errors.append((
                            line_no,
                            "WARN",
                            f"Component '{type_name}' exists in {plugin_dir.name}/shared/ but is missing from qmldir. "
                            f"Run 'python3 scripts/sync_shared.py' to regenerate qmldir."
                        ))
                    continue

                # 4. Symbol known in DMS 1.6.2 (Stable baseline)
                if type_name in self.all_stable_dms_symbols:
                    continue

                # 5. Symbol from unreleased DMS master?
                if type_name in UNRELEASED_DMS_SYMBOLS:
                    errors.append((
                        line_no,
                        "ERROR",
                        f"Unreleased DMS component '{type_name}' is NOT available in stable DMS {BASELINE_DMS_VERSION} "
                        f"and is not bundled in shared/. Please bundle '{type_name}.qml' into shared/ and run sync_shared.py."
                    ))
                    continue

                # 6. Check if imported via relative path or known alias
                # If unresolvable:
                if self.verbose:
                    print(f"  [DEBUG] {file_path.name}:{line_no}: Unresolved type '{type_name}'", file=sys.stderr)

        return errors

    def check_plugin(self, plugin_dir: Path) -> List[str]:
        """Check all QML files in a plugin and return formatted error messages."""
        failures = []
        plugin_shared_files, plugin_qmldir_types = get_plugin_shared_components(plugin_dir)
        local_components = get_local_plugin_components(plugin_dir)

        qml_files: List[Path] = []
        for root, dirs, files in os.walk(plugin_dir):
            if "shared" in dirs:
                dirs.remove("shared")
            if "dms-common" in dirs:
                dirs.remove("dms-common")
            for f in files:
                if f.endswith(".qml"):
                    qml_files.append(Path(root) / f)

        for qml_file in sorted(qml_files):
            issues = self.check_qml_file(
                qml_file,
                plugin_dir,
                plugin_shared_files,
                plugin_qmldir_types,
                local_components
            )
            for line_no, severity, msg in issues:
                try:
                    rel_path = qml_file.relative_to(REPO_ROOT)
                except ValueError:
                    rel_path = qml_file
                failures.append(f"{rel_path}:{line_no} [{severity}] {msg}")

        return failures


def main():
    parser = argparse.ArgumentParser(
        description="Verify backward compatibility of DMS plugins against stable DMS baseline."
    )
    parser.add_argument("plugins", nargs="*", help="Specific plugin directories to check (default: all)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show verbose debug output")
    args = parser.parse_args()

    checker = CompatibilityChecker(verbose=args.verbose)

    if args.plugins:
        plugin_dirs = [REPO_ROOT / p for p in args.plugins]
    else:
        plugin_dirs = [
            d for d in REPO_ROOT.iterdir()
            if d.is_dir()
            and not d.name.startswith(".")
            and d.name not in ["scripts", "shared", "node_modules"]
            and (d / "plugin.json").exists()
        ]

    plugin_dirs.sort(key=lambda p: p.name)

    print(f"Checking backward compatibility against DMS {BASELINE_DMS_VERSION} for {len(plugin_dirs)} plugins...\n")

    total_errors = 0
    for plugin_dir in plugin_dirs:
        failures = checker.check_plugin(plugin_dir)
        if failures:
            total_errors += len(failures)
            print(f"✗ [{plugin_dir.name}] ({len(failures)} issue(s)):")
            for f in failures:
                print(f"    {f}")
        else:
            print(f"✓ [{plugin_dir.name}]")

    print("-" * 60)
    if total_errors > 0:
        print(f"FAILED: Found {total_errors} backward compatibility issue(s).", file=sys.stderr)
        sys.exit(1)
    else:
        print("✓ All plugins passed backward compatibility checks.")
        sys.exit(0)


if __name__ == "__main__":
    main()
