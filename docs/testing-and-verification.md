# Testing & Verification Guide

This document describes the workflow for testing, hot-reloading, and linting plugins in `dms-plugins`.

---

## 1. Local Testing Setup

Symlink the plugin folder to your local DMS plugins directory:

```bash
ln -sfn "$PWD/<pluginName>" "$HOME/.config/DankMaterialShell/plugins/<pluginName>"
```

---

## 2. Hot-Reloading via IPC

Do not restart DMS or Quickshell to test plugin changes. Reload directly via IPC:

```bash
dms ipc call plugins reload <pluginName>
```

Verify that the terminal output confirms:
```
PLUGIN_RELOAD_SUCCESS: <pluginName>
```

---

## 3. Interactive Testing via IPC

Exercise plugin actions and modal states directly from your terminal:

```bash
dms ipc call <pluginName> open
dms ipc call <pluginName> close
dms ipc call <pluginName> toggle
```

---

## 4. Linting & Validation Scripts

Before submitting changes, run the repository validation suite:

```bash
# 1. QML syntax check
qmllint <pluginName>/*.qml <pluginName>/shared/*.qml

# 2. Check for unused QML imports
python3 scripts/check_unused_imports.py <pluginName>

# 3. Verify backward compatibility against DMS 1.6.2 (Stable)
python3 scripts/check_compatibility.py <pluginName>
```

All three checks must pass with zero errors.
