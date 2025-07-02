# Network Diagnostic & Audit Tool (NDAT)

> **The Swiss‑Army knife for busy sysadmins**  
> One Bash script to collect the 90 % of network facts you need in the first 90 seconds of troubleshooting.

[![shell-check](https://github.com/jafarizadeh/Scripts/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/jafarizadeh/Scripts/actions)  ![license](https://img.shields.io/badge/license-MIT-blue.svg)

---

## Table&nbsp;of&nbsp;Contents
1. [Key Highlights](#key-highlights)
2. [Live Demo](#live-demo)
3. [Quick Start](#quick-start)
4. [Feature Matrix](#feature-matrix)
5. [Dependencies](#dependencies)
6. [Installation](#installation)
7. [Running NDAT](#running-ndat)
8. [Logging & Reports](#logging--reports)
9. [Configuration](#configuration)
10. [Security Notes](#security-notes)
11. [Contribution Guide](#contribution-guide)
12. [Roadmap](#roadmap)
13. [License](#license)

---

## Key Highlights

|   | Capability | Notes |
|---|------------|-------|
| 🎯 | **Unified snapshot** of your host’s network health in *one* run | Interactive TUI **or** choose individual checks
| 📡 | *Both* local & public IP discovery | Uses `curl`, `dig`, or fallback methods
| 🌐 | Multi‑host **reachability**, **DNS** resolution, latency & packet‑loss stats | Targets configurable in the header
| 🔍 | Interface, MAC, MTU, link speed & routing table enumeration | Pure `ip` + `ethtool`—no exotic deps
| 🕳️ | Local **listening sockets**, remote **port scan** (Nmap) & OS fingerprint | Safe defaults (`--open`) to avoid noise
| 🛰️ | Path analysis via traceroute or **MTR** (preferred) | Auto‑selects whichever tool is installed
| 📊 | Live **bandwidth monitors** (`iftop`, `nload`, `bmon`) + CLI **speed‑test** | Launches the first program found
| 🔥 | Firewall status for **UFW**, **firewalld** or raw `iptables` | No external parsers required
| 🕵️ | Quick **tcpdump** capture with time‑boxed timeout | Saves `.pcap` under `~/.ndat/logs`
| 📜 | **JSON** or HTML ready logs for further automation | Optional Slack / e‑mail alert hooks

---

## Live Demo
<details>
<summary>Click to expand</summary>

```text
Network Diagnostic & Audit Tool  (log: /home/alice/.ndat/logs/20250702_143301.log)
───────────────────────────────────────────────────────────────────────────
 1) Show IP info              2) Internet check
 3) DNS resolve test          4) Interface details
 5) Routing table             6) Local open ports
 7) Remote port scan          8) Latency / packet loss
 9) Traceroute / MTR         10) Bandwidth monitor
11) Speed‑test               12) Firewall status
13) ARP / neighbours         14) Quick tcpdump sniff
15) Export JSON report       16) View last 40 log lines
 0) Quit
```

</details>

---

## Quick Start
```bash
# Clone the repo and make the script executable
$ git clone https://github.com/jafarizadeh/Scripts.git && cd Scripts
$ chmod +x network_diagnostic_tool.sh

# Run with default interactive menu
$ ./network_diagnostic_tool.sh
```

> **Tip:** Feel like living dangerously? symlink it into `$PATH` so you can call `ndat` from anywhere:
> ```bash
> sudo ln -s "$PWD/network_diagnostic_tool.sh" /usr/local/bin/ndat
> ```

---

## Feature Matrix

| Option | What it does | Requires |
|--------|--------------|----------|
| 1 | Show local & public IP | `curl` *or* `dig` (fallbacks auto) |
| 2 | Ping 4 configurable hosts | `ping` |
| 3 | DNS resolution for 3 domains | `host` |
| 4 | Interface details (MAC / MTU / speed) | `ip`, `ethtool` (optional) |
| 5 | Routing table | `ip` |
| 6 | Local listening sockets | `ss` |
| 7 | Remote port scan & OS fingerprint | `nmap` |
| 8 | 5‑packet latency test | `ping` |
| 9 | Path trace (MTR > traceroute) | `mtr` *or* `traceroute` |
| 10 | Live bandwidth monitor | `iftop`, `nload`, or `bmon` |
| 11 | CLI speed‑test | `speedtest` *or* `fast` |
| 12 | Firewall status summary | `ufw`, `firewalld` or `iptables` |
| 13 | ARP / neighbour cache | `ip` |
| 14 | 10‑second tcpdump capture | `tcpdump` |
| 15 | Export last run as JSON | `jq` |
| 16 | Tail the current log | — |

---

## Dependencies
NDAT follows a **“graceful degradation”** philosophy: if a binary is missing, that menu entry is hidden or a friendly error is shown—but the rest still works.

| Package | Ubuntu/Debian | Fedora/RHEL | Purpose |
|---------|---------------|------------|---------|
| Base tools | `iproute2` `iputils-ping` | *(pre‑installed)* | Core networking
| `curl` | `curl` | `curl` | Public IP detection
| `dnsutils` | `bind-utils` | DNS tests
| `ethtool` | `ethtool` | Link speed
| `mtr-tiny` | `mtr` | Path analysis
| `nmap` | `nmap` | Remote scan
| `tcpdump` | `tcpdump` | Packet capture
| `jq` | `jq` | JSON report export
| Optional | `iftop` `nload` `bmon` `speedtest-cli` `fast` | Bandwidth & speed‑tests

Install the full stack on Ubuntu:
```bash
sudo apt update && sudo apt install -y iproute2 iputils-ping curl dnsutils ethtool mtr-tiny nmap tcpdump jq iftop nload bmon speedtest-cli
```

---

## Installation
1. **Clone** the repository
2. **Inspect** the script: `less network_diagnostic_tool.sh` (never run random scripts blind!)
3. **Make it executable**: `chmod +x network_diagnostic_tool.sh`
4. *(Optional)* Place into your `$PATH`

For system‑wide use you might want to copy it into `/usr/local/sbin` and restrict write-permissions:
```bash
sudo install -m 755 network_diagnostic_tool.sh /usr/local/sbin/ndat
```

---

## Running NDAT

| Scenario | Command |
|----------|---------|
| Interactive menu | `./network_diagnostic_tool.sh` |
| Preselect a check (e.g., traceroute) | `MENU_CHOICE=9 ./network_diagnostic_tool.sh` |
| Non‑interactive cron run | `CRON=1 ./network_diagnostic_tool.sh > /var/log/ndat.$(date +%F).log` |

> The script currently offers limited flag support; future versions will expose proper CLI options.

---

## Logging & Reports
* **Log directory:** `~/.ndat/logs/` (created automatically)
* **File name pattern:** `YYYYMMDD_HHMMSS.log`
* **JSON export:** Choose option 15 — you’ll get `report_<epoch>.json` with the entire log embedded.
* **HTML export:** Planned for Q4 2025 (see Roadmap).

Slack or e‑mail alerts are triggered automatically whenever NDAT’s own `fail()` function is called. Configure endpoints via environment variables in the *CONFIG* block:
```bash
MAIL_TO="admin@example.com"
SLACK_WEBHOOK="https://hooks.slack.com/services/…"
```

---

## Configuration
Open the script and look for the **CONFIG** section at the top—everything is a plain Bash array or variable:
```bash
LOG_ROOT="$HOME/.ndat/logs"          # Where logs live
PING_TARGETS=("8.8.8.8" "1.1.1.1")  # Reachability tests
DNS_TEST_DOMAINS=("google.com" …)    # DNS checks
```
Feel free to hard‑code values or `export` environment variables before launching to override at runtime.

---

## Security Notes
* Most functions run *read‑only* commands, but several (firewall status, MTR, tcpdump, iftop) require **root privileges**.
* NDAT invokes `sudo` *on demand*; you’ll be prompted multiple times if `sudo` time‑outs. For unattended runs either:
  * Execute the whole script with `sudo`, or
  * Grant password‑less privileges for the specific binaries in `/etc/sudoers`.
* No data ever leaves the host **unless you enable the Slack or e‑mail hooks.**

---

## Contribution Guide
We 💚 contributions! To keep things stable please:
1. **Open an Issue** to propose a feature/fix before the PR
2. **Run ShellCheck** locally: `shellcheck network_diagnostic_tool.sh`
3. **Follow the code style** (snake_case, 2‑space indents, `set -euo pipefail` at top)
4. **Document** new options in this README
5. **Target** the `develop` branch; CI merges into `master` weekly

### Local Dev Workflow
```bash
git checkout -b feature/my-awesome-feature
./test/run-unit-tests.sh   # coming soon
pre-commit run --all-files # lint & format
```

---

## Roadmap
| Quarter | Milestone |
|---------|-----------|
| Q3 2025 | Flag‑based non‑interactive API (`--dns`, `--scan 80-443`, etc.) |
| Q4 2025 | HTML export, Prometheus exporter, container image |
| 2026    | Windows PowerShell port, GUI frontend (Tauri) |

