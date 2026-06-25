#!/usr/bin/env bash
# Claude Code Popup Notification - Remote (Server-Side)
# Sends notification via TCP to local machine through SSH reverse tunnel.
# Falls back to local notify-send if TCP send fails and fallback_to_local is true.

HOOK_NAME="${CLAUDE_HOOK_NAME:-Stop}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"

TITLE="Claude Code"
MESSAGE="任务完成"
SOUND=true
REMOTE_PORT=9876
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

    # Read remote config
    port=$(jq -r '.remote.port // empty' "$CONFIG_FILE" 2>/dev/null)
    fallback=$(jq -r '.remote.fallback_to_local // empty' "$CONFIG_FILE" 2>/dev/null)
    [ -n "$port" ] && REMOTE_PORT="$port"
    [ -n "$fallback" ] && FALLBACK_LOCAL="$fallback"
fi

# Env var overrides config
[ -n "$CLAUDE_REMOTE_PORT" ] && REMOTE_PORT="$CLAUDE_REMOTE_PORT"

# Args override config
[ -n "$1" ] && TITLE="$1"
[ -n "$2" ] && MESSAGE="$2"

# Try to send via TCP to local machine (through SSH reverse tunnel)
send_remote() {
    local msg="${TITLE}|||${MESSAGE}"

    # Method 1: bash /dev/tcp
    if (echo "$msg" > /dev/tcp/localhost/"$REMOTE_PORT") 2>/dev/null; then
        return 0
    fi

    # Method 2: nc (netcat)
    if command -v nc &>/dev/null; then
        echo "$msg" | nc -q 1 localhost "$REMOTE_PORT" 2>/dev/null
        return $?
    fi

    # Method 3: ncat
    if command -v ncat &>/dev/null; then
        echo "$msg" | ncat -q 1 localhost "$REMOTE_PORT" 2>/dev/null
        return $?
    fi

    return 1
}

if send_remote; then
    exit 0
fi

# TCP send failed — no tunnel or listener not running
if [ "$FALLBACK_LOCAL" = "true" ]; then
    # Fallback to local notification (useful if server has desktop)
    if [ "$SOUND" = "true" ]; then
        if command -v paplay &>/dev/null; then
            paplay /usr/share/sounds/freedesktop/stereo/complete.oga &>/dev/null &
        elif command -v aplay &>/dev/null && [ -f /usr/share/sounds/alsa/Front_Center.wav ]; then
            aplay /usr/share/sounds/alsa/Front_Center.wav &>/dev/null &
        fi
    fi

    if command -v notify-send &>/dev/null; then
        notify-send -u critical "$TITLE" "$MESSAGE"
    else
        echo "[Claude Code Popper] Remote send failed (port $REMOTE_PORT). Install listener on local machine."
        echo "  $TITLE: $MESSAGE"
    fi
else
    echo "[Claude Code Popper] Remote send failed (port $REMOTE_PORT). Is listener running locally?"
fi
