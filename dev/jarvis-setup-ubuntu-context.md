# JARVIS SETUP-UBUNTU — IMPLEMENTATION CONTEXT

# Version: 3.0 (Final)

# Date: 2026-05-12

# Purpose: Fresh Ubuntu post-install automation. Run once after clean install.

# NO backups. NO over-cautious guards. Just automate the boring stuff.

# Give this + jarvis.sh to implement exactly as intended.

================================================================================
SECTION 1: COMMAND STRUCTURE (ABSOLUTE RULES)
================================================================================

Command pattern:
jarvis setup-ubuntu <step>

Valid inputs:
jarvis setup-ubuntu step 1
jarvis setup-ubuntu step 2
jarvis setup-ubuntu step 3
jarvis setup-ubuntu 1 ← alias for "step 1"
jarvis setup-ubuntu 2 ← alias for "step 2"
jarvis setup-ubuntu 3 ← alias for "step 3"
jarvis setup-ubuntu help
jarvis setup-ubuntu h ← alias for help

INVALID — do NOT implement:
jarvis setup-ubuntu --pre
jarvis setup-ubuntu --mid
jarvis setup-ubuntu --post
jarvis setup-ubuntu --help
jarvis setup-ubuntu -h
jarvis setup-ubuntu --anything

Router behavior: - Unknown step → show help, exit 0 - Missing step → show help, exit 0 - "help" or "h" → show help, exit 0

================================================================================
SECTION 2: EXISTING SCRIPT — WHAT TO USE, WHAT TO ADD
================================================================================

EXISTING HELPERS (use these, do not recreate):

    require_ubuntu()
        Reads /etc/os-release, checks ID=="ubuntu"
        Calls log_fail if wrong OS
        USE THIS for OS check.

    require_apt_package <cmd> [pkg]
        Checks if command exists. If not, log_fail with install hint.

    log_info(), log_ok(), log_warn(), log_fail(), log_label()
        Already defined. Use exactly as-is.

    show_divider(), divider_small()
        Already defined. Use exactly as-is.

NEW HELPERS TO ADD (place after require_file(), before banner section):

    check_internet()
        ping -c 1 -W 3 google.com > /dev/null 2>&1
        If fail: log_fail "No internet connection. Connect to WiFi first."
        If pass: log_ok "Internet connection active"

    ensure_dir <path>
        If dir does not exist: mkdir -p and log_ok
        If exists: silent (no output)

EXISTING COMMANDS (do NOT modify or break): - cmd_lights(), cmd_lock(), cmd_unlock(), cmd_tree(), cmd_observe_vault_log()

EXISTING HELPERS (do NOT modify): - lights*on_helper(), lights_off_helper(), lock_helper(), unlock_helper() - All require*\* functions

================================================================================
SECTION 3: HELP TEXT CONTENT
================================================================================

Function name: show_setup_ubuntu_help()

Display using cat << EOF heredoc.
Use ${script_name} variable for command name.

Content:

    ${script_name} setup-ubuntu - Fresh Ubuntu Setup Wizard

    Usage:
        ${script_name} setup-ubuntu step 1    Prepare: open browser tabs for manual downloads
        ${script_name} setup-ubuntu step 2    Build: run full automated setup
        ${script_name} setup-ubuntu step 3    Looks: configure themes and appearance
        ${script_name} setup-ubuntu help      Show this help

    What each step does:

      Step 1 (PREP) — You do this:
        • Opens Firefox with download pages for AppImageLauncher & OpenRGB
        • Shows a checklist of what .deb files to save to ~/Downloads
        • When done, run Step 2

      Step 2 (BUILD) — The computer does everything:
        • Updates & upgrades the system
        • Installs all CLI tools, snaps, VSCode, Chrome, Node.js
        • Sets up SSH server + allows SSH through firewall
        • Installs any .deb files found in ~/Downloads
        • Creates auto-lock and RGB-off systemd services
        • Logs EVERYTHING to ~/.local/logs/

      Step 3 (LOOKS) — Coming soon:
        • VSCode minimal theme
        • Terminal fonts and styling
        • Ubuntu themes, icons, cursors

    Safety:
        • Checks you're on Ubuntu and have internet before touching anything
        • Every action is logged with a timestamp
        • Shows [OK] or [WARN] for each step so you know what happened

    Example workflow:
        ${script_name} setup-ubuntu step 1
        # ...download 2 .deb files in Firefox...
        ${script_name} setup-ubuntu step 2
        # ...wait 5-10 minutes, everything installs...
        ${script_name} setup-ubuntu step 3
        # ...when it's ready...

