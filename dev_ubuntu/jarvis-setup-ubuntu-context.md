# JARVIS.SH UPGRADE CONTEXT v4.0

# Date: 2026-05-14

# Purpose: Context file for upgrading jarvis.sh from v1.11.1 to next version

# Usage: Provide this file + current jarvis.sh to implement all changes

================================================================================
SECTION 1: VERSION BUMP RULES
================================================================================

- Current version: 1.11.1
- After implementing all changes below, bump version to: 1.12.0
- Git commit message: "feat: add step 3 automation, zsh setup, warp client, vscode config, cleanup"

================================================================================
SECTION 2: EXISTING SCRIPT — WHAT TO PRESERVE
================================================================================

DO NOT MODIFY:

- All color definitions and log helpers (log_info, log_ok, log_warn, log_fail, log_label)
- show_divider(), divider_small()
- require_ubuntu(), require_apt_package(), require_external_dependency()
- require_openrgb(), require_dbus(), require_gnome_screensaver(), require_gnome_lock()
- require_file()
- check_internet() (already implemented in current jarvis.sh)
- ensure_dir() (already implemented in current jarvis.sh)
- show_banner_1(), show_banner_2(), show_banner(), refresh_banner()
- show_help(), show_light_help(), show_setup_ubuntu_help()
- cmd_lights(), cmd_lock(), cmd_unlock(), cmd_tree(), cmd_observe_vault_log()
- lights_on_helper(), lights_off_helper(), lock_helper(), unlock_helper()
- All existing subcommand routers (v/version, h/help, light/lights, lock, unlock, observe/monitor, poweroff/power/pwr/shutdown, tree/list/lst/ls)

================================================================================
SECTION 3: COMMAND STRUCTURE (UNCHANGED)
================================================================================

Valid inputs:
jarvis setup-ubuntu step 1
jarvis setup-ubuntu step 2
jarvis setup-ubuntu step 3
jarvis setup-ubuntu 1
jarvis setup-ubuntu 2
jarvis setup-ubuntu 3
jarvis setup-ubuntu help
jarvis setup-ubuntu h

INVALID — do NOT implement:
jarvis setup-ubuntu --pre, --mid, --post, --help, -h, --anything

Router behavior:

- Unknown step → show help, exit 0
- Missing step → show help, exit 0
- "help" or "h" → show help, exit 0

================================================================================
SECTION 4: STEP 2 MODIFICATIONS
================================================================================

### 4A: Add gnome-boxes installation

In Phase 2A — System Foundation, AFTER installing core CLI tools, ADD:

    log_info "Installing GNOME Boxes..."
    sudo apt install -y gnome-boxes
    log_ok "GNOME Boxes installed"

### 4B: Add .deb cleanup at end of Phase 2G

