#!/usr/bin/env bash
# --------------------------------------------------------------------
# File   : port_check.sh
# Purpose: Check whether a specified TCP port on a remote host is open
#          using the 'nc' (netcat) utility.
# Usage  : ./port_check.sh <host> <port>
# Return : 0 = open, 2 = closed/unreachable, 1 = usage error
# --------------------------------------------------------------------

set -euo pipefail

[[ $# -eq 1 ]] || { echo "Usage: $0 <port>"; exit 1; }
PORT="$1"

local_ip=$(hostname -I | awk '{print $1}')
public_ip=""

if command -v curl &>/dev/null; then
    public_ip=$(curl -s ifconfig.me || true)
fi
if [[ -z $public_ip ]]; then
    public_ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null || true)
fi

IPS=("$local_ip")
[[ -n $public_ip ]] && IPS+=("$public_ip")

printf "%-20s %s\n" "IP Address" "Port $PORT Status"
printf -- "-------------------- ----------------------\n"

[[ -z "$public_ip" ]] && echo "[!] Public IP unavailable"

for ip in "${IPS[@]}"; do
    if nc -z -w 2 "$ip" "$PORT" &>/dev/null; then
        printf "%-20s [✓] OPEN\n" "$ip"
    else
        printf "%-20s [✗] CLOSED\n" "$ip"
    fi
done