================================================================================
SECTION 4: STEP 1 — PREP
================================================================================

Function name: cmd_setup_ubuntu_step_1()

Behavior: 1. Print header banner 2. Call require_ubuntu() 3. Call check_internet() 4. Open Firefox with 2 tabs:
firefox "URL1" "URL2" > /dev/null 2>&1 & disown
URLs:
https://github.com/TheAssassin/AppImageLauncher/releases
https://openrgb.org/releases.html 5. log_ok "Firefox opened with 2 tabs" 6. Print checklist 7. Print instruction to run step 2 8. Exit 0

Does NOT: - Download anything - Install anything - Modify system - Call show_banner() or refresh_banner()

================================================================================
SECTION 5: STEP 2 — BUILD
================================================================================

Function name: cmd_setup_ubuntu_step_2()

Behavior: 1. Print header banner 2. Call require_ubuntu() 3. Call check_internet() 4. Setup logging — CAPTURES EVERYTHING:
ensure_dir "$HOME/.local/logs"
           LOGFILE="$HOME/.local/logs/jarvis-setup-$(date +%Y%m%d-%H%M%S).log"
           exec > >(tee -a "$LOGFILE") 2>&1
This means ALL output goes to terminal AND file: - log_info/log_ok messages - apt output (package lists, progress, installs) - snap output (download progress, install messages) - wget output - curl output - systemctl output - EVERYTHING 5. Print log_info "Log file: $LOGFILE" 6. Run phases 2A through 2H 7. Print final summary 8. Exit 0

Does NOT: - Call show_banner() or refresh_banner() - Reboot - Ask for confirmation - Create ANY backups

---

PHASE 2A — System Foundation:

    log_info "Updating package lists..."
    sudo apt update -y
    log_ok "apt update complete"

    log_info "Upgrading packages..."
    sudo apt upgrade -y
    log_ok "apt upgrade complete"

    log_info "Creating user directories..."
    ensure_dir "$HOME/.themes"
    ensure_dir "$HOME/.icons"
    ensure_dir "$HOME/.fonts"
    ensure_dir "$HOME/.config/systemd/user"
    log_ok "User directories ready"

    log_info "Installing core CLI tools..."
    sudo apt-get install -y         git curl gnome-tweaks gnome-shell-extension-manager         wget apt-transport-https software-properties-common         ca-certificates gnupg lsb-release         openssh-server ufw tree
    log_ok "Core tools installed"

---

PHASE 2B — Snap Applications:

    Install ONE BY ONE. Each gets its own log_info + log_ok/log_warn.
    Do NOT loop silently. Do NOT fail entire script on one snap failure.
    Use || log_warn on each.

    sudo snap install brave || log_warn "Brave snap failed"
    sudo snap install chromium || log_warn "Chromium snap failed"
    sudo snap install opera || log_warn "Opera snap failed"
    sudo snap install firefox || log_warn "Firefox snap failed"
    sudo snap install obsidian --classic || log_warn "Obsidian snap failed"
    sudo snap install obs-studio || log_warn "OBS Studio snap failed"
    sudo snap install vlc || log_warn "VLC snap failed"
    sudo snap install qbittorrent-arnatious || log_warn "qBittorrent snap failed"

    Final: log_ok "Snap installations complete"

---

PHASE 2C — VSCode (Official Microsoft Apt Repo):

    log_info "Adding Microsoft GPG key..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc |         sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
    log_ok "Microsoft key added"

    log_info "Adding VSCode apt repository..."
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |         sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    log_ok "VSCode repo added"

    log_info "Installing VSCode..."
    sudo apt update -y
    sudo apt install -y code
    log_ok "VSCode installed: $(code --version | head -1)"

