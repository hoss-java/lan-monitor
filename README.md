## lan-monitor
Simple user-level LAN host monitor that pings hosts listed in ~/.lan-monitor and shows GNOME desktop notifications when hosts become unreachable or when they recover.

### Features
- Reads target hosts from ~/.lan-monitor (one IP or hostname per line; supports comments with #).
- Notifies once when the set of unreachable hosts changes, listing all unreachable hosts together.
- Sends a single one-time notification if ~/.lan-monitor is missing or contains no valid hosts.
- Runs as a systemd --user timer (default: every 1 minute).
- Installer script supports --install and --remove and places the monitor script in ~/.bin.

### Files installed
- ~/.bin/lan-monitor.sh — main monitoring script
- ~/.config/systemd/user/lan-monitor.service — systemd user service unit
- ~/.config/systemd/user/lan-monitor.timer — systemd user timer unit
- ~/.lan-monitor — sample hosts file (created on install if missing)
- ~/.cache/lan-monitor/ — state directory (stores unavailable_list and notified_no_hosts)

### Requirements
- Linux desktop with systemd --user (typical modern Ubuntu/GNOME).
- notify-send (libnotify-bin) to show desktop notifications: sudo apt install libnotify-bin
- ping utility (iputils-ping) installed (standard).

### Installation
1. Save the provided installer script (lan-monitor-installer.sh) and make it executable:
```
chmod +x lan-monitor-installer.sh
```
2. Run installer:
```
./lan-monitor-installer.sh --install
```

3. Edit your hosts list:
```
# Add one host per line (IPs or hostnames). Use # for coomments
nano ~/.lan-monitor
```

4. Verify timer/service:
```
systemctl --user status lan-monitor.timer
systemctl --user status lan-monitor.service
```

* Uninstall / Remove (stop and remove installed files): `./lan-monitor-installer.sh --remove`
* OBS!: ~/.lan-monitor (your host list) is not removed by the uninstaller.
*  Behavior details (ping options): `ping -c1 -W1`
* Manual testing (run one check): `~/.bin/lan-monitor.sh`


This will perform one check and may show a notification if the state changed.

### Troubleshooting
- No notifications shown:
  - Ensure you have an active desktop session and notify-send works:
    ```
    notify-send "Test" "Notification test"
    ```
  - Verify systemd user services are running:
    ```
    systemctl --user status lan-monitor.timer
    ```
  - Check logs:
    ```
    journalctl --user -u lan-monitor.service --since "10 minutes ago"
    ```
- Adjusting check interval:
  - Edit `~/.config/systemd/user/lan-monitor.timer` and change `OnUnitActiveSec`, then:
    ```
    systemctl --user daemon-reload
    systemctl --user restart lan-monitor.timer
    ```

### Customization
- Change check behavior by editing `~/.bin/lan-monitor.sh` (PING_OPTS, notification text, etc.).
- Change install path by modifying the installer before running if you prefer a different location.

## License
MIT License

Copyright (c) 2026 Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
