#!/usr/bin/env python3
"""
Synchronizes shared UI components from top-level `shared/` to each plugin's `shared/` directory.

- Detects which components from `shared/` are referenced by each plugin (including transitive dependencies).
- Copies only the needed components (plus assets if needed).
- Generates a clean, sorted `qmldir` in each plugin's `shared/` directory.
- Cleans up legacy `dms-common` directories and updates import statements.
"""

import os
import re
import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SOURCE_SHARED = REPO_ROOT / "shared"

def get_available_components(source_dir: Path):
    components = {}
    for f in source_dir.glob("*.qml"):
        components[f.stem] = f
    return components

def get_dependencies_in_file(filepath: Path, available_names: set):
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception:
        return set()

    deps = set()
    for name in available_names:
        # Match word boundary for component type usage: Name { or <Name> or type Name
        pattern = r'\b' + re.escape(name) + r'\b'
        if re.search(pattern, content):
            deps.add(name)
    return deps

def update_imports_in_plugin(plugin_dir: Path):
    """Replaces imports of `dms-common` with `shared` in all QML files."""
    for root, dirs, files in os.walk(plugin_dir):
        # Skip shared directory itself
        if "shared" in dirs:
            dirs.remove("shared")
        if "dms-common" in dirs:
            dirs.remove("dms-common")

        for f in files:
            if f.endswith(".qml"):
                p = Path(root) / f
                try:
                    text = p.read_text(encoding="utf-8")
                    # Replace e.g. import "./dms-common" -> import "./shared"
                    # import "../dms-common" -> import "../shared"
                    # import "../../dms-common" -> import "../../shared"
                    new_text = re.sub(r'import\s+([\'"].*?)dms-common([\'"])', r'import \1shared\2', text)
                    if new_text != text:
                        p.write_text(new_text, encoding="utf-8")
                except Exception as e:
                    print(f"Error processing {p}: {e}")

def sync_plugin(plugin_dir: Path, available_components: dict):
    available_names = set(available_components.keys())

    # 1. Update imports from dms-common -> shared
    update_imports_in_plugin(plugin_dir)

    # 2. Collect all QML files in plugin outside of shared/ and legacy dms-common/
    plugin_qml_files = []
    for root, dirs, files in os.walk(plugin_dir):
        if "shared" in dirs:
            dirs.remove("shared")
        if "dms-common" in dirs:
            dirs.remove("dms-common")
        for file in files:
            if file.endswith(".qml"):
                plugin_qml_files.append(Path(root) / file)

    # 3. Detect direct dependencies
    used_components = set()
    for qml_file in plugin_qml_files:
        used_components.update(get_dependencies_in_file(qml_file, available_names))

    # 4. Resolve transitive dependencies inside shared components
    added_new = True
    while added_new:
        added_new = False
        current_used = list(used_components)
        for comp in current_used:
            comp_file = available_components[comp]
            deps = get_dependencies_in_file(comp_file, available_names)
            for d in deps:
                if d not in used_components:
                    used_components.add(d)
                    added_new = True

    target_shared = plugin_dir / "shared"
    legacy_common = plugin_dir / "dms-common"

    # Remove legacy dms-common if present
    if legacy_common.exists():
        shutil.rmtree(legacy_common)

    if not used_components:
        if target_shared.exists():
            shutil.rmtree(target_shared)
        return 0

    # 5. Populate plugin's shared/ directory
    if target_shared.exists():
        shutil.rmtree(target_shared)
    target_shared.mkdir(parents=True, exist_ok=True)

    qmldir_lines = ["module dms.common"]
    for comp in sorted(used_components):
        src_file = available_components[comp]
        dst_file = target_shared / src_file.name
        shutil.copy2(src_file, dst_file)
        qmldir_lines.append(f"{comp} 1.0 {src_file.name}")

    # Copy assets if FeedbackCard or NoteCard or any component uses them
    src_assets = SOURCE_SHARED / "assets"
    if src_assets.exists() and ("FeedbackCard" in used_components):
        dst_assets = target_shared / "assets"
        shutil.copytree(src_assets, dst_assets)

    qmldir_path = target_shared / "qmldir"
    qmldir_path.write_text("\n".join(qmldir_lines) + "\n", encoding="utf-8")
    return len(used_components)

def main():
    if not SOURCE_SHARED.exists():
        print(f"Error: Canonical shared directory not found at {SOURCE_SHARED}")
        sys.exit(1)

    available_components = get_available_components(SOURCE_SHARED)
    print(f"Found {len(available_components)} available components in {SOURCE_SHARED.name}/")

    plugins = [
        d for d in REPO_ROOT.iterdir()
        if d.is_dir()
        and not d.name.startswith(".")
        and d.name not in ["scripts", "shared", "node_modules"]
        and (d / "plugin.json").exists()
    ]

    plugins.sort(key=lambda p: p.name)
    print(f"Scanning {len(plugins)} plugins...")

    for plugin_dir in plugins:
        count = sync_plugin(plugin_dir, available_components)
        print(f"  [{plugin_dir.name}] -> synchronized {count} components into shared/")

    print("\nSync completed successfully.")

if __name__ == "__main__":
    main()