---

PHASE 2D — Google Chrome:

    log_info "Downloading Chrome..."
    wget -q "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"         -O "/tmp/google-chrome-stable_current_amd64.deb"
    log_ok "Chrome .deb downloaded"

    log_info "Installing Chrome (auto-adds update repo)..."
    sudo apt install -y "/tmp/google-chrome-stable_current_amd64.deb"
    rm -f "/tmp/google-chrome-stable_current_amd64.deb"
    log_ok "Chrome installed with auto-updates"

---

PHASE 2E — Node.js (NodeSource):

    log_info "Adding NodeSource repository..."
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    log_ok "NodeSource repo configured"

    log_info "Installing Node.js..."
    sudo apt install -y nodejs
    log_ok "Node.js $(node -v) + npm $(npm -v) installed"

---

PHASE 2F — SSH Server & Firewall:

    log_info "Enabling SSH..."
    sudo systemctl enable ssh
    sudo systemctl start ssh
    log_ok "SSH service: $(systemctl is-active ssh)"

    Get IP:
        ip_addr=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)

    log_info "Allowing SSH through firewall..."
    sudo ufw allow ssh
    log_ok "SSH allowed through firewall"

    NOTE: Do NOT run "sudo ufw enable" or "sudo ufw --force enable"
    NOTE: Do NOT run "sudo ufw default deny incoming"
    NOTE: Do NOT run "sudo ufw default allow outgoing"
    The firewall stays INACTIVE (default on fresh Ubuntu).
    We only add the SSH rule so it's ready if user enables UFW later.

    Print SSH access line:
        log_clr_l2 "  🔐 SSH ready: ssh $(whoami)@${ip_addr}"

---

PHASE 2G — Install .deb files from ~/Downloads:

    Find all *.deb in ~/Downloads (maxdepth 1).
    Use find with -print0 and while read loop.

    If none found:
        log_warn "No .deb files in ~/Downloads"
        log_warn "If you need AppImageLauncher/OpenRGB, run: ${script_name} setup-ubuntu step 1"

    If found:
        For each .deb:
            log_info "Installing: $(basename "$deb")"
            sudo apt install -y "$deb" || log_warn "Failed: $(basename "$deb")"
        log_ok "$count .deb file(s) installed"

---

PHASE 2H — Systemd User Services:

    Service 1: Auto-lock
        File: ~/.config/systemd/user/autolock-session.service
        NO backup before writing (fresh install, nothing to backup)
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
        log_ok "Created: autolock-session.service"

    Service 2: RGB-off
        File: ~/.config/systemd/user/openrgb-off.service
        NO backup before writing (fresh install, nothing to backup)
        Content:
            [Unit]
            Description=Turn off RAM RGB after login
            [Service]
            Type=oneshot
            ExecStart=/bin/bash -c 'sleep 5 && openrgb --mode static --color 000000 > /dev/null'
            [Install]
            WantedBy=default.target
        log_ok "Created: openrgb-off.service"

    Register:
        log_info "Registering with systemd..."
        systemctl --user daemon-reload
        systemctl --user enable autolock-session.service
        systemctl --user enable openrgb-off.service
        log_ok "Services registered (activate on next login)"

---

FINAL SUMMARY:

    show_divider()
    log_clr_l2 "  ✅ STEP 2 COMPLETE — Here's what happened:"
    List each completed item as log_ok()
    List any warnings as log_warn()
    Print log file path: log_txt_dm "  📁 Full log: $LOGFILE"
    Print next step suggestion:
        log_clr_l1 "  Next:"
        log_txt_dm "      ${script_name} setup-ubuntu step 3     (when it's ready)"

Summary items to list:
✔ System updated & upgraded
✔ Core tools: git, curl, gnome-tweaks, ssh, ufw, tree
✔ Browsers: Brave, Chromium, Opera, Firefox (snap)
✔ Apps: Obsidian, OBS Studio, VLC, qBittorrent (snap)
✔ VSCode: installed + official repo for updates
✔ Chrome: installed + auto-update repo
✔ Node.js: <version> + npm <version>
✔ SSH server: active on <user>@<ip>
✔ Firewall: SSH rule added (UFW stays inactive)
✔ Auto-lock: 3-second delay after login
✔ RGB-off: 5-second delay after login
✔ Custom .debs: <count> installed (or warning if 0)

