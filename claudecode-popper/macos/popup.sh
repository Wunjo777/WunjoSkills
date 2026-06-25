#!/usr/bin/env bash
# Claude Code Popup Notification - macOS
# Reads config from config.json in the same directory.
# Uses osascript (built-in) for native notifications.

HOOK_NAME="${CLAUDE_HOOK_NAME:-Stop}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"

TITLE="Claude Code"
MESSAGE="任务完成"
SOUND=true

# Parse config.json
if [ -f "$CONFIG_FILE" ] && command -v jq &>/dev/null; then
    section=$(jq -r "if .${HOOK_NAME,,} then .${HOOK_NAME,,} else .stop end" "$CONFIG_FILE" 2>/dev/null)
    if [ "$section" != "null" ]; then
        t=$(echo "$section" | jq -r '.title // empty')
        m=$(echo "$section" | jq -r '.message // empty')
        s=$(echo "$section" | jq -r '.sound // empty')
        [ -n "$t" ] && TITLE="$t"
        [ -n "$m" ] && MESSAGE="$m"
        [ -n "$s" ] && SOUND="$s"
    fi
fi

# Args override config
[ -n "$1" ] && TITLE="$1"
[ -n "$2" ] && MESSAGE="$2"

# Build sound clause
SOUND_CLAUSE=""
if [ "$SOUND" = "true" ]; then
    SOUND_CLAUSE='sound name "Glass"'
fi

# Show native macOS notification
osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" $SOUND_CLAUSE"
