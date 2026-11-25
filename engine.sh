#!/bin/bash
set -eu
conf=/etc/edgeguard
source "$conf/settings"
mode=$(cat "$conf/mode")
case "$1" in
  run)
    case "$mode" in
      ids) capture=("--pcap=$IFACE");;
      ips) capture=(-q 42);;
      *) exit 1;;
    esac
    exec /usr/bin/suricata -c /etc/suricata/suricata.yaml -S "$conf/$mode.rules" \
      -l /var/log/edgeguard --set unix-command.enabled=no "${capture[@]}"
    ;;
  ready)
    if [[ $mode == ips ]]; then
      for ((i=0;i<150;i++)); do
        if awk '$1==42 {found=1} END {exit !found}' /proc/net/netfilter/nfnetlink_queue 2>/dev/null; then
          nft -f "$conf/queue.nft"
          exit 0
        fi
        sleep 0.2
      done
      exit 1
    fi
    ;;
  cleanup)
    if nft list table inet edgeguard >/dev/null 2>&1; then nft delete table inet edgeguard; fi
    ;;
esac
