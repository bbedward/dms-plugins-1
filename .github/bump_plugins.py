#!/usr/bin/env python3
import json
import re
import subprocess
from pathlib import Path

def git_cmd(*args):
    try:
        res = subprocess.run(["git", *args], capture_output=True, text=True, check=True)
        return res.stdout.strip()
    except subprocess.CalledProcessError:
        return ""

def parse_semver(ver_str):
    parts = [int(x) for x in re.findall(r"\d+", str(ver_str or "1.0.0"))]
    while len(parts) < 3:
        parts.append(0)
    return parts[:3]

def clean_commit_msg(msg):
    cleaned = re.sub(r"^(?:[a-zA-Z0-9_-]+\s+)?(?:[a-zA-Z0-9_-]+(?:\([^)]*\))?!*:\s*)", "", msg).strip()
    if cleaned:
        return cleaned[0].upper() + cleaned[1:]
    return msg

author_cache = {}

def get_author_credit(commit_hash, author_name, author_email):
    if "hthienloc" in author_name.lower() or "huynhloc" in author_email.lower():
        return ""

    if author_email in author_cache:
        login = author_cache[author_email]
        if login and login.lower() == "hthienloc":
            return ""
        return f" by @{login}" if login else f" by {author_name}"

    try:
        res = subprocess.run(
            ["gh", "api", f"repos/:owner/:repo/commits/{commit_hash}", "--jq", ".author.login"],
            capture_output=True, text=True, timeout=5
        )
        login = res.stdout.strip()
        if login and login != "null":
            author_cache[author_email] = login
            if login.lower() == "hthienloc":
                return ""
            return f" by @{login}"
    except Exception:
        pass

    author_cache[author_email] = None
    return f" by {author_name}"

def determine_bump_type(commits):
    has_breaking = False
    has_feat = False
    has_fix = False

    for msg in commits:
        msg = msg.strip()
        if not msg:
            continue
        # Breaking change: feat!: or fix!: or BREAKING CHANGE: / BREAKING-CHANGE:
        if re.search(r"BREAKING[- ]CHANGE|^\w+(\(.*?\))?!:", msg):
            has_breaking = True
            break
        elif re.match(r"^feat(\(.*?\))?:", msg):
            has_feat = True
        else:
            has_fix = True

    if has_breaking:
        return "major"
    if has_feat:
        return "minor"
    if has_fix:
        return "patch"
    return None

def bump(parts, bump_type):
    major, minor, patch = parts
    if bump_type == "major":
        return [major + 1, 0, 0]
    elif bump_type == "minor":
        return [major, minor + 1, 0]
    elif bump_type == "patch":
        return [major, minor, patch + 1]
    return parts

updated = []
release_notes = []

for plugin_dir in sorted(Path(".").iterdir()):
    if not plugin_dir.is_dir() or plugin_dir.name.startswith("."):
        continue

    manifest = plugin_dir / "plugin.json"
    if not manifest.exists():
        continue

    # Latest release bump commit touching plugin.json. Plain commits that edit plugin.json
    # (e.g. dependency changes) must not count as a baseline, or earlier fixes are skipped.
    last_bump = git_cmd("log", "-n", "1", "--format=%H", "--grep=^chore(release):", "--", str(manifest))
    range_spec = f"{last_bump}..HEAD" if last_bump else "HEAD"

    # Retrieve commits in plugin_dir since last bump
    raw_log = git_cmd("log", range_spec, "--format=%H%x1f%an%x1f%ae%x1f%s", "--", str(plugin_dir))
    if not raw_log:
        continue

    relevant_commits = []
    for line in raw_log.splitlines():
        parts = line.split("\x1f")
        if len(parts) < 4:
            continue
        h, author, email, subject = parts
        # Skip github-actions bot commits and release bump commits
        if "github-actions" in author.lower() or subject.startswith("chore(release):"):
            continue

        # Check if the commit modified files other than plugin.json
        files = git_cmd("diff-tree", "--no-commit-id", "--name-only", "-r", h, "--", str(plugin_dir)).splitlines()
        if any(f.strip() != str(manifest) for f in files if f.strip()):
            relevant_commits.append((h, author, email, subject))

    if not relevant_commits:
        continue

    bump_type = determine_bump_type([c[3] for c in relevant_commits])
    if not bump_type:
        continue

    try:
        data = json.loads(manifest.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"Error reading {manifest}: {e}")
        continue

    current_ver = data.get("version", "1.0.0")
    next_ver = ".".join(str(x) for x in bump(parse_semver(current_ver), bump_type))

    if current_ver == next_ver:
        continue

    data["version"] = next_ver
    manifest.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    updated.append(f"{plugin_dir.name} ({current_ver} -> {next_ver})")
    print(f"[{bump_type.upper()}] {plugin_dir.name}: {current_ver} -> {next_ver}")

    display_name = data.get("name") or plugin_dir.name
    plugin_notes = [f"### {display_name} ({current_ver} -> {next_ver})\n"]
    seen_commits = set()
    for h, author, email, subject in relevant_commits:
        cleaned = clean_commit_msg(subject)
        credit = get_author_credit(h, author, email)
        entry = f"{cleaned}{credit}"
        if entry not in seen_commits:
            seen_commits.add(entry)
            plugin_notes.append(f"- {entry}\n")
    plugin_notes.append("\n")
    release_notes.extend(plugin_notes)

if updated:
    summary = "\n".join(updated)
    Path(".bump-summary.txt").write_text(summary + "\n", encoding="utf-8")
    notes_body = "".join(release_notes).strip() + "\n"
    Path(".bump-release-notes.md").write_text(notes_body, encoding="utf-8")
    print(f"Updated:\n{summary}")
else:
    print("No plugins require version bump.")
