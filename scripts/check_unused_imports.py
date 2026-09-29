#!/usr/bin/env python3
"""
check_unused_imports.py - Detect and optionally remove unused QML import statements in DMS plugins.

Usage:
    python3 scripts/check_unused_imports.py [PATHS...] [--fix] [--verbose]

Examples:
    python3 scripts/check_unused_imports.py emojiPicker/
    python3 scripts/check_unused_imports.py .
    python3 scripts/check_unused_imports.py --fix
"""

import os
import re
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Set, Tuple

# Base fallback symbol mapping for known QML and DMS modules
KNOWN_MODULE_SYMBOLS: Dict[str, Set[str]] = {
    "Quickshell.Io": {
        "IpcHandler", "Process", "File", "Socket", "Pipe", "IoStream", "StandardPaths",
        "FileInfo", "FileWatcher", "SplitParser", "StringParser"
    },
    "Quickshell.Wayland": {
        "WlrLayershell", "WlrLayershellV1", "Toplevel", "GlobalShortcut",
        "ForeignToplevelV1", "VirtualKeyboard"
    },
    "Quickshell.X11": {
        "X11"
    },
    "Quickshell": {
        "Quickshell", "PanelWindow", "Scope", "Variants", "LazyLoader",
        "Screen", "Region", "Wayland", "FloatingWindow", "PopupWindow"
    },
    "QtQuick.Layouts": {
        "RowLayout", "ColumnLayout", "GridLayout", "StackLayout", "Layout"
    },
    "QtQuick.Shapes": {
        "Shape", "ShapePath", "PathLine", "PathCurve", "PathAngleArc",
        "PathSvg", "PathQuad", "PathCubic", "PathArc"
    },
    "QtQuick.Effects": {
        "MultiEffect"
    },
    "QtQuick.Dialogs": {
        "FileDialog", "ColorDialog", "FolderDialog", "FontDialog", "MessageDialog"
    },
    "QtMultimedia": {
        "MediaPlayer", "AudioOutput", "SoundEffect", "VideoOutput"
    },
    "QtCore": {
        "StandardPaths", "Settings", "QByteArray", "QUrl", "QDateTime",
        "QDate", "QTime", "QCryptographicHash"
    },
    "qs.Common": {
        "Theme", "Paths", "Style", "Log", "I18n", "Units", "GSettings",
        "DankAnim", "DankColorAnim", "SpringMotion", "ElevationShadow"
    },
    "qs.Services": {
        "DMSService", "CompositorService", "ToastService", "ClipboardService",
        "AudioService", "BluetoothService", "NetworkService", "BrightnessService",
        "PowerService", "NotificationService", "MediaService", "PluginService",
        "PopoutService", "SessionData", "SettingsData", "DmsAppService",
        "MprisService", "WallpaperService", "IdleService", "Log"
    },
    "qs.Modules.Plugins": {
        "PluginComponent", "PluginService", "PluginSettings",
        "DesktopPluginComponent", "BasePill"
    },
    "qs.Modals.Common": {
        "DankModal", "DankModalHost", "ModalBackground"
    },
    "qs.Modals.FileBrowser": {
        "DankFileBrowser", "FileBrowserModal", "FileBrowserSurfaceModal"
    },
    "qs.Modules.Settings.Widgets": {
        "SettingsCard", "SectionTitle", "ToggleSetting", "SelectionSetting", "SliderSetting"
    },
    "qs.Widgets": {
        "DankButton", "DankActionButton", "DankIcon",
        "DankTextField", "DankDropdown", "DankKeycap", "DankModal", "StyledText",
        "DankCard", "DankGridView", "DankListView", "DankToggle", "FocusRing",
        "StateLayer", "DankTextCursor", "DankAnim", "SpringMotion", "DankFlickable",
        "DankScrollIndicator", "DankTabBar", "DankTabButton", "DankSlider",
        "StyledRect", "StyledTextMetrics", "NumericText", "DankBadge",
        "DankPopout", "DankPopoutHost", "DankTooltip", "DankTooltipHost"
    },
}

# Regex to strip single-line and multi-line comments
COMMENT_RE = re.compile(r'/\*.*?\*/|//.*?$', re.MULTILINE | re.DOTALL)

# Regex to parse import lines
IMPORT_RE = re.compile(
    r'^[ \t]*import[ \t]+(?P<target>"[^"]+"|\'[^\']+\'|[^\s;]+)(?:[ \t]+as[ \t]+(?P<alias>[A-Za-z0-9_]+))?[ \t]*;?[ \t]*$',
    re.MULTILINE
)


def load_dms_tree_symbols():
    """Attempt to discover symbols dynamically from a local DMS clone if present."""
    candidates = [
        Path(__file__).resolve().parent.parent.parent / "DankMaterialShell",
        Path.home() / "Documents/GitHub/DankMaterialShell",
        Path.home() / ".config/DankMaterialShell",
    ]
    for dms_dir in candidates:
        if (dms_dir / "quickshell").is_dir():
            qs_dir = dms_dir / "quickshell"
            # Map directories to modules
            mapping = {
                "qs.Widgets": qs_dir / "Widgets",
                "qs.Common": qs_dir / "Common",
                "qs.Services": qs_dir / "Services",
                "qs.Modules.Plugins": qs_dir / "Modules/Plugins",
                "qs.Modals.Common": qs_dir / "Modals/Common",
                "qs.Modals.FileBrowser": qs_dir / "Modals/FileBrowser",
            }
            for mod_name, mod_dir in mapping.items():
                if mod_dir.is_dir():
                    for qml_file in mod_dir.glob("*.qml"):
                        KNOWN_MODULE_SYMBOLS.setdefault(mod_name, set()).add(qml_file.stem)
            break


