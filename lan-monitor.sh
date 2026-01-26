#!/usr/bin/env bash
# lan-monitor.sh - notify once listing all unavailable hosts (reads hosts from ~/.lan-monitor)
# Behavior:
# - If ~/.lan-monitor is missing: send one notification "No hosts configured" once, then do nothing afterwards.
# - Otherwise: read hosts (ignore blank lines/comments), ping each, notify only when the set of unavailable hosts changes.
# - State stored in ~/.cache/lan-monitor/unavailable_list and ~/.cache/lan-monitor/notified_no_hosts

PING_OPTS="-c1 -W1"
STATE_DIR="$HOME/.cache/lan-monitor"
STATE_FILE="$STATE_DIR/unavailable_list"
NOHOST_FLAG="$STATE_DIR/notified_no_hosts"
HOSTS_FILE="$HOME/.lan-monitor"

mkdir -p "$STATE_DIR"

# If host list file missing -> notify once and exit.
if [ ! -f "$HOSTS_FILE" ]; then
  if [ ! -f "$NOHOST_FLAG" ]; then
    notify-send -u normal "LAN monitor" "No hosts configured in ~/.lan-monitor — create the file with one host per line."
    # create flag so we don't notify again
    : > "$NOHOST_FLAG"
  fi
  exit 0
fi

# If file exists but we previously set the no-hosts flag, remove it (so future deletion re-notifies)
if [ -f "$NOHOST_FLAG" ]; then
  rm -f "$NOHOST_FLAG" 2>/dev/null || true
fi

# Read hosts: strip comments and empty lines
mapfile -t HOSTS < <(sed -e 's/#.*//' -e '/^\s*$/d' "$HOSTS_FILE")

# If after filtering there are no hosts, act like missing file: notify once
if [ ${#HOSTS[@]} -eq 0 ]; then
  if [ ! -f "$NOHOST_FLAG" ]; then
    notify-send -u normal "LAN monitor" "No valid hosts found in ~/.lan-monitor — add IPs or hostnames (one per line)."
    : > "$NOHOST_FLAG"
  fi
  exit 0
fi

# Build current unavailable list (one per line, sorted)
UNAVAILABLE=$(
  for H in "${HOSTS[@]}"; do
    if ! ping $PING_OPTS "$H" >/dev/null 2>&1; then
      echo "$H"
    fi
  done | sort
)

OLD_UNAVAILABLE="$(cat "$STATE_FILE" 2>/dev/null || true)"

if [ "$UNAVAILABLE" != "$OLD_UNAVAILABLE" ]; then
  if [ -n "$UNAVAILABLE" ]; then
    BODY="$(echo "$UNAVAILABLE" | sed 's/^/- /')"
    notify-send -u critical "LAN alert: hosts unreachable" "$BODY"
  else
    notify-send -u normal "LAN: all hosts reachable" "Previously unavailable hosts have recovered"
  fi
  printf '%s\n' "$UNAVAILABLE" > "$STATE_FILE"
fi
