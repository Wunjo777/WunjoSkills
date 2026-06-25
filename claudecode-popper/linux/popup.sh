#!/usr/bin/env bash
# Claude Code Popup Notification - Linux
# Reads config from config.json in the same directory.
# Requires: notify-send (libnotify)

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

# Play sound
if [ "$SOUND" = "true" ]; then
    if command -v paplay &>/dev/null; then
        paplay /usr/share/sounds/freedesktop/stereo/complete.oga &>/dev/null &
    elif command -v aplay &>/dev/null && [ -f /usr/share/sounds/alsa/Front_Center.wav ]; then
        aplay /usr/share/sounds/alsa/Front_Center.wav &>/dev/null &
    fi
fi

# Show notification
if command -v notify-send &>/dev/null; then
    notify-send -u critical "$TITLE" "$MESSAGE"
else
    echo "[Claude Code Popper] notify-send not found. Install: sudo apt install libnotify-bin"
    echo "  $TITLE: $MESSAGE"
fi
