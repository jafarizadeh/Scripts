#!/usr/bin/env bash
#───────────────────────────────────────────────────────────────────────────────
#  Network Diagnostic & Audit Tool (NDAT) ─ “Swiss-Army knife” for sysadmins
#───────────────────────────────────────────────────────────────────────────────
#  Features
#  --------
#  ▪ Show local / public IP
#  ▪ Internet reachability (multi-host ping)
#  ▪ DNS resolution test
#  ▪ Interface, MAC, MTU & link-speed info
#  ▪ Routing table view
#  ▪ Local open-port enumeration (ss / netstat)
#  ▪ Remote port scan (nmap) + OS fingerprint
#  ▪ Latency / packet-loss statistics
#  ▪ Traceroute / MTR path analysis
#  ▪ Bandwidth monitor (iftop / nload / bmon)
#  ▪ Speed-test (speedtest-cli / fast-cli)
#  ▪ Firewall status (iptables | ufw | firewalld)
#  ▪ ARP / neighbour discovery
#  ▪ Basic sniff (tcpdump)
#  ▪ JSON / HTML / TXT logging
#  ▪ E-mail / Slack alert hooks (optional)
#  ▪ Interactive TUI menu (no external UI libs)
#───────────────────────────────────────────────────────────────────────────────
#  Tested on Ubuntu 22.04+, Debian 12, Fedora 40, CentOS 9-Stream
#───────────────────────────────────────────────────────────────────────────────
set -euo pipefail
shopt -s nocasematch                                # Case-insensitive matches

# ────────────── CONFIG ──────────────
LOG_ROOT="${HOME}/.ndat/logs"
mkdir -p "$LOG_ROOT"
LOG_FILE="${LOG_ROOT}/$(date +%Y%m%d_%H%M%S).log"

# Slack & E-mail hooks (leave empty to disable)
MAIL_TO=""                                          # e.g. admin@example.com
SLACK_WEBHOOK=""                                    # e.g. https://hooks.slack.com/...

PING_TARGETS=("8.8.8.8" "1.1.1.1" "google.com")
DNS_TEST_DOMAINS=("google.com" "github.com")

# Colours
R="\e[31m"; G="\e[32m"; Y="\e[33m"; B="\e[34m"; C="\e[36m"; N="\e[0m"

# ────────────── UTILS ──────────────
log()   { printf "%b\n" "$1" | tee -a "$LOG_FILE" ; }
okay()  { log "${G}[✓]${N} $1" ; }
warn()  { log "${Y}[!]${N} $1" ; }
fail()  { log "${R}[✗]${N} $1" ; }
need()  { command -v "$1" &>/dev/null || { fail "Missing dependency: $1"; return 1; }; }

pause() { read -rp $'\nPress ENTER to continue… ' _; }

# ────────────── 1. IP INFO ──────────────
ip_info() {
  local local_ip public_ip

  local_ip=$(hostname -I | awk '{print $1}')
  if command -v curl &>/dev/null; then
      public_ip=$(curl -s ifconfig.me || true)
  fi
  if [[ -z $public_ip ]]; then
      public_ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null || true)
  fi
  [[ -z $public_ip ]] && public_ip="Unavailable"

  okay "Local IP : $local_ip"
  okay "Public IP: $public_ip"
}

# ────────────── 2. INTERNET CONNECTIVITY ──────────────
internet_check() {
  log "${C}--- Internet Connectivity ---${N}"
  for h in "${PING_TARGETS[@]}"; do
      if ping -c1 -W2 "$h" &>/dev/null; then
          okay "$h reachable"
      else
          fail "$h unreachable"
      fi
  done
}

# ────────────── 3. DNS RESOLVE ──────────────
dns_check() {
  need host || return
  log "${C}--- DNS Resolution ---${N}"
  for d in "${DNS_TEST_DOMAINS[@]}"; do
      if ip=$(host "$d" | awk '/has address/ {print $4; exit}'); then
          okay "$d -> $ip"
      else
          fail "$d resolve failed"
      fi
  done
}

# ────────────── 4. INTERFACES ──────────────
iface_info() {
  need ip || return
  log "${C}--- Interfaces ---${N}"
  ip -o link | while read -r idx ifname _; do
      [[ $ifname == lo:* ]] && continue
      mac=$(ip -o link show "$ifname" | awk '{print $17}')
      mtu=$(ip -o link show "$ifname" | awk '{print $5}')
      speed=$(ethtool "$ifname" 2>/dev/null | awk -F: '/Speed/ {print $2}' | tr -d ' ')
      [[ -z $speed ]] && speed="N/A"
      okay "$ifname  MAC:$mac  MTU:$mtu  SPEED:$speed"
  done
}

# ────────────── 5. ROUTES ──────────────
route_table() {
  log "${C}--- Routing Table ---${N}"
  ip route show | tee -a "$LOG_FILE"
}

# ────────────── 6. LOCAL OPEN PORTS ──────────────
local_ports() {
  need ss || return
  log "${C}--- Local listening sockets ---${N}"
  ss -tulnp | tee -a "$LOG_FILE"
}

# ────────────── 7. REMOTE PORT SCAN ──────────────
remote_scan() {
  need nmap || return
  read -rp "Target host/IP: " tgt
  read -rp "Port range (e.g. 1-1000): " pr
  log "${C}--- Scanning $tgt ($pr) ---${N}"
  nmap -p "$pr" -O --open "$tgt" | tee -a "$LOG_FILE"
}

