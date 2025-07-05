#!/usr/bin/env bash
# --------------------------------------------------------------------
# File: ping_test.sh
# Purpose : Ping a single IP address or DNS name to verify reachability
#           and display round-trip-time statistics.
# Usage   : ./ping_test.sh <target>
# Return  : 0 = reachable, 2 = unreachable, 1 = usage error
# --------------------------------------------------------------------
set -euo pipefail

[[ $# -eq 1 ]] || { echo "Usage: $0 <IP_or_FQDN>"; exit 1; }

TARGET="$1"
echo " Pinging $TARGET ..."
if ping -c1 -W2 "$TARGET" &>/dev/null; then
    echo "$TARGET is reachable"
    exit 0
else
    echo "$TARGET is unreachable"
    exit 2
fi
