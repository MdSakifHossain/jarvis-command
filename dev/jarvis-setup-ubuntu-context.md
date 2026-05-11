# JARVIS SETUP-UBUNTU CONTEXT FILE

# Version: 1.0

# Date: 2026-05-11

# Purpose: Single source of truth for building `jarvis setup-ubuntu` commands

# Give this file + your jarvis script to rebuild the commands exactly as intended.

================================================================================
SECTION 1: COMMAND STRUCTURE (FINAL DECISION)
================================================================================

NO FLAGS. NO --PREFIXES. Natural language subcommands only.

Command pattern:
jarvis setup-ubuntu <step>

Supported commands:
jarvis setup-ubuntu step 1 # PREP phase
jarvis setup-ubuntu step 2 # BUILD phase
jarvis setup-ubuntu step 3 # LOOKS phase (placeholder)
jarvis setup-ubuntu 1 # Alias for "step 1"
jarvis setup-ubuntu 2 # Alias for "step 2"
jarvis setup-ubuntu 3 # Alias for "step 3"
jarvis setup-ubuntu help # Show help text
jarvis setup-ubuntu h # Alias for help

NOT supported (do not implement):
jarvis setup-ubuntu --pre # NO FLAGS
jarvis setup-ubuntu --mid # NO FLAGS
jarvis setup-ubuntu --post # NO FLAGS
jarvis setup-ubuntu --help # NO FLAGS

================================================================================
SECTION 2: EXISTING SCRIPT STYLE TO MATCH
================================================================================

The new code MUST match the existing jarvis script's style exactly:

1. COLORS (already defined in script, do not redefine):
   RESET='\033[0m'
   BOLD='\033[1m'
   DIM='\033[2m'
   ORANGE='\033[38;5;209m'
   BORANGE='\033[1;38;5;209m'
   DIM_ORANGE='\033[2;38;5;209m'
   BWHITE='\033[1;37m'
   BGREEN='\033[1;32m'
   RED='\033[0;31m'
   YELLOW='\033[1;33m'
   BLUE='\033[94m'
   BBLUE='\033[1;94m'

2. LOGGING HELPERS (already defined, use these exactly):
   log_clr_l1() → orange text
   log_clr_l2() → bold orange text
   log_clr_l3() → dim orange text
   log_txt_nm() → normal text
   log_txt_bd() → bold text
   log_txt_dm() → dim text
   log_info() → blue [INFO] prefix
   log_ok() → green checkmark ✔
   log_warn() → yellow warning ⚠
   log_fail() → red [ERROR], prints to stderr, exits 1
   log_label() → orange ▸ + bold white text
   show_divider() → dim orange long line
   divider_small() → dim orange short line

3. BANNER STYLE:
   - show_banner() already exists
   - New commands should NOT call show_banner() unless explicitly needed
   - Use the ╔═══╗ box style for command headers instead

4. ERROR HANDLING:
   - Script uses `set -euo pipefail` at top
   - log_fail() exits with code 1
   - All new functions must be compatible with set -e

5. VARIABLES:
   - script_name="$(basename "$0")" — use this in help text
   - version="1.4.3" — do not change

================================================================================
SECTION 3: STEP 1 — PREP (Human Phase)
================================================================================

Purpose: Open browser tabs for manual downloads. Show checklist.

What it does: 1. Safety check: verify Ubuntu OS 2. Safety check: verify internet connection 3. Open Firefox with 2 tabs: - https://github.com/TheAssassin/AppImageLauncher/releases - https://openrgb.org/releases.html 4. Print checklist telling user what .deb files to download 5. Tell user to run "jarvis setup-ubuntu step 2" when done

What it does NOT do: - Does NOT download anything automatically - Does NOT install anything - Does NOT modify system

Firefox command:
firefox "URL1" "URL2" > /dev/null 2>&1 & disown

Checklist text to display: 1. AppImageLauncher → Look for .deb file (appimagelauncher*\*\_amd64.deb) 2. OpenRGB → Look for .deb file (openrgb*\*\_amd64.deb)

Save location: ~/Downloads

================================================================================
SECTION 4: STEP 2 — BUILD (Full Automation)
================================================================================

Purpose: Everything that can be automated, automated.

SAFETY GUARDS (must run first, in this order): 1. check_ubuntu() — verify lsb_release exists, verify ID is "Ubuntu" 2. check_internet() — ping google.com with 3 second timeout 3. If either fails, call log_fail() and exit