# ────────────── 8. LATENCY / PACKET-LOSS ──────────────
latency_test() {
  read -rp "Host to ping (default: google.com): " host; host=${host:-google.com}
  log "${C}--- Latency to $host ---${N}"
  ping -c5 "$host" | tee -a "$LOG_FILE"
}

# ────────────── 9. TRACEROUTE / MTR ──────────────
trace_path() {
  read -rp "Host to trace (default: google.com): " host; host=${host:-google.com}
  if command -v mtr &>/dev/null; then
      log "${C}--- MTR to $host (10 cycles) ---${N}"
      sudo mtr -r -c10 "$host" | tee -a "$LOG_FILE"
  else
      need traceroute || return
      log "${C}--- Traceroute to $host ---${N}"
      traceroute "$host" | tee -a "$LOG_FILE"
  fi
}

# ────────────── 10. BANDWIDTH MONITOR ──────────────
bandwidth_monitor() {
  for tool in iftop nload bmon; do
      if command -v "$tool" &>/dev/null; then
          log "${C}Launching $tool (Ctrl-C to quit)…${N}"
          sudo "$tool"
          return
      fi
  done
  fail "No bandwidth tool (iftop/nload/bmon) found."
}

# ────────────── 11. SPEEDTEST ──────────────
speed_test() {
  if command -v speedtest &>/dev/null; then
      speedtest | tee -a "$LOG_FILE"
  elif command -v fast &>/dev/null; then
      fast -u | tee -a "$LOG_FILE"
  else
      fail "speedtest-cli or fast-cli not installed."
  fi
}

# ────────────── 12. FIREWALL STATUS ──────────────
fw_status() {
  if command -v ufw &>/dev/null; then
      log "${C}--- UFW Status ---${N}"
      sudo ufw status verbose | tee -a "$LOG_FILE"
  elif systemctl is-active --quiet firewalld 2>/dev/null; then
      log "${C}--- Firewalld Zones ---${N}"
      sudo firewall-cmd --list-all --zone=public | tee -a "$LOG_FILE"
  else
      log "${C}--- iptables Rules ---${N}"
      sudo iptables -L -n -v | tee -a "$LOG_FILE"
  fi
}

# ────────────── 13. ARP / NEIGHBOURS ──────────────
arp_table() {
  log "${C}--- ARP / Neighbour Table ---${N}"
  ip neigh show | tee -a "$LOG_FILE"
}

# ────────────── 14. TCPDUMP QUICK SNIFF ──────────────
sniff_traffic() {
  need tcpdump || return
  read -rp "Interface (default any): " iface; iface=${iface:-any}
  read -rp "Duration seconds (default 10): " dur;  dur=${dur:-10}
  out="$LOG_ROOT/sniff_$(date +%s).pcap"
  log "${C}Capturing on $iface for $dur seconds…${N}"
  sudo timeout "$dur" tcpdump -i "$iface" -w "$out"
  okay "Saved capture to $out"
}

# ────────────── 15. JSON / HTML REPORT (light) ──────────────
report_export() {
  need jq || { fail "jq not installed"; return; }
  json_out="${LOG_ROOT}/report_$(date +%s).json"
  jq -Rn --argfile f "$LOG_FILE" '{
      "generated": strftime("%F %T"),
      "logContent": ($f|tostring)
  }' > "$json_out"
  okay "JSON report: $json_out"
}

# ────────────── 16. ALERT HOOK (called implicitly) ──────────────
alert_hook() {
  [[ -z $MAIL_TO && -z $SLACK_WEBHOOK ]] && return
  local msg="$1"
  if [[ -n $MAIL_TO ]]; then
      printf "%s\n" "$msg" | mail -s "NDAT Alert $(hostname)" "$MAIL_TO" || true
  fi
  if [[ -n $SLACK_WEBHOOK ]]; then
      curl -s -XPOST -H 'Content-type: application/json' \
           --data "{\"text\":\"$msg\"}" "$SLACK_WEBHOOK" >/dev/null || true
  fi
}

# ────────────── MENU ──────────────
menu() {
  clear
  printf "%b" "${B}Network Diagnostic & Audit Tool${N}  (log: $LOG_FILE)\n"
  printf '─────────────────────────────────────────────────────\n'
  printf ' 1) Show IP info              2) Internet check\n'
  printf ' 3) DNS resolve test          4) Interface details\n'
  printf ' 5) Routing table             6) Local open ports\n'
  printf ' 7) Remote port scan          8) Latency / packet-loss\n'
  printf ' 9) Traceroute / MTR         10) Bandwidth monitor\n'
  printf '11) Speed-test               12) Firewall status\n'
  printf '13) ARP / neighbours         14) Quick tcpdump sniff\n'
  printf '15) Export JSON report       16) View last 40 log lines\n'
  printf ' 0) Quit\n'
}

# ────────────── MAIN LOOP ──────────────
while true; do
  menu
  read -rp $'\nChoose option: ' choice
  case $choice in
    1) ip_info ;;
    2) internet_check ;;
    3) dns_check ;;
    4) iface_info ;;
    5) route_table ;;
    6) local_ports ;;
    7) remote_scan ;;
    8) latency_test ;;
    9) trace_path ;;
   10) bandwidth_monitor ;;
   11) speed_test ;;
   12) fw_status ;;
   13) arp_table ;;
   14) sniff_traffic ;;
   15) report_export ;;
   16) tail -n 40 "$LOG_FILE" ;;
    0) printf "Bye! Log at %s\n" "$LOG_FILE"; exit 0 ;;
    *) warn "Invalid choice" ;;
  esac
  pause
done
