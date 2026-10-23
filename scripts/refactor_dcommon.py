#!/usr/bin/env python3
"""
refactor_dcommon.py - Migrate QML plugins from qs.Widgets Dank* wrappers to qs.DCommon.Widgets.

Usage:
    python3 scripts/refactor_dcommon.py
    python3 scripts/refactor_dcommon.py --apply
    python3 scripts/refactor_dcommon.py --check
    python3 scripts/refactor_dcommon.py --apply terrain/ --verbose
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent

DCOMMON_IMPORT = "import qs.DCommon.Widgets"
SHELL_IMPORT = "import qs.Widgets"
MODALS_IMPORT = "import qs.Modals.Common"

TYPE_MAP: Dict[str, str] = {
    "DankActionButton": "DActionButton",
    "DankBlink": "DBlink",
    "DankButton": "DButton",
    "DankButtonGroup": "DButtonGroup",
    "DankCircularImage": "DCircularImage",
    "DankCollapsibleSection": "DCollapsibleSection",
    "DankColorAnimation": "DColorAnimation",
    "DankColorSwatch": "DColorSwatch",
    "DankDropdown": "DDropdown",
    "DankFilterChips": "DFilterChips",
    "DankFlickable": "DFlickable",
    "DankGridView": "DGridView",
    "DankIcon": "DIcon",
    "DankIconPicker": "DIconPicker",
    "DankKeycap": "DKeycap",
    "DankListView": "DListView",
    "DankLocationSearch": "DLocationSearch",
    "DankNFIcon": "DNFIcon",
    "DankNumberStepper": "DNumberStepper",
    "DankRefreshButton": "DRefreshButton",
    "DankRipple": "DRipple",
    "DankScrollbar": "DScrollbar",
    "DankSlider": "DSlider",
    "DankSpinner": "DSpinner",
    "DankSVGIcon": "DSVGIcon",
    "DankTabBar": "DTabBar",
    "DankTextCursor": "DTextCursor",
    "DankTextEdit": "DTextEdit",
    "DankTextField": "DTextField",
    "DankToggle": "DToggle",
    "DankTooltipV2": "DTooltipV2",
}

LOCAL_TYPE_MAP: Dict[str, Tuple[str, str]] = {
    "DankModal": ("DModal", MODALS_IMPORT),
    "DankFloatingWindow": ("DFloatingWindow", SHELL_IMPORT),
}

SHELL_ONLY: Set[str] = {
    "BackdropBlur", "BatteryMeter", "ClockContent", "DAnimatedAlbumArt", "DBackdrop",
    "DContextMenu", "DEditableGrid", "DEditableGridSlot", "DFloatingWindow", "DFocusGrab",
    "DGridEditChrome", "DKeyHints", "DOSD", "DOSDSheet", "DPanelResizer", "DPopout",
    "DPopoutHost", "DResizeGrip", "DSeekbar", "DSlideout", "DTooltip", "DismissZone",
    "EdgeExclusion", "FeatureCard", "HoverDismissTracker", "LauncherLogo", "MaterialWallpaper",
    "MediaArtBackdrop", "MediaArtwork", "MediaBlobHalo", "MorphShape", "PluginGlobalVar",
    "PointerOverflowMarker", "PopoutHoverBodyTracker", "PopoutHoverDismiss", "ReleaseHero",
    "ReleaseNotesCard", "ScrollingText", "SurfaceContentClip", "TransientSurfaceTracker",
    "UserIdentity", "WorkspacePager", "WorkspaceSwitcherModel",
}

DCOMMON_ONLY: Set[str] = {
    "DActionButton", "DAnalogClock", "DBadge", "DBlink", "DBottomSheet", "DButton",
    "DButtonGroup", "DCard", "DCarousel", "DCarouselItem", "DCircularImage", "DClockFace",
    "DClockWidget", "DCollapsibleSection", "DColorAnimation", "DColorButton", "DColorSwatch",
    "DConfirmDialogContent", "DDetailChip", "DDialog", "DDragHandle", "DDropdown", "DEdgeFade",
    "DFab", "DFilterChips", "DFlickable", "DGridView", "DHeroCard", "DHorizontalScrollbar",
    "DIcon", "DIconButton", "DIconPicker", "DKeycap", "DLayer", "DListHighlight", "DListItem",
    "DListRow", "DListView", "DLoadingIndicator", "DLocationSearch", "DMaterialShape",
    "DMaterialWallpaper", "DMonthGrid", "DNFIcon", "DNavigationBar", "DNumberStepper",
    "DOrganicBlob", "DOverlapClockFace", "DPaletteSwatch", "DRefreshButton", "DReorderGroup",
    "DReorderList", "DRingGauge", "DRipple", "DSVGIcon", "DSaturationValuePicker", "DScrollbar",
    "DSearchField", "DShapeHero", "DSlider", "DSparkline", "DSpinner", "DSplitButton", "DTabBar",
    "DTextCursor", "DTextEdit", "DTextField", "DTimePicker", "DToggle", "DTone", "DTooltipHost",
    "DTooltipV2", "DWindowHeader", "WindowCaptureGuard",
}

SHARED_TYPES: Set[str] = {
    "AppIconRenderer", "CachingImage", "FloatingWindowControls", "FocusRing", "M3WaveProgress",
    "NumericText", "StateLayer", "StyledButton", "StyledRect", "StyledText",
    "StyledTextMetrics", "SystemLogo", "WindowBlur",
}

MODAL_TYPES: Set[str] = {"DModal"}


def iter_qml_files(paths: List[Path]) -> List[Path]:
    files: List[Path] = []
    for base in paths:
        if base.is_file() and base.suffix == ".qml":
            files.append(base)
            continue
        for path in sorted(base.rglob("*.qml")):
            if ".git" in path.parts or "node_modules" in path.parts:
                continue
            files.append(path)
    return files


def find_types(text: str, names: Set[str]) -> Set[str]:
    return {name for name in names if re.search(r"\b" + re.escape(name) + r"\b", text)}


def migrate_types(text: str) -> Tuple[str, Dict[str, int]]:
    replaced: Dict[str, int] = {}
    for old, new in sorted(TYPE_MAP.items(), key=lambda item: len(item[0]), reverse=True):
        text, count = re.subn(r"\b" + re.escape(old) + r"\b", new, text)
        if count:
            replaced[old] = count
    for old, (new, _module) in LOCAL_TYPE_MAP.items():
        text, count = re.subn(r"\b" + re.escape(old) + r"\b", new, text)
        if count:
            replaced[old] = count
    return text, replaced


def insert_import(lines: List[str], import_line: str) -> List[str]:
    if import_line in {line.strip() for line in lines}:
        return lines
    for index, line in enumerate(lines):
        if line.strip() == "import qs.Common":
            return lines[:index + 1] + [import_line] + lines[index + 1:]
    last_import = -1
    for index, line in enumerate(lines):
        if line.strip().startswith("import "):
            last_import = index
    lines.insert(last_import + 1, import_line)
    return lines


def replace_import(lines: List[str], old: str, new: str) -> List[str]:
    for index, line in enumerate(lines):
        if line.strip() == old:
            lines[index] = new
            break
    return lines


def plan_imports(text: str) -> Tuple[str, List[str]]:
    used_shell = find_types(text, SHELL_ONLY)
    used_common = find_types(text, DCOMMON_ONLY | SHARED_TYPES)
    used_modal = find_types(text, MODAL_TYPES)
    lines = text.splitlines()
    current = {line.strip() for line in lines}
    actions: List[str] = []
    has_shell = SHELL_IMPORT in current
    has_common = DCOMMON_IMPORT in current
    has_modal = MODALS_IMPORT in current

    if used_shell:
        if not has_shell:
            lines = insert_import(lines, SHELL_IMPORT)
            actions.append("+qs.Widgets")
        if used_common and not has_common:
            lines = insert_import(lines, DCOMMON_IMPORT)
            actions.append("+qs.DCommon.Widgets")
    elif has_shell:
        if used_common:
            lines = replace_import(lines, SHELL_IMPORT, DCOMMON_IMPORT)
            actions.append("qs.Widgets->qs.DCommon.Widgets")
        else:
            lines = [line for line in lines if line.strip() != SHELL_IMPORT]
            actions.append("-qs.Widgets")
    elif used_common and not has_common:
        lines = insert_import(lines, DCOMMON_IMPORT)
        actions.append("+qs.DCommon.Widgets")

    if used_modal and not has_modal:
        lines = insert_import(lines, MODALS_IMPORT)
        actions.append("+qs.Modals.Common")

    trailing = "\n" if text.endswith("\n") else ""
    return "\n".join(lines) + trailing, actions


def find_legacy(text: str) -> Dict[str, int]:
    clean = re.sub(r"/\*.*?\*/|//.*?$", "", text, flags=re.MULTILINE | re.DOTALL)
    found: Dict[str, int] = {}
    for old in list(TYPE_MAP) + list(LOCAL_TYPE_MAP):
        count = len(re.findall(r"\b" + re.escape(old) + r"\b", clean))
        if count:
            found[old] = count
    return found


def check_imports(text: str) -> List[str]:
    problems: List[str] = []
    current = {line.strip() for line in text.splitlines()}
    if find_types(text, DCOMMON_ONLY) and DCOMMON_IMPORT not in current:
        problems.append("uses qs.DCommon.Widgets types without import")
    if find_types(text, MODAL_TYPES) and MODALS_IMPORT not in current:
        problems.append("uses DModal without import qs.Modals.Common")
    return problems


def update_requires_dms(path: Path, value: str) -> bool:
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(r'("requires_dms"\s*:\s*)"[^"]*"')
    if pattern.search(text):
        new_text = pattern.sub(lambda match: match.group(1) + json.dumps(value), text, count=1)
    else:
        match = re.search(r'(\n[ \t]*"version"\s*:\s*"[^"]*",)', text)
        if not match:
            raise ValueError(f"Cannot locate insertion point in {path}")
        new_text = text[:match.end()] + f'\n  "requires_dms": {json.dumps(value)},' + text[match.end():]
    if new_text != text:
        json.loads(new_text)
        path.write_text(new_text, encoding="utf-8")
        return True
    return False


def get_requires_dms(path: Path) -> str:
    return json.loads(path.read_text(encoding="utf-8")).get("requires_dms", "")


def main() -> int:
    parser = argparse.ArgumentParser(description="Migrate Dank* widgets to qs.DCommon.Widgets.")
    parser.add_argument("paths", nargs="*", help="Files or directories (default: repository root)")
    parser.add_argument("--apply", action="store_true", help="Write changes to disk")
    parser.add_argument("--check", action="store_true", help="Fail if legacy types or missing imports remain")
    parser.add_argument("--requires-dms", metavar="VERSION", help="Set or verify requires_dms in every plugin.json")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show every file")
    args = parser.parse_args()

    bases = [REPO_ROOT / path for path in args.paths] if args.paths else [REPO_ROOT]
    files = iter_qml_files(bases)
    changed_files = 0
    legacy_total = 0
    legacy_files: List[Tuple[Path, Dict[str, int]]] = []
    import_problems: List[Tuple[Path, List[str]]] = []

    for path in files:
        text = path.read_text(encoding="utf-8")
        legacy = find_legacy(text)
        if legacy:
            legacy_files.append((path, legacy))
            legacy_total += sum(legacy.values())
        if args.check:
            problems = check_imports(text)
            if problems:
                import_problems.append((path, problems))

        new_text, replaced = migrate_types(text)
        if not replaced:
            continue
        new_text, actions = plan_imports(new_text)
        changed_files += 1
        if args.verbose or not args.check:
            rel = path.relative_to(REPO_ROOT)
            detail = ", ".join(f"{old}x{count}" for old, count in sorted(replaced.items()))
            import_detail = f" [{', '.join(actions)}]" if actions else ""
            print(f"{'WRITE' if args.apply else 'DRY  '} {rel}: {detail}{import_detail}")
        if args.apply and new_text != text:
            path.write_text(new_text, encoding="utf-8")

    manifests = sorted(REPO_ROOT.glob("*/plugin.json"))
    metadata_changes = 0
    metadata_issues: List[Tuple[Path, str]] = []

    if args.requires_dms:
        for path in manifests:
            current = get_requires_dms(path)
            if args.check:
                if current != args.requires_dms:
                    metadata_issues.append((path, current))
            elif current != args.requires_dms:
                metadata_changes += 1
                rel = path.relative_to(REPO_ROOT)
                print(f"{'WRITE' if args.apply else 'DRY  '} {rel}: requires_dms {current or '-'} -> {args.requires_dms}")
                if args.apply:
                    update_requires_dms(path, args.requires_dms)

    if args.check:
        for path, legacy in legacy_files:
            rel = path.relative_to(REPO_ROOT)
            detail = ", ".join(f"{old}x{count}" for old, count in sorted(legacy.items()))
            print(f"LEGACY {rel}: {detail}", file=sys.stderr)
        for path, problems in import_problems:
            rel = path.relative_to(REPO_ROOT)
            print(f"IMPORT {rel}: {'; '.join(problems)}", file=sys.stderr)
        for path, current in metadata_issues:
            rel = path.relative_to(REPO_ROOT)
            print(f"METADATA {rel}: requires_dms '{current}' != '{args.requires_dms}'", file=sys.stderr)
        if legacy_total or import_problems or metadata_issues:
            print(
                f"FAILED: {legacy_total} legacy type occurrence(s) in {len(legacy_files)} file(s), "
                f"{len(import_problems)} import issue(s), {len(metadata_issues)} metadata issue(s).",
                file=sys.stderr,
            )
            return 1
        print(
            f"OK: no legacy widget types or import issues in {len(files)} file(s), "
            f"{len(manifests)} plugin manifest(s) checked."
        )
        return 0

    mode = "Applied" if args.apply else "Dry run"
    print(
        f"{mode}: {changed_files} file(s), "
        f"{legacy_total} legacy occurrence(s) in {len(legacy_files)} file(s) before migration, "
        f"{metadata_changes} manifest(s) to update."
    )
    if not args.apply:
        print("Re-run with --apply to write changes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