def strip_comments(text: str) -> str:
    """Strip comments from QML code to avoid false positive symbol matches."""
    def replacer(match):
        s = match.group(0)
        return '\n' * s.count('\n')
    return COMMENT_RE.sub(replacer, text)


def get_symbols_from_directory(dir_path: Path) -> Set[str]:
    """Collect exported QML types (.qml filenames) from a directory."""
    symbols = set()
    if not dir_path.is_dir():
        return symbols

    for item in dir_path.iterdir():
        if item.is_file() and item.suffix == ".qml":
            symbols.add(item.stem)

    qmldir = dir_path / "qmldir"
    if qmldir.is_file():
        try:
            with open(qmldir, 'r', encoding='utf-8') as f:
                for line in f:
                    parts = line.strip().split()
                    if parts and not parts[0].startswith('#'):
                        if len(parts) >= 2 and parts[0] == "singleton" and len(parts) >= 3:
                            symbols.add(parts[1])
                        elif len(parts) >= 2 and not parts[0].startswith("module"):
                            symbols.add(parts[0])
        except Exception:
            pass

    return symbols


def check_file(file_path: Path, verbose: bool = False) -> List[Tuple[int, str, str]]:
    """
    Check a single .qml file for unused imports.
    Returns list of (line_number, raw_import_statement, reason).
    """
    try:
        content = file_path.read_text(encoding='utf-8')
    except Exception as e:
        if verbose:
            print(f"Error reading {file_path}: {e}", file=sys.stderr)
        return []

    lines = content.splitlines()
    unused: List[Tuple[int, str, str]] = []
    stripped_body = strip_comments(content)

    for idx, line in enumerate(lines, 1):
        m = IMPORT_RE.match(line)
        if not m:
            continue

        target = m.group('target').strip('\'"')
        alias = m.group('alias')

        # Case 1: Aliased import (e.g. `import "foo.js" as Foo` or `import Bar as B`)
        if alias:
            pattern = re.compile(r'\b' + re.escape(alias) + r'\b')
            matches = list(pattern.finditer(stripped_body))
            if len(matches) <= 1:
                unused.append((idx, line.strip(), f"Alias '{alias}' is never used"))
            continue

        # Case 2: Directory import (e.g. `import "./dms-common"`)
        if target.startswith(".") or "/" in target:
            target_dir = (file_path.parent / target).resolve()
            symbols = get_symbols_from_directory(target_dir)
            if not symbols:
                continue

            used = any(re.search(r'\b' + re.escape(sym) + r'\b', stripped_body) for sym in symbols)
            if not used:
                unused.append((idx, line.strip(), f"No types from directory '{target}' are used"))
            continue

        # Case 3: Known module import without alias
        if target in KNOWN_MODULE_SYMBOLS:
            symbols = KNOWN_MODULE_SYMBOLS[target]
            used = any(re.search(r'\b' + re.escape(sym) + r'\b', stripped_body) for sym in symbols)
            if not used:
                unused.append((idx, line.strip(), f"No types from module '{target}' are used"))
            continue

    return unused


def fix_file(file_path: Path, unused_lines: List[int]) -> bool:
    """Remove unused import lines from file."""
    try:
        content = file_path.read_text(encoding='utf-8')
        lines = content.splitlines(keepends=True)
        new_lines = [line for idx, line in enumerate(lines, 1) if idx not in unused_lines]
        file_path.write_text(''.join(new_lines), encoding='utf-8')
        return True
    except Exception as e:
        print(f"Failed to fix {file_path}: {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(description="Detect and optionally fix unused QML imports in DMS plugins.")
    parser.add_argument("paths", nargs="*", default=["."], help="Paths to files or directories to inspect (default: current directory).")
    parser.add_argument("--fix", action="store_true", help="Automatically remove unused import lines.")
    parser.add_argument("-v", "--verbose", action="store_true", help="Show verbose output.")
    args = parser.parse_args()

    load_dms_tree_symbols()

    files_to_check: List[Path] = []
    for p in args.paths:
        path = Path(p)
        if path.is_file() and path.suffix == ".qml":
            files_to_check.append(path)
        elif path.is_dir():
            files_to_check.extend(path.rglob("*.qml"))

    files_to_check = sorted(set(files_to_check))
    total_unused = 0
    files_with_unused = 0
    results: Dict[Path, List[Tuple[int, str, str]]] = {}

    for f in files_to_check:
        unused = check_file(f, verbose=args.verbose)
        if unused:
            results[f] = unused
            total_unused += len(unused)
            files_with_unused += 1

    if not results:
        print("✓ No unused imports found.")
        sys.exit(0)

    print(f"\nFound {total_unused} unused import(s) in {files_with_unused} file(s):\n")
    for file_path, items in results.items():
        rel_path = file_path.relative_to(Path.cwd()) if file_path.is_relative_to(Path.cwd()) else file_path
        print(f"  {rel_path}:")
        for line_no, stmt, reason in items:
            print(f"    Line {line_no:3d}: {stmt:<35} # {reason}")

    if args.fix:
        print("\nApplying fixes...")
        fixed_count = 0
        for file_path, items in results.items():
            line_numbers = [item[0] for item in items]
            if fix_file(file_path, line_numbers):
                fixed_count += 1
                rel_path = file_path.relative_to(Path.cwd()) if file_path.is_relative_to(Path.cwd()) else file_path
                print(f"  ✓ Cleaned {rel_path}")
        print(f"\nFixed {fixed_count} file(s).")
        sys.exit(0)
    else:
        print("\nRun with --fix to automatically remove unused imports.")
        sys.exit(1)


if __name__ == "__main__":
    main()
