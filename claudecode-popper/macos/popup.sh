#!/usr/bin/env bash
# Claude Code Popup Notification - macOS
# Reads config from config.json in the same directory.
# Supports remote mode: TCP tunnel or ntfy.sh push.
# Uses osascript (built-in) for native notifications.

HOOK_NAME="${CLAUDE_HOOK_NAME:-Stop}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"

TITLE="Claude Code"
MESSAGE="任务完成"
SOUND=true
REMOTE_MODE="${CLAUDE_REMOTE_MODE:-}"
REMOTE_PORT="${CLAUDE_REMOTE_PORT:-}"
FALLBACK_LOCAL=true
NTFY_SERVER="https://ntfy.sh"
NTFY_TOPIC="${CLAUDE_NTFY_TOPIC:-}"
NTFY_TOKEN=""
NTFY_PRIORITY="high"
NTFY_TAGS="robot_face"
NTFY_CLICK=""

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
    [ -z "$REMOTE_MODE" ] && { m=$(jq -r '.remote.mode // empty' "$CONFIG_FILE" 2>/dev/null); [ -n "$m" ] && REMOTE_MODE="$m"; }
    [ -z "$REMOTE_PORT" ] && { p=$(jq -r '.remote.port // empty' "$CONFIG_FILE" 2>/dev/null); [ -n "$p" ] && REMOTE_PORT="$p"; }
    fallback=$(jq -r '.remote.fallback_to_local // empty' "$CONFIG_FILE" 2>/dev/null)
    [ -n "$fallback" ] && FALLBACK_LOCAL="$fallback"

    # Read ntfy config
    [ -z "$NTFY_TOPIC" ] && { t=$(jq -r '.ntfy.topic // empty' "$CONFIG_FILE" 2>/dev/null); [ -n "$t" ] && NTFY_TOPIC="$t"; }
    ns=$(jq -r '.ntfy.server // empty' "$CONFIG_FILE" 2>/dev/null); [ -n "$ns" ] && NTFY_SERVER="$ns"
    tk=$(jq -r '.ntfy.token // empty' "$CONFIG_FILE" 2>/dev/null); [ -n "$tk" ] && NTFY_TOKEN="$tk"
    pr=$(jq -r '.ntfy.priority // empty' "$CONFIG_FILE" 2>/dev/null); [ -n "$pr" ] && NTFY_PRIORITY="$pr"
    tg=$(jq -r '.ntfy.tags // empty | if type == "array" then join(",") else . end' "$CONFIG_FILE" 2>/dev/null); [ -n "$tg" ] && NTFY_TAGS="$tg"
    cl=$(jq -r '.ntfy.click // empty' "$CONFIG_FILE" 2>/dev/null); [ -n "$cl" ] && NTFY_CLICK="$cl"
fi

# Args override config
[ -n "$1" ] && TITLE="$1"
[ -n "$2" ] && MESSAGE="$2"

# --- ntfy mode ---
send_ntfy() {
    if ! command -v curl &>/dev/null; then
        echo "[Claude Code Popper] curl not found. Required for ntfy mode."
        return 1
    fi
    if [ -z "$NTFY_TOPIC" ]; then
        echo "[Claude Code Popper] ntfy.topic not configured."
        return 1
    fi

    local headers=(-H "Title: $TITLE" -H "Priority: $NTFY_PRIORITY" -H "Tags: $NTFY_TAGS")
    [ -n "$NTFY_TOKEN" ] && headers+=(-H "Authorization: Bearer $NTFY_TOKEN")
    [ -n "$NTFY_CLICK" ] && headers+=(-H "Click: $NTFY_CLICK")
    [ "$SOUND" = "false" ] && headers+=(-H "X-Disable: yes")

    local http_code
    http_code=$(curl -s -o /dev/null -w '%{http_code}' \
        "${headers[@]}" \
        -d "$MESSAGE" \
        "$NTFY_SERVER/$NTFY_TOPIC" 2>/dev/null)

    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ] 2>/dev/null; then
        return 0
    fi
    return 1
}

# --- tunnel mode ---
send_tunnel() {
    local msg="${TITLE}|||${MESSAGE}"
    if command -v nc &>/dev/null; then
        echo "$msg" | nc -q 1 localhost "$REMOTE_PORT" 2>/dev/null
        return $?
    fi
    return 1
}

# --- route by mode ---
if [ "$REMOTE_MODE" = "ntfy" ]; then
    if send_ntfy; then
        exit 0
    fi
    if [ "$FALLBACK_LOCAL" != "true" ]; then
        echo "[Claude Code Popper] ntfy send failed (server=$NTFY_SERVER topic=$NTFY_TOPIC)."
        exit 1
    fi
    # Fall through to local
elif [ -n "$REMOTE_PORT" ]; then
    if send_tunnel; then
        exit 0
    fi
    if [ "$FALLBACK_LOCAL" != "true" ]; then
        echo "[Claude Code Popper] Remote send failed (port $REMOTE_PORT). Is listener running locally?"
        exit 1
    fi
    # Fall through to local
fi

# Build sound clause
SOUND_CLAUSE=""
if [ "$SOUND" = "true" ]; then
    SOUND_CLAUSE='sound name "Glass"'
fi

# Show native macOS notification
osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" $SOUND_CLAUSE"
