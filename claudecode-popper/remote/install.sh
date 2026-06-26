#!/usr/bin/env bash
# Claude Code Popper - Remote Installer (Server-Side)
# Installs the remote popup script on the server.
# Supports two notification modes:
#   - tunnel: SSH reverse tunnel + TCP (requires local listener)
#   - ntfy:   ntfy.sh push service (no listener needed)
#
# One-line: curl -fsSL https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper/remote/install.sh | bash

set -e

REPO_BASE="https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/claudecode-popper"
INSTALL_DIR="$HOME/.claude/claudecode-popper"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "Claude Code Popper - Remote Installer"
echo "======================================"
echo ""

# 1. Create install directory
mkdir -p "$INSTALL_DIR"
echo "[OK] Created $INSTALL_DIR"

# 2. Check dependencies
if ! command -v jq &>/dev/null; then
    echo "[WARN] jq not found. Install for config.json support."
    echo "  Ubuntu/Debian: sudo apt install jq"
    echo "  Fedora:        sudo dnf install jq"
    echo "  Arch:          sudo pacman -S jq"
fi

# 3. Download files
curl -fsSL "$REPO_BASE/remote/popup.sh" -o "$INSTALL_DIR/popup.sh"
echo "[OK] Downloaded popup.sh"

# config.json is in repo root, not in remote/
curl -fsSL "$REPO_BASE/config.json" -o "$INSTALL_DIR/config.json"
echo "[OK] Downloaded config.json"
chmod +x "$INSTALL_DIR/popup.sh"

# Also download the local uninstaller if not present
if [ ! -f "$INSTALL_DIR/uninstall.sh" ]; then
    curl -fsSL "$REPO_BASE/linux/uninstall.sh" -o "$INSTALL_DIR/uninstall.sh"
    chmod +x "$INSTALL_DIR/uninstall.sh"
    echo "[OK] Downloaded uninstall.sh"
fi

# 4. Patch settings.json
HOOK_CMD="bash \\\"$INSTALL_DIR/popup.sh\\\""

if [ -f "$SETTINGS_FILE" ]; then
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"
else
    echo '{}' > "$SETTINGS_FILE"
fi

if command -v jq &>/dev/null; then
    for EVENT in Notification Stop; do
        EXISTS=$(jq -r --arg e "$EVENT" '
            (.hooks[$e] // []) | map(.hooks[]?.command // "") | map(select(test("claudecode-popper.*popup\\.sh"))) | length
        ' "$SETTINGS_FILE" 2>/dev/null)

        if [ "$EXISTS" -gt 0 ] 2>/dev/null; then
            echo "[SKIP] $EVENT hook already exists"
        else
            jq --arg e "$EVENT" --arg cmd "$HOOK_CMD" '
                .hooks[$e] = ((.hooks[$e] // []) + [{"hooks": [{"type": "command", "command": $cmd}]}])
            ' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
            echo "[OK] Added $EVENT hook"
        fi
    done
else
    echo "[WARN] jq not available. Add hooks manually to $SETTINGS_FILE"
    echo "  \"Notification\": [{\"hooks\": [{\"type\": \"command\", \"command\": \"bash \\\"$INSTALL_DIR/popup.sh\\\"\"}]}]"
    echo "  \"Stop\": [{\"hooks\": [{\"type\": \"command\", \"command\": \"bash \\\"$INSTALL_DIR/popup.sh\\\"\"}]}]"
fi

echo "[OK] Patched settings.json"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                      Setup Complete!                        ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║                                                            ║"
echo "║  Choose a notification mode in config.json:                ║"
echo "║    $INSTALL_DIR/config.json                                ║"
echo "║                                                            ║"
echo "║  ┌─────────────────────────────────────────────────────┐   ║"
echo "║  │ Mode: ntfy (recommended — no listener needed)       │   ║"
echo "║  ├─────────────────────────────────────────────────────┤   ║"
echo "║  │ 1. Install ntfy app on your phone/desktop          │   ║"
echo "║  │    https://ntfy.sh/#app                            │   ║"
echo "║  │ 2. Edit config.json:                               │   ║"
echo "║  │    \"remote\": { \"mode\": \"ntfy\" }                     │   ║"
echo "║  │    \"ntfy\": { \"topic\": \"your-unique-topic-name\" }    │   ║"
echo "║  │ 3. Subscribe to the same topic in the ntfy app     │   ║"
echo "║  │ 4. Restart Claude Code                             │   ║"
echo "║  └─────────────────────────────────────────────────────┘   ║"
echo "║                                                            ║"
echo "║  ┌─────────────────────────────────────────────────────┐   ║"
echo "║  │ Mode: tunnel (SSH reverse tunnel + TCP)             │   ║"
echo "║  ├─────────────────────────────────────────────────────┤   ║"
echo "║  │ 1. On LOCAL machine, download and run listener:    │   ║"
echo "║  │    Linux/macOS:                                    │   ║"
echo "║  │      mkdir -p ~/.claude/claudecode-popper          │   ║"
echo "║  │      curl -fsSL $REPO_BASE/remote/listener.sh \\    │   ║"
echo "║  │        -o ~/.claude/claudecode-popper/listener.sh  │   ║"
echo "║  │      bash ~/.claude/claudecode-popper/listener.sh  │   ║"
echo "║  │    Windows (PowerShell):                           │   ║"
echo "║  │      ...\\listener.ps1 (see README)                 │   ║"
echo "║  │ 2. SSH with reverse tunnel:                        │   ║"
echo "║  │    ssh -R 9876:localhost:9876 user@this-server     │   ║"
echo "║  │ 3. Restart Claude Code                             │   ║"
echo "║  └─────────────────────────────────────────────────────┘   ║"
echo "║                                                            ║"
echo "║  Edit config: $INSTALL_DIR/config.json                     ║"
echo "║  Uninstall:   bash $INSTALL_DIR/uninstall.sh               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
