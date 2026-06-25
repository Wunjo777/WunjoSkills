#!/usr/bin/env bash
# Claude Code Popper - Remote Installer (Server-Side)
# Installs the remote popup script on the server.
# Notifications will be sent to your local machine via SSH reverse tunnel.
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
for f in popup.sh config.json; do
    curl -fsSL "$REPO_BASE/remote/$f" -o "$INSTALL_DIR/$f"
    echo "[OK] Downloaded $f"
done
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
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    Setup Complete!                       ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║                                                          ║"
echo "║  Next steps:                                             ║"
echo "║                                                          ║"
echo "║  1. On your LOCAL machine, download and run the          ║"
echo "║     listener script:                                     ║"
echo "║                                                          ║"
echo "║     Linux/macOS:                                         ║"
echo "║       curl -fsSL $REPO_BASE/remote/listener.sh \\         ║"
echo "║         -o ~/listener.sh && bash ~/listener.sh           ║"
echo "║                                                          ║"
echo "║     Windows (PowerShell):                                ║"
echo "║       irm $REPO_BASE/remote/listener.ps1 | iex           ║"
echo "║                                                          ║"
echo "║  2. When connecting to this server via SSH, use:         ║"
echo "║                                                          ║"
echo "║     ssh -R 9876:localhost:9876 user@this-server          ║"
echo "║                                                          ║"
echo "║  3. Restart Claude Code on this server.                  ║"
echo "║                                                          ║"
echo "║  Edit config: $INSTALL_DIR/config.json                   ║"
echo "║  Uninstall:   bash $INSTALL_DIR/uninstall.sh             ║"
echo "╚══════════════════════════════════════════════════════════╝"