After installing all .deb files from ~/Downloads, ADD:

    log_info "Cleaning up .deb files from ~/Downloads..."
    rm -f "$HOME/Downloads"/*.deb
    log_ok "Downloads cleaned"

Update final summary to include:
log_ok "GNOME Boxes: installed"
log_ok "Custom .debs: ${\_deb_count} installed + cleaned from Downloads"

================================================================================
SECTION 5: STEP 3 — FULL IMPLEMENTATION
================================================================================

Step 3 is NO LONGER a placeholder. It performs real automation.

### 5A: Step 3 Header

    log_clr_l2 "  ╔══════════════════════════════════════════════════════════════╗"
    log_clr_l2 "  ║         FRESH UBUNTU SETUP  —  STEP 3: LOOKS & CONFIG       ║"
    log_clr_l2 "  ╚══════════════════════════════════════════════════════════════╝"
    echo

    require_ubuntu
    check_internet

    ensure_dir "$HOME/.local/logs"
    LOGFILE="$HOME/.local/logs/jarvis-setup-$(date +%Y%m%d-%H%M%S).log"
    exec > >(tee -a "$LOGFILE") 2>&1

    log_info "Log file: $LOGFILE"
    echo

### 5B: Phase 3A — WARP Client

    log_clr_l1 "  ┌─ [3A] WARP Client (Cloudflare) ────────────────────────────┐"
    echo

    log_info "Adding Cloudflare GPG key..."
    curl -fsSL https://pkg.cloudflareclient.com/cloudflare-release.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloudflare-client.gpg
    log_ok "Cloudflare key added"

    log_info "Adding Cloudflare apt repository..."
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-client.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list > /dev/null
    log_ok "Cloudflare repo added"

    log_info "Installing WARP client..."
    sudo apt update -y
    sudo apt install -y cloudflare-warp
    log_ok "WARP client installed"

    log_warn "WARP requires manual registration: run 'warp-cli register' and login via browser"
    echo

### 5C: Phase 3B — VSCode Minimal Config

    log_clr_l1 "  ┌─ [3B] VSCode Minimal Theme & Settings ─────────────────────┐"
    echo

    log_info "Installing VSCode extensions..."
    code --install-extension Catppuccin.catppuccin-vscode --force
    code --install-extension PKief.material-icon-theme --force
    code --install-extension Equinusocio.vsc-material-theme --force
    log_ok "VSCode extensions installed"

    log_info "Writing VSCode settings..."
    ensure_dir "$HOME/.config/Code/User"
    cat > "$HOME/.config/Code/User/settings.json" << 'VSCODEOF'

{
"workbench.productIconTheme": "material-product-icons",
"workbench.iconTheme": "material-icon-theme",
"workbench.statusBar.visible": false,
"workbench.startupEditor": "none",
"editor.minimap.enabled": false,
"breadcrumbs.enabled": false,
"window.zoomLevel": 3,
"window.customMenuBarAltFocus": false,
"window.enableMenuBarMnemonics": false,
"editor.fontFamily": "'GeistMono NFP', 'Droid Sans Mono', monospace",
"workbench.colorTheme": "Catppuccin Macchiato",
"editor.padding.top": 16,
"editor.padding.bottom": 16,
"terminal.integrated.smoothScrolling": true,
"editor.cursorSmoothCaretAnimation": "on",
"workbench.list.smoothScrolling": true,
"editor.smoothScrolling": true,
"editor.formatOnSave": true,
"editor.cursorStyle": "block",
"editor.cursorBlinking": "phase",
"workbench.navigationControl.enabled": false,
"workbench.openInAgents.enabled": false,
"workbench.browser.showInTitleBar": false,
"window.menuBarVisibility": "toggle",
"workbench.layoutControl.enabled": false,
"window.commandCenter": false,
"workbench.editor.enablePreview": false,
"workbench.sideBar.location": "right",
"workbench.activityBar.location": "hidden"
}
VSCODEOF
log_ok "VSCode settings written"
echo

### 5D: Phase 3C — Zsh & Terminal Setup

    log_clr_l1 "  ┌─ [3C] Zsh, Oh-My-Zsh & Powerlevel10k ──────────────────────┐"
    echo

    log_info "Installing zsh..."
    sudo apt install -y zsh
    log_ok "zsh installed"

    log_info "Installing Oh-My-Zsh (unattended)..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_ok "Oh-My-Zsh installed"

    log_info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    log_ok "zsh-autosuggestions installed"

    log_info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    log_ok "zsh-syntax-highlighting installed"

    log_info "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    log_ok "Powerlevel10k installed"

    log_info "Configuring .zshrc..."
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
    log_ok ".zshrc configured"

    log_warn "Shell changed to zsh. LOG OUT and LOG BACK IN for changes to take effect."
    echo

### 5E: Phase 3D — Browser Restoration Links

    log_clr_l1 "  ┌─ [3D] Opening Essential Accounts in Brave ─────────────────┐"
    echo

    log_info "Opening Brave with restoration links..."
    brave --new-window         "https://pass.proton.me"         "https://accounts.google.com"         "https://web.whatsapp.com"         "https://www.instagram.com"         "https://www.facebook.com"         "https://web.telegram.org/a"         "https://github.com/login"         "https://x.com"         "https://web.programming-hero.com/dashboard"         &>/dev/null & disown
    log_ok "Brave opened with 9 tabs"
    echo

### 5F: Phase 3E — Manual Instructions (Printed, Not Executed)

    log_clr_l1 "  ┌─ [3E] Manual Steps (Human Required) ───────────────────────┐"
    echo

    log_txt_nm "  ${BORANGE}GNOME Shell Extensions:${RESET}"
    log_txt_nm "    1. Open 'Extension Manager' (installed in Step 2)"
    log_txt_nm "    2. Install: User Themes, Hide Top Bar, Blur my Shell"
    log_txt_nm "    3. Install: Burn My Windows, Compiz alike magic lamp"
    log_txt_nm "    4. Install: Compiz windows effect"
    echo

    log_txt_nm "  ${BORANGE}Themes & Icons:${RESET}"
    log_txt_nm "    1. Download Graphite GTK/Shell theme from GitHub"
    log_txt_nm "    2. Download McMojave-circle icon theme"
    log_txt_nm "    3. Download ArcAurora cursors"
    log_txt_nm "    4. Extract to ~/.themes, ~/.icons, ~/.icons respectively"
    log_txt_nm "    5. Apply via GNOME Tweaks or gsettings"
    echo

    log_txt_nm "  ${BORANGE}Fonts:${RESET}"
    log_txt_nm "    1. Download Nerd Fonts (Inter, Poppins, DM Mono, Space Mono)"
    log_txt_nm "    2. Copy .ttf files to ~/.fonts"
    log_txt_nm "    3. Run: fc-cache -fv"
    log_txt_nm "    4. Set font in GNOME Settings > Appearance"
    echo

    log_txt_nm "  ${BORANGE}Terminal Gogh Theme:${RESET}"
    log_txt_nm "    1. Run: bash -c "$(wget -qO- https://git.io/vQgMr)""
    log_txt_nm "    2. Pick theme number interactively"
    echo

    log_txt_nm "  ${BORANGE}WARP Registration:${RESET}"
    log_txt_nm "    1. Run: warp-cli register"
    log_txt_nm "    2. Login via browser when prompted"
    log_txt_nm "    3. Run: warp-cli connect"
    echo

### 5G: Step 3 Final Summary

    show_divider
    log_clr_l2 "  ✅ STEP 3 COMPLETE — Here's what happened:"
    echo
    log_ok "WARP client: installed (registration required)"
    log_ok "VSCode: minimal theme + extensions + settings applied"
    log_ok "Zsh: installed with Oh-My-Zsh, autosuggestions, syntax-highlighting"
    log_ok "Powerlevel10k: theme installed and configured"
    log_ok ".zshrc: configured with plugins"
    log_ok "Brave: opened with 9 restoration links"
    log_warn "Manual steps listed above require human interaction"
    log_warn "Log out and back in for zsh to become default shell"
    echo
    log_txt_dm "  📁 Full log: $LOGFILE"
    echo
    log_clr_l1 "  Setup complete. Your system is ready."
    echo

    exit 0

================================================================================
SECTION 6: HELP TEXT UPDATE
================================================================================

Update show_setup_ubuntu_help() to reflect Step 3 is no longer "Coming soon":

Step 3 (LOOKS & CONFIG) — The computer does most, you do some:
• Installs WARP client (you register manually)
• Installs VSCode extensions + applies minimal settings
• Sets up zsh, Oh-My-Zsh, Powerlevel10k, plugins
• Opens Brave with all essential account links
• Lists manual steps: GNOME extensions, themes, icons, fonts, Gogh

================================================================================
SECTION 7: FILE PLACEMENT IN jarvis.sh
================================================================================

Order of insertion/modification:

1. MODIFY Phase 2A: Add gnome-boxes installation after core CLI tools
2. MODIFY Phase 2G: Add .deb cleanup after installation loop
3. MODIFY Final Summary (Step 2): Add GNOME Boxes line, update .deb line
4. REPLACE cmd_setup_ubuntu_step_3(): Implement full Step 3 (Sections 5A-5G)
5. UPDATE show_setup_ubuntu_help(): Update Step 3 description
6. BUMP version variable: "1.11.1" → "1.12.0"

================================================================================
SECTION 8: SAFETY & EDGE CASES
================================================================================

1. VSCode extensions: Use --force flag to avoid interactive prompts
2. Oh-My-Zsh: Use --unattended flag to avoid interactive prompts
3. Brave: If 'brave' command not found (snap PATH issue), fallback to:
   snap run brave --new-window <urls> &>/dev/null & disown
4. zsh chsh: Do NOT run chsh in script — it requires password input and
   the user must log out anyway. Just install zsh and configure .zshrc.
   The user runs 'chsh -s $(which zsh)' manually after Step 3.
5. WARP: warp-cli register requires browser auth — cannot be automated.
   Print clear instructions.
6. All Phase 3 operations use || log_warn pattern where appropriate
   (e.g., if VSCode extensions fail, warn but continue)

================================================================================
SECTION 9: WHAT NOT TO DO (ABSOLUTE RULES)
================================================================================

1. NO --flags for setup-ubuntu. Only: step 1, step 2, step 3, help, h, 1, 2, 3.
2. NO dry-run mode.
3. NO confirmation prompts.
4. NO reboot command.
5. NO modification of existing commands (lights, lock, unlock, tree, observe).
6. NO modification of existing helpers.
7. NO show_banner() or refresh_banner() in setup commands.
8. NO "sudo ufw enable". UFW stays INACTIVE.
9. NO theme/icon/cursor downloads or gsettings application — HUMAN ONLY.
10. NO Gogh automation — HUMAN ONLY (interactive menu).
11. NO Nerd Fonts automation beyond instructions — HUMAN ONLY.
12. NO gnome-extensions CLI automation — HUMAN ONLY (no stable URLs).
13. NO chsh in script — HUMAN ONLY (requires password + logout).

================================================================================
SECTION 10: GIT COMMIT MESSAGE
================================================================================

feat: add step 3 automation, zsh setup, warp client, vscode config, cleanup

- Implement full Step 3: WARP install, VSCode minimal theme, zsh/oh-my-zsh,
  Powerlevel10k, Brave restoration links
- Add gnome-boxes to Step 2 system foundation
- Add .deb cleanup in Step 2 after installation
- Update help text to reflect Step 3 capabilities
- List manual steps (extensions, themes, fonts, Gogh) for human completion
- Bump version to 1.12.0

================================================================================
END OF CONTEXT
================================================================================
