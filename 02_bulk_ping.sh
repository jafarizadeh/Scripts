#!/usr/bin/env bash
# --------------------------------------------------------------------
# File   : bulk_ping.sh
# Purpose: Read a list of IP addresses / hostnames from a text file and
#          ping each in turn, summarising reachability.
# Usage  : ./bulk_ping.sh hosts.txt
# Output : Prints a table (Reachable/Unreachable) and a summary line.
# --------------------------------------------------------------------
set -euo pipefail

[[ $# -eq 1 && -f $1 ]] || { echo "Usage: $0 <host_list_file>"; exit 1; }
mapfile -t HOSTS < "$1"

GOOD=0
BAD=0

printf "%-30s %s\n" "Host" "Status"
printf -- "--------------------------- ---------\n"

for host in "${HOSTS[@]}"; do
    [[ -z "$host" ]] && continue
    if ping -c1 -W1 -q "$host" &>/dev/null; then
        GOOD=$((GOOD + 1))
        printf "%-30s [✓]\n" "$host" 
    else
        BAD=$((BAD + 1))
        printf "%-30s [✗]\n" "$host" 
    fi
done

printf -- "--------------------------- ---------\n"
echo "Summary: $GOOD reachable, $BAD unreachable."
exit $BAD
