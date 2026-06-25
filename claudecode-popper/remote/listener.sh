#!/usr/bin/env bash
# Claude Code Popper - Remote Listener (Local Machine)
# Listens on a TCP port for notifications from remote server via SSH reverse tunnel.
# Shows native notifications on your local desktop.
#
# Usage:
#   bash listener.sh [port]
#
# Setup:
#   1. Start this listener in a terminal on your local machine
#   2. SSH to server with reverse tunnel: ssh -R 9876:localhost:9876 user@server
#   3. Use Claude Code on the server — popups appear locally
#
# Dependencies:
#   Linux:  notify-send (libnotify-bin), nc (netcat)
#   macOS:  osascript (built-in), nc (built-in)

PORT="${1:-9876}"

# Detect OS
OS="$(uname)"

# Check dependencies
check_deps() {
    case "$OS" in
        Darwin)
            if ! command -v osascript &>/dev/null; then
                echo "[ERROR] osascript not found. macOS required."
                exit 1
            fi
            if ! command -v nc &>/dev/null; then
                echo "[ERROR] nc (netcat) not found."
                exit 1
            fi
            ;;
        Linux)
            if ! command -v notify-send &>/dev/null; then
                echo "[WARN] notify-send not found. Install: sudo apt install libnotify-bin"
            fi
            if ! command -v nc &>/dev/null; then
                echo "[ERROR] nc (netcat) not found. Install: sudo apt install netcat-openbsd"
                exit 1
            fi
            ;;
        *)
            echo "[ERROR] Unsupported OS: $OS"
            echo "  For Windows, use listener.ps1 instead."
            exit 1
            ;;
    esac
}

show_notification() {
    local title="$1"
    local message="$2"

    case "$OS" in
        Darwin)
            osascript -e "display notification \"$message\" with title \"$title\" sound name \"Glass\"" 2>/dev/null
            ;;
        Linux)
            notify-send -u critical "$title" "$message" 2>/dev/null
            ;;
    esac
}

check_deps

echo "╔══════════════════════════════════════════════════════════╗"
echo "║        Claude Code Popper - Remote Listener             ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Listening on port: $PORT"
echo "║  OS: $OS"
echo "║"
echo "║  Setup SSH tunnel on your server:"
echo "║    ssh -R $PORT:localhost:$PORT user@server"
echo "║"
echo "║  Press Ctrl+C to stop."
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Cleanup on exit
cleanup() {
    echo ""
    echo "[INFO] Listener stopped."
    exit 0
}
trap cleanup INT TERM

while true; do
    # Listen for a single connection, read message
    msg=$(nc -l -p "$PORT" 2>/dev/null || nc -l "$PORT" 2>/dev/null)

    # Skip empty
    [ -z "$msg" ] && continue

    # Strip trailing newlines
    msg=$(echo "$msg" | tr -d '\r\n')

    # Parse protocol: TITLE|||MESSAGE
    if [[ "$msg" == *"|||"* ]]; then
        title="${msg%%|||*}"
        message="${msg#*|||}"
    else
        title="Claude Code"
        message="$msg"
    fi

    # Show notification
    show_notification "$title" "$message"

    # Log
    echo "[$(date '+%H:%M:%S')] $title: $message"
done
