#!/usr/bin/env bash
# Claude Code Popup Notification - Remote (Server-Side)
# Sends notification to local machine via:
#   - SSH reverse tunnel (TCP)  [mode: tunnel]
#   - ntfy.sh push service      [mode: ntfy]
# Falls back to local notify-send if send fails and fallback_to_local is true.

HOOK_NAME="${CLAUDE_HOOK_NAME:-Stop}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"

TITLE="Claude Code"
MESSAGE="任务完成"
SOUND=true
REMOTE_MODE="tunnel"
REMOTE_PORT=9876
FALLBACK_LOCAL=true
NTFY_SERVER="https://ntfy.sh"
NTFY_TOPIC=""
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

    # Read remote config
    mode=$(jq -r '.remote.mode // empty' "$CONFIG_FILE" 2>/dev/null)
    port=$(jq -r '.remote.port // empty' "$CONFIG_FILE" 2>/dev/null)
    fallback=$(jq -r '.remote.fallback_to_local // empty' "$CONFIG_FILE" 2>/dev/null)
    [ -n "$mode" ] && REMOTE_MODE="$mode"
    [ -n "$port" ] && REMOTE_PORT="$port"
    [ -n "$fallback" ] && FALLBACK_LOCAL="$fallback"

    # Read ntfy config
    ntfy_server=$(jq -r '.ntfy.server // empty' "$CONFIG_FILE" 2>/dev/null)
    ntfy_topic=$(jq -r '.ntfy.topic // empty' "$CONFIG_FILE" 2>/dev/null)
    ntfy_token=$(jq -r '.ntfy.token // empty' "$CONFIG_FILE" 2>/dev/null)
    ntfy_priority=$(jq -r '.ntfy.priority // empty' "$CONFIG_FILE" 2>/dev/null)
    ntfy_tags=$(jq -r '.ntfy.tags // empty | if type == "array" then join(",") else . end' "$CONFIG_FILE" 2>/dev/null)
    ntfy_click=$(jq -r '.ntfy.click // empty' "$CONFIG_FILE" 2>/dev/null)
    [ -n "$ntfy_server" ] && NTFY_SERVER="$ntfy_server"
    [ -n "$ntfy_topic" ] && NTFY_TOPIC="$ntfy_topic"
    [ -n "$ntfy_token" ] && NTFY_TOKEN="$ntfy_token"
    [ -n "$ntfy_priority" ] && NTFY_PRIORITY="$ntfy_priority"
    [ -n "$ntfy_tags" ] && NTFY_TAGS="$ntfy_tags"
    [ -n "$ntfy_click" ] && NTFY_CLICK="$ntfy_click"
fi

# Env var overrides config
[ -n "$CLAUDE_REMOTE_MODE" ] && REMOTE_MODE="$CLAUDE_REMOTE_MODE"
[ -n "$CLAUDE_REMOTE_PORT" ] && REMOTE_PORT="$CLAUDE_REMOTE_PORT"
[ -n "$CLAUDE_NTFY_TOPIC" ] && NTFY_TOPIC="$CLAUDE_NTFY_TOPIC"
[ -n "$CLAUDE_NTFY_SERVER" ] && NTFY_SERVER="$CLAUDE_NTFY_SERVER"

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
        echo "[Claude Code Popper] ntfy.topic not configured. Set in config.json or CLAUDE_NTFY_TOPIC env var."
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

# --- route by mode ---
case "$REMOTE_MODE" in
    ntfy)
        if send_ntfy; then
            exit 0
        fi
        if [ "$FALLBACK_LOCAL" = "true" ]; then
            :  # fall through to local
        else
            echo "[Claude Code Popper] ntfy send failed (server=$NTFY_SERVER topic=$NTFY_TOPIC). Check config."
            exit 1
        fi
        ;;
    tunnel|*)
        if send_tunnel; then
            exit 0
        fi
        if [ "$FALLBACK_LOCAL" != "true" ]; then
            echo "[Claude Code Popper] Remote send failed (port $REMOTE_PORT). Is listener running locally?"
            exit 1
        fi
        # Fall through to local
        ;;
esac

# --- fallback: local notification ---
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
    echo "[Claude Code Popper] Remote send failed. Install listener on local machine or configure ntfy."
    echo "  $TITLE: $MESSAGE"
fi
