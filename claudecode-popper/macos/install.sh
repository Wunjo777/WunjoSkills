#!/usr/bin/env bash
# Claude Code Popper - macOS Installer
# One-line: curl -fsSL https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/macos/install.sh | bash

set -e

REPO_BASE="https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master"
INSTALL_DIR="$HOME/.claude/claudecode-popper"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "Claude Code Popper - macOS Installer"

# 1. Create install directory
mkdir -p "$INSTALL_DIR"
echo "[OK] Created $INSTALL_DIR"

# 2. Check dependencies
if ! command -v jq &>/dev/null; then
    echo "[WARN] jq not found. Install for config.json support."
    echo "  brew install jq"
fi

# 3. Download files
for f in popup.sh config.json uninstall.sh; do
    curl -fsSL "$REPO_BASE/macos/$f" -o "$INSTALL_DIR/$f"
    echo "[OK] Downloaded $f"
done
chmod +x "$INSTALL_DIR/popup.sh" "$INSTALL_DIR/uninstall.sh"

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
echo "Done! Restart Claude Code to see popups."
echo "Edit config: $INSTALL_DIR/config.json"
echo "Uninstall:   bash $INSTALL_DIR/uninstall.sh"
