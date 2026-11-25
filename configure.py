"""Generate deployment settings for one IPv4 endpoint."""
import argparse
import ipaddress
import re
from pathlib import Path


def port(value):
    n = int(value)
    if not 1 <= n <= 65535:
        raise argparse.ArgumentTypeError("port must be between 1 and 65535")
    return n


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--device", type=ipaddress.IPv4Address, required=True)
    p.add_argument("--client", type=ipaddress.IPv4Address, required=True)
    p.add_argument("--interface", required=True)
    p.add_argument("--port", type=port, default=8080)
    p.add_argument("--dashboard-port", type=port, default=8082)
    p.add_argument("--output", type=Path, required=True)
    a = p.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,14}", a.interface):
        p.error("invalid interface")
    if a.device == a.client or a.port == a.dashboard_port:
        p.error("use distinct addresses and distinct ports")
    config = a.output
    config.mkdir(exist_ok=True, parents=True)
    (config / "settings").write_text(
        f"DEVICE={a.device}\nCLIENT={a.client}\nIFACE={a.interface}\nPORT={a.port}\nWEB={a.dashboard_port}\n")
    for mode, action in (("ids", "alert"), ("ips", "drop")):
        (config / f"{mode}.rules").write_text(
            f'{action} http {a.client} any -> {a.device} {a.port} '
            '(msg:"EdgeGuard HTTP test marker"; flow:established,to_server; '
            'http.uri; content:"/lab/blocked"; startswith; endswith; sid:1000001; rev:1;)\n')
    (config / "queue.nft").write_text(f'''table inet edgeguard {{
 chain input {{
  type filter hook input priority 10; policy accept;
  iifname "{a.interface}" ip saddr {a.client} ip daddr {a.device} tcp dport {a.port} queue num 42 bypass
 }}
 chain output {{
  type filter hook output priority 10; policy accept;
  oifname "{a.interface}" ip saddr {a.device} ip daddr {a.client} tcp sport {a.port} queue num 42 bypass
 }}
}}
''')


if __name__ == "__main__":
    main()
