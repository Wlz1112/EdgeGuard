#!/bin/bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
if [[ ${1:-} == --help ]]; then
  echo "sudo bash install.sh --device IP --client IP --interface IFACE [--port 8080] [--dashboard-port 8082] [--demo]"
  exit
fi
[[ $EUID == 0 ]] || { echo "Run with sudo" >&2; exit 1; }
args=()
demo=no
for arg in "$@"; do
  if [[ $arg == --demo ]]; then demo=yes; else args+=("$arg"); fi
done
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
python3 configure.py "${args[@]}" --output "$tmp"
source "$tmp/settings"
ip -4 -o addr show dev "$IFACE" | awk '{print $4}' | cut -d/ -f1 | grep -Fxq "$DEVICE" || {
  echo "Assign $DEVICE to $IFACE first." >&2; exit 1;
}
check_port() {
  if ! systemctl is-active --quiet "$2" && [[ -n $(ss -H -ltn "sport = :$1") ]]; then
    echo "TCP $1 already in use. Select another port." >&2; exit 1
  fi
}
check_port "$WEB" edgeguard-dashboard
if [[ $demo == yes ]]; then check_port "$PORT" edgeguard-demo; fi
if [[ -f /etc/edgeguard/settings ]] && ! cmp -s "$tmp/settings" /etc/edgeguard/settings; then
  echo "Existing settings differ. Back up /etc/edgeguard and uninstall before reconfiguring." >&2; exit 1
fi
source /etc/os-release
pkg=suricata
if [[ ${VERSION_CODENAME:-} == trixie && $(dpkg --print-architecture) == arm64 ]]; then
  (cd vendor && sha256sum -c SHA256SUMS)
  deb="$PWD/vendor/suricata-arm64.deb"
  installed=$(dpkg-query -W -f='${Version}' suricata 2>/dev/null || true)
  if [[ -z $installed ]] || dpkg --compare-versions "$installed" le "$(dpkg-deb -f "$deb" Version)"; then pkg="$deb"; fi
fi
apt-get update
apt-get install -y --no-install-recommends "$pkg" nftables python3-flask python3-psutil
install -d -m 755 /opt/edgeguard /etc/edgeguard /var/log/edgeguard/experiment-alerts
install -m 644 dashboard.py dashboard-live.html demo.py /opt/edgeguard/
install -m 755 engine.sh /opt/edgeguard/
install -m 755 edgeguard /usr/local/sbin/edgeguard
install -m 644 "$tmp/settings" "$tmp/queue.nft" /etc/edgeguard/
for mode in ids ips; do
  if [[ ! -e /etc/edgeguard/$mode.rules ]]; then install -m 644 "$tmp/$mode.rules" /etc/edgeguard/; fi
done
install -m 644 systemd/*.service /etc/systemd/system/
systemctl daemon-reload
mode=ids
if [[ -f /etc/edgeguard/mode ]]; then mode=$(cat /etc/edgeguard/mode); fi
/usr/local/sbin/edgeguard "$mode"
systemctl enable edgeguard-dashboard
systemctl restart edgeguard-dashboard
if [[ $demo == yes ]]; then systemctl enable --now edgeguard-demo; fi
python3 - "$DEVICE" "$WEB" <<'PY'
import http.client, sys, time
for attempt in range(20):
    try:
        conn = http.client.HTTPConnection(sys.argv[1], int(sys.argv[2]), timeout=3)
        conn.request("GET", "/api/live")
        if conn.getresponse().status == 200:
            break
    except OSError:
        pass
    time.sleep(0.5)
else:
    sys.exit("Dashboard startup failed. Check journalctl -u edgeguard-dashboard.")
PY
echo "EdgeGuard: http://$DEVICE:$WEB/"
