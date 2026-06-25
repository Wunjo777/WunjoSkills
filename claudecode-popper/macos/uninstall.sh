#!/usr/bin/env bash
# Claude Code Popper - macOS Uninstaller
# One-line: curl -fsSL https://raw.githubusercontent.com/Wunjo777/WunjoAgentTools/master/macos/uninstall.sh | bash

set -e

INSTALL_DIR="$HOME/.claude/claudecode-popper"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "Claude Code Popper - macOS Uninstaller"

# 1. Remove hooks from settings.json
if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"

    for EVENT in Notification Stop; do
        HAS=$(jq -r --arg e "$EVENT" '
            (.hooks[$e] // []) | map(.hooks[]?.command // "") | map(select(test("claudecode-popper.*popup\\.sh"))) | length
        ' "$SETTINGS_FILE" 2>/dev/null)

        if [ "$HAS" -gt 0 ] 2>/dev/null; then
            jq --arg e "$EVENT" '
                .hooks[$e] = [.hooks[$e][] | select([.hooks[]?.command // ""] | map(select(test("claudecode-popper.*popup\\.sh"))) | length == 0)]
                | if .hooks[$e] | length == 0 then del(.hooks[$e]) else . end
            ' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
            echo "[OK] Removed $EVENT hook"
        fi
    done

    echo "[OK] Patched settings.json"
elif [ -f "$SETTINGS_FILE" ]; then
    echo "[WARN] jq not available. Remove hooks manually from $SETTINGS_FILE"
fi

# 2. Remove install directory
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "[OK] Removed $INSTALL_DIR"
fi

echo ""
echo "Done! Restart Claude Code."