================================================================================
SECTION 6: STEP 3 — LOOKS (PLACEHOLDER)
================================================================================

Function name: cmd_setup_ubuntu_step_3()

Behavior: 1. Print header banner 2. Print "This step is not built yet." 3. List what it WILL handle:
• VSCode minimal theme and settings
• Terminal fonts and styling
• Ubuntu themes, icons, cursors 4. Print "For now, your system is fully functional after Step 2." 5. Exit 0

Does NOT implement any actual functionality.

================================================================================
SECTION 7: COMMAND ROUTER
================================================================================

Add to case "$SUBCOMMAND" block, BEFORE the \*) catch-all:

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
SECTION 8: VISUAL OUTPUT SPECIFICATIONS
================================================================================

Step header format (use log_clr_l2 for borders):

    ╔══════════════════════════════════════════════════════════════╗
    ║           FRESH UBUNTU SETUP  —  STEP N: NAME                ║
    ╚══════════════════════════════════════════════════════════════╝

Phase header format inside Step 2 (use log_clr_l1):

    ┌─ [2A] Phase Name ─────────────────────────────────────────┐

Summary format:
show_divider()
log_clr_l2 " ✅ STEP 2 COMPLETE — Here's what happened:"
Then log_ok() for each item, log_warn() for any issues.

Do NOT: - Call show_banner() in any setup command - Call refresh_banner() in any setup command - Use colors not defined in the script

================================================================================
SECTION 9: WHAT NOT TO DO (ABSOLUTE RULES)
================================================================================

1. NO --flags. Only: step 1, step 2, step 3, help, h, 1, 2, 3.
2. NO dry-run mode.
3. NO confirmation prompts.
4. NO reboot command.
5. NO snap install loop. Install snaps one by one with individual logging.
6. NO modification of existing commands (lights, lock, unlock, tree, observe).
7. NO modification of existing helpers.
8. NO show_banner() or refresh_banner() in setup commands.
9. NO WARP client setup.
10. NO gnome-boxes installation.
11. NO root check at script level.
12. NO lsb_release for OS check. Use require_ubuntu().
13. NO backup_if_exists(). Fresh install = nothing to backup.
14. NO "sudo ufw enable". UFW stays INACTIVE.
15. NO "sudo ufw default deny incoming" or "sudo ufw default allow outgoing".

================================================================================
SECTION 10: FILE PLACEMENT IN jarvis.sh
================================================================================

Order of insertion:

    1. NEW HELPERS (after require_file(), before show_banner_1()):
        check_internet()
        ensure_dir()

    2. HELP TEXT FUNCTION (after show_light_help(), before cmd_lights()):
        show_setup_ubuntu_help()

    3. COMMAND FUNCTIONS (after cmd_observe_vault_log(), before Execution block):
        cmd_setup_ubuntu_step_1()
        cmd_setup_ubuntu_step_2()
        cmd_setup_ubuntu_step_3()

    4. ROUTER (in case "$SUBCOMMAND" block, before *) catch-all):
        setup-ubuntu) ... ;;

================================================================================
SECTION 11: LOGGING BEHAVIOR
================================================================================

The exec > >(tee -a "$LOGFILE") 2>&1 line captures:
✔ All echo output
✔ All log_info / log_ok / log_warn messages
✔ All apt output (package lists, unpacking, setting up)
✔ All snap output (download bars, install progress)
✔ All wget output (download progress)
✔ All curl output (NodeSource script output)
✔ All systemctl output
✔ All errors (stderr)
✔ Everything that prints to terminal

The log file is plain text. User can cat it later to see full output.
Log file naming: jarvis-setup-YYYYMMDD-HHMMSS.log
Log directory: ~/.local/logs/

================================================================================
END OF CONTEXT
================================================================================
