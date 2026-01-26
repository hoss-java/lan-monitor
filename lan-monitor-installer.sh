#!/usr/bin/env bash
set -e

# Installer for lan-monitor
# Usage: ./lan-monitor-installer.sh --install
#        ./lan-monitor-installer.sh --remove
#
# Installs:
#  - $HOME/.bin/lan-monitor.sh
#  - $HOME/.config/systemd/user/lan-monitor.service
#  - $HOME/.config/systemd/user/lan-monitor.timer
#  - sample hosts file $HOME/.lan-monitor (one IP/hostname per line)
#
# Remove will stop timer, disable service, and delete installed files.

USER_HOME="${HOME}"
BIN_DIR="${USER_HOME}/.bin"
SCRIPT_PATH="${BIN_DIR}/lan-monitor.sh"
STATE_DIR="${USER_HOME}/.cache/lan-monitor"
SVC_DIR="${USER_HOME}/.config/systemd/user"
SERVICE_FILE="${SVC_DIR}/lan-monitor.service"
TIMER_FILE="${SVC_DIR}/lan-monitor.timer"
HOSTS_FILE="${USER_HOME}/.lan-monitor"

print_usage(){
  cat <<EOF
Usage: $0 --install | --remove
--install   Install lan-monitor (creates sample $HOSTS_FILE if missing)
--remove    Uninstall lan-monitor and disable timer/service
EOF
}

install(){
  mkdir -p "$BIN_DIR" "$STATE_DIR" "$SVC_DIR"

  # script
  cat > "$SCRIPT_PATH" <<'SCRIPT'
#!/usr/bin/env bash
# lan-monitor.sh - notify once listing all unavailable hosts (reads hosts from ~/.lan-monitor)
PING_OPTS="-c1 -W1"
STATE_DIR="$HOME/.cache/lan-monitor"
STATE_FILE="$STATE_DIR/unavailable_list"
HOSTS_FILE="$HOME/.lan-monitor"

mkdir -p "$STATE_DIR"

if [ ! -f "$HOSTS_FILE" ]; then
  # nothing to do
  exit 0
fi

# read hosts, ignore empty lines and comments
mapfile -t HOSTS < <(sed -e 's/#.*//' -e '/^\s*$/d' "$HOSTS_FILE")

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
    # prefix each line with "- "
    BODY="$(echo "$UNAVAILABLE" | sed 's/^/- /')"
    notify-send -u critical "LAN alert: hosts unreachable" "$BODY"
  else
    notify-send -u normal "LAN: all hosts reachable" "Previously unavailable hosts have recovered"
  fi
  printf '%s\n' "$UNAVAILABLE" > "$STATE_FILE"
fi
SCRIPT

  chmod +x "$SCRIPT_PATH"

  # systemd unit
  cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=LAN monitor - check hosts and notify on changes

[Service]
Type=oneshot
ExecStart=${SCRIPT_PATH}
EOF

  cat > "$TIMER_FILE" <<EOF
[Unit]
Description=Run LAN monitor every minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1m
Persistent=true

[Install]
WantedBy=timers.target
EOF

  # sample hosts file if absent
  if [ ! -f "$HOSTS_FILE" ]; then
    cat > "$HOSTS_FILE" <<EOF
# Put one IP or hostname per line. Lines starting with # are comments.
192.168.1.50
192.168.1.60
EOF
    chmod 600 "$HOSTS_FILE"
    echo "Created sample hosts file at $HOSTS_FILE (edit to your hosts)."
  fi

  # enable and start systemd user timer
  systemctl --user daemon-reload
  systemctl --user enable --now lan-monitor.timer

  echo "Installed lan-monitor to $SCRIPT_PATH"
  echo "Systemd user timer enabled: lan-monitor.timer"
  echo "Edit hosts in $HOSTS_FILE"
}

remove(){
  # stop timer and disable
  systemctl --user disable --now lan-monitor.timer 2>/dev/null || true
  systemctl --user stop lan-monitor.service 2>/dev/null || true
  systemctl --user daemon-reload

  # remove files
  rm -f "$SCRIPT_PATH" "$SERVICE_FILE" "$TIMER_FILE"
  rm -rf "$STATE_DIR"

  echo "Uninstalled lan-monitor (removed script, service, timer, state)."
  echo "Hosts file $HOSTS_FILE was NOT removed."
}

case "$1" in
  --install) install ;;
  --remove) remove ;;
  *) print_usage; exit 1 ;;
esac