LOGGING: - Create ~/.local/logs/ if not exists - Log file: ~/.local/logs/jarvis-setup-YYYYMMDD-HHMMSS.log - Use `exec > >(tee -a "$LOGFILE") 2>&1` to log everything - Print log file path at start

PHASE 2A — System Foundation: 1. sudo apt update -y 2. sudo apt upgrade -y 3. Create directories (only if missing):
~/.themes
~/.icons
~/.fonts
~/.config/systemd/user 4. Install core tools:
git curl gnome-tweaks gnome-shell-extension-manager
wget apt-transport-https software-properties-common
ca-certificates gnupg lsb-release
openssh-server ufw tree 5. Each step shows log_info() before, log_ok() after

PHASE 2B — Snap Applications (install one by one, warn on failure):
sudo snap install brave
sudo snap install chromium
sudo snap install opera
sudo snap install firefox
sudo snap install obsidian --classic
sudo snap install obs-studio
sudo snap install vlc
sudo snap install qbittorrent-arnatious

    NOTE: Use || log_warn on each, do not fail entire script if one snap fails

PHASE 2C — VSCode (Official Microsoft Apt Repo): 1. Download and add GPG key:
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg 2. Add apt repo:
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null 3. sudo apt update -y 4. sudo apt install -y code 5. Verify: code --version | head -1

PHASE 2D — Google Chrome: 1. Download .deb to /tmp/:
wget -q "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -O "/tmp/google-chrome-stable_current_amd64.deb" 2. Install: sudo apt install -y "/tmp/google-chrome-stable_current_amd64.deb" 3. Clean up: rm -f "/tmp/google-chrome-stable_current_amd64.deb" 4. NOTE: This auto-adds Google's apt repo for future updates

PHASE 2E — Node.js (NodeSource): 1. Add repo: curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash - 2. Install: sudo apt install -y nodejs 3. Verify: node -v and npm -v

PHASE 2F — SSH Server & Firewall: 1. Enable and start SSH:
sudo systemctl enable ssh
sudo systemctl start ssh 2. Verify: systemctl is-active ssh 3. Get IP address:
ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1 4. Configure UFW:
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw --force enable 5. Display SSH command: ssh $(whoami)@$IP_ADDRESS

PHASE 2G — Install .deb files from ~/Downloads: 1. Find all .deb files in ~/Downloads (maxdepth 1) 2. If none found: log_warn + suggest running step 1 3. If found: loop through each, sudo apt install -y "$deb" 4. Use || log_warn if individual .deb fails, do not fail entire script 5. Count and report how many were installed

PHASE 2H — Systemd User Services: 1. Auto-lock service:
File: ~/.config/systemd/user/autolock-session.service
Backup if exists first (backup_if_exists)
Content:
[Unit]
Description=Auto-lock session after login delay
After=graphical-session.target
PartOf=graphical-session.target
[Service]
Type=oneshot
ExecStart=/bin/sh -c 'sleep 3 && loginctl lock-session'
[Install]
WantedBy=default.target

    2. RGB-off service:
        File: ~/.config/systemd/user/openrgb-off.service
        Backup if exists first (backup_if_exists)
        Content:
            [Unit]
            Description=Turn off RAM RGB after login
            [Service]
            Type=oneshot
            ExecStart=/bin/bash -c 'sleep 5 && openrgb --mode static --color 000000 > /dev/null'
            [Install]
            WantedBy=default.target

    3. Register:
        systemctl --user daemon-reload
        systemctl --user enable autolock-session.service
        systemctl --user enable openrgb-off.service
    4. Note: services activate on NEXT login, not immediately

FINAL SUMMARY (display at end):
Print "STEP 2 COMPLETE" with list of everything done
Show [OK] for each completed item
Show [WARN] for any skipped/failed items
Print log file path
Suggest next command: jarvis setup-ubuntu step 3

================================================================================
SECTION 5: STEP 3 — LOOKS (Placeholder)
================================================================================

Purpose: Configure themes, terminal, VSCode appearance.

Current state: NOT IMPLEMENTED. Just a friendly placeholder.

What it displays: - Header banner - "This step is not built yet." - List of what it WILL handle when ready:
_ VSCode minimal theme and settings
_ Terminal fonts and styling \* Ubuntu themes, icons, cursors - "For now, your system is fully functional after Step 2."

Do NOT implement any actual functionality yet.

