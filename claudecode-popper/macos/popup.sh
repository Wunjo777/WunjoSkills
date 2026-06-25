#!/usr/bin/env bash
# Claude Code Popup Notification - macOS
# Reads config from config.json in the same directory.
# Supports remote mode: sends via TCP to local machine if CLAUDE_REMOTE_PORT is set.
# Uses osascript (built-in) for native notifications.

HOOK_NAME="${CLAUDE_HOOK_NAME:-Stop}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"

TITLE="Claude Code"
MESSAGE="任务完成"
SOUND=true
REMOTE_PORT="${CLAUDE_REMOTE_PORT:-}"
FALLBACK_LOCAL=true

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

    # Read remote config (env var takes precedence)
    if [ -z "$REMOTE_PORT" ]; then
        port=$(jq -r '.remote.port // empty' "$CONFIG_FILE" 2>/dev/null)
        [ -n "$port" ] && REMOTE_PORT="$port"
    fi
    fallback=$(jq -r '.remote.fallback_to_local // empty' "$CONFIG_FILE" 2>/dev/null)
    [ -n "$fallback" ] && FALLBACK_LOCAL="$fallback"
fi

# Args override config
[ -n "$1" ] && TITLE="$1"
[ -n "$2" ] && MESSAGE="$2"

# Remote mode: try TCP send to local machine
if [ -n "$REMOTE_PORT" ]; then
    send_remote() {
        local msg="${TITLE}|||${MESSAGE}"
        if command -v nc &>/dev/null; then
            echo "$msg" | nc -q 1 localhost "$REMOTE_PORT" 2>/dev/null
            return $?
        fi
        return 1
    }

    if send_remote; then
        exit 0
    fi

    # TCP failed
    if [ "$FALLBACK_LOCAL" != "true" ]; then
        echo "[Claude Code Popper] Remote send failed (port $REMOTE_PORT). Is listener running locally?"
        exit 1
    fi
    # Fall through to local notification
fi

# Build sound clause
SOUND_CLAUSE=""
if [ "$SOUND" = "true" ]; then
    SOUND_CLAUSE='sound name "Glass"'
fi

# Show native macOS notification
osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" $SOUND_CLAUSE"
