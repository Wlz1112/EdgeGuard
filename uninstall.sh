#!/bin/bash
set -eu
[[ $EUID == 0 ]] || { echo "Run with sudo"; exit 1; }
for unit in edgeguard-engine edgeguard-demo edgeguard-dashboard; do
  if [[ -f /etc/systemd/system/$unit.service ]]; then
    systemctl disable --now "$unit"
    rm -f "/etc/systemd/system/$unit.service"
  fi
done
systemctl daemon-reload
rm -f /usr/local/sbin/edgeguard /opt/edgeguard/{dashboard.py,dashboard-live.html,engine.sh,demo.py}
echo "Services removed. Settings and evidence retained in /etc/edgeguard and /var/log/edgeguard."