================================================================================
SECTION 6: HELP TEXT
================================================================================

Command: jarvis setup-ubuntu help

Display using cat heredoc, matching existing help style in script.

Content must include: - Usage examples for all step commands - What each step does (brief) - Safety features list - Example workflow

Use ${script_name} variable for the command name.

================================================================================
SECTION 7: NEW HELPERS TO ADD
================================================================================

These go in the "Helpers" section of the script, before the commands:

check_ubuntu(): - Check if lsb_release exists (command -v) - Run lsb_release -is, verify output is exactly "Ubuntu" - If fail: log_fail with message - If pass: log_ok "OS verified: Ubuntu $(lsb_release -rs)"

check_internet(): - ping -c 1 -W 3 google.com > /dev/null 2>&1 - If fail: log_fail "No internet connection. Connect to WiFi first." - If pass: log_ok "Internet connection active"

ensure_dir(): - Takes one argument: directory path - If dir does not exist: mkdir -p and log_ok - If exists: do nothing (silent)

backup_if_exists(): - Takes one argument: file or directory path - If exists: cp -r to "${file}.backup.$(date +%Y%m%d-%H%M%S)" - log_warn the backup action - If not exists: do nothing (silent)

================================================================================
SECTION 8: COMMAND ROUTER (CASE STATEMENT)
================================================================================

Add to the main case "$SUBCOMMAND" block, BEFORE the \*) catch-all:

    setup-ubuntu)
        local step="${1:-}"
        shift || true

        case "$step" in
            step)
                local num="${1:-}"
                case "$num" in
                    1 | one)   cmd_setup_ubuntu_step_1; exit 0 ;;
                    2 | two)   cmd_setup_ubuntu_step_2; exit 0 ;;
                    3 | three) cmd_setup_ubuntu_step_3; exit 0 ;;
                    *)         show_setup_ubuntu_help; exit 0 ;;
                esac
                ;;
            1)         cmd_setup_ubuntu_step_1; exit 0 ;;
            2)         cmd_setup_ubuntu_step_2; exit 0 ;;
            3)         cmd_setup_ubuntu_step_3; exit 0 ;;
            help | h | --help | -h)
                show_setup_ubuntu_help; exit 0 ;;
            *)
                show_setup_ubuntu_help; exit 0 ;;
        esac
        ;;

================================================================================
SECTION 9: VISUAL OUTPUT SPECIFICATIONS
================================================================================

Step headers must use this exact format:

    ╔══════════════════════════════════════════════════════════════╗
    ║           FRESH UBUNTU SETUP  —  STEP N: NAME                ║
    ╚══════════════════════════════════════════════════════════════╝

Phase headers inside Step 2 must use this exact format:

    ┌─ [2A] Phase Name ─────────────────────────────────────────┐

Use log_clr_l2 for the box borders, log_clr_l1 for phase headers.

Summary at end of Step 2: - show_divider() before summary - log_clr_l2 " ✅ STEP 2 COMPLETE — Here's what happened:" - Each item as log_ok() - Any warnings as log_warn() - log_txt_dm for "Next:" suggestion

================================================================================
SECTION 10: WHAT NOT TO DO
================================================================================

1. NO --flags. Ever. Only natural language: step 1, step 2, help.
2. NO dry-run mode. Not requested.
3. NO confirmation prompts. The safety guards are the checks at start.
4. NO root check at script level. Use sudo only where needed.
5. NO reboot command. Never ask user to reboot.
6. NO snap loop with single command. Install snaps one by one with individual log_info/log_ok.
7. NO modification of existing commands (lights, lock, unlock, etc.).
8. NO show_banner() call in new commands.
9. NO WARP client setup. Not included in this version.
10. NO gnome-boxes installation. Not included in this version.

================================================================================
SECTION 11: FILES REFERENCED (EXISTING)
================================================================================

These are the user's existing notes for context only:

- Fresh-Ubuntu-Install.md: Original manual checklist (now being automated)
- Lock-After-Auto-Login.md: Systemd auto-lock service (being automated in 2H)
- Turn-off-RAM-LED.md: Systemd RGB-off service (being automated in 2H)
- more-info.md: SSH setup instructions (being automated in 2F)

The script automates everything from these notes that is CLI-capable.
Only AppImageLauncher and OpenRGB .debs still need manual download (Step 1).

================================================================================
END OF CONTEXT FILE
================================================================================
