#!/usr/bin/env bash
# =============================================================================
#  installer.sh — install / update / uninstall jarvis + Zsh auto-completions
#  Pure bash · No external dependencies (beyond sudo, python3)
#  Supports local-development mode and online one-line installation.
# =============================================================================

set -euo pipefail

# ── Identity ──────────────────────────────────────────────────────────────────
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="2.0.0"

# ── GitHub asset configuration (single source of truth for all URLs) ──────────
GITHUB_RAW_BASE="https://raw.githubusercontent.com/MdSakifHossain/jarvis-command/main"
GITHUB_ASSET_COMMAND="${GITHUB_RAW_BASE}/command/jarvis"
GITHUB_ASSET_SCHEMA="${GITHUB_RAW_BASE}/jarvis-schema.json"
GITHUB_ASSET_GENERATOR="${GITHUB_RAW_BASE}/generate-completions.py"

# ── Asset paths (resolved by prepare_assets; used everywhere else) ────────────
COMMAND_DIR=""        # set by prepare_assets
SCHEMA_FILE=""        # set by prepare_assets
GENERATOR=""          # set by prepare_assets

# ── Fixed paths ───────────────────────────────────────────────────────────────
INSTALL_DIR="/usr/local/bin"
OMZ_COMPLETION_DIR="${HOME}/.oh-my-zsh/completions"

# ── Temporary directory (used only in download mode) ─────────────────────────
_TMP_DIR=""           # set by prepare_assets when in download mode

# ── Colors ────────────────────────────────────────────────────────────────────
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

# ── Color helpers ─────────────────────────────────────────────────────────────
log_clr_l1() { echo -e "${ORANGE}${1}${RESET}"; }
log_clr_l2() { echo -e "${BORANGE}${1}${RESET}"; }
log_clr_l3() { echo -e "${DIM_ORANGE}${1}${RESET}"; }

# ── Text helpers ──────────────────────────────────────────────────────────────
log_txt_nm() { echo -e "${1}"; }
log_txt_bd() { echo -e "${BOLD}${1}${RESET}"; }
log_txt_dm() { echo -e "${DIM}${1}${RESET}"; }

# ── Semantic logging ──────────────────────────────────────────────────────────
log_info() { echo -e "  ${ORANGE}ℹ${RESET}  $*"; }
log_ok()   { echo -e "  ${BGREEN}✔${RESET}  $*"; }
log_warn() { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
log_fail() {
  echo -e "\n  ${RED}✖  ERROR:${RESET}  $*\n" >&2
  exit 1
}
log_label() { echo -e "  ${BORANGE}▸${RESET}  ${BWHITE}$*${RESET}"; }

# ── UI helpers ────────────────────────────────────────────────────────────────
divider()  { log_clr_l3 "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }
thin_div() { log_txt_dm "  ──────────────────────────────────────────────────────────────────"; }

step() { echo -e "  ${BORANGE}[${1}]${RESET}  ${BWHITE}${2}${RESET}"; }

prompt_yn() {
  # $1 = question   returns 0 for yes, 1 for no
  echo -ne "  ${BORANGE}?${RESET}  ${BWHITE}${1}${RESET} ${DIM}[y/N]${RESET} ${ORANGE}›${RESET} "
  read -r _ans
  [[ "${_ans,,}" == "y" || "${_ans,,}" == "yes" ]]
}

# ── Banner ────────────────────────────────────────────────────────────────────
show_banner() {
  clear
  echo
  log_clr_l2 "  ██╗███╗  ██╗███████╗████████╗ █████╗ ██╗     ██╗     "
  log_clr_l2 "  ██║████╗ ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     "
  log_clr_l2 "  ██║██╔██╗██║███████╗   ██║   ███████║██║     ██║     "
  log_clr_l1 "  ██║██║╚████║╚════██║   ██║   ██╔══██║██║     ██║     "
  log_clr_l1 "  ██║██║ ╚███║███████║   ██║   ██║  ██║███████╗███████╗"
  log_clr_l3 "  ╚═╝╚═╝  ╚══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝"
  echo
  log_txt_dm "  v${VERSION} · Pure Bash · No dependencies"
  echo
  divider
  echo
}

# ── Help ──────────────────────────────────────────────────────────────────────
show_help() {
  echo
  echo -e "  ${BORANGE}${SCRIPT_NAME}${RESET} ${DIM}v${VERSION}${RESET}"
  echo
  echo -e "  ${BWHITE}Install, update, or uninstall jarvis and its Zsh auto-completions.${RESET}"
  echo
  echo -e "  ${BORANGE}Usage${RESET}"
  thin_div
  echo -e "    ${BWHITE}./${SCRIPT_NAME} ${DIM}<subcommand> [flags]${RESET}"
  echo
  echo -e "  ${BORANGE}Subcommands${RESET}"
  thin_div
  echo -e "    ${BWHITE}install, i${RESET}              Install jarvis and completions."
  echo -e "    ${BWHITE}update,  u${RESET}              Re-install everything (alias for install)."
  echo -e "    ${BWHITE}uninstall, remove, rm${RESET}   Remove jarvis and completions."
  echo
  echo -e "  ${BORANGE}Flags${RESET}"
  thin_div
  echo -e "    ${BWHITE}-y, y${RESET}           Skip prompts, use defaults."
  echo -e "    ${BWHITE}-h, --help${RESET}      Show this help message."
  echo -e "    ${BWHITE}-v, --version${RESET}   Show version number."
  echo
  echo -e "  ${BORANGE}Examples${RESET}"
  thin_div
  echo -e "    ${DIM}\$${RESET} ./${SCRIPT_NAME} install"
  echo -e "    ${DIM}\$${RESET} ./${SCRIPT_NAME} install -y"
  echo -e "    ${DIM}\$${RESET} ./${SCRIPT_NAME} update"
  echo -e "    ${DIM}\$${RESET} ./${SCRIPT_NAME} uninstall"
  echo -e "    ${DIM}\$${RESET} curl -fsSL <url> | bash -s -- install"
  echo
  divider
  echo
}

# ── Asset cleanup (called via trap on exit in download mode) ──────────────────
cleanup() {
  if [[ -n "$_TMP_DIR" && -d "$_TMP_DIR" ]]; then
    rm -rf "$_TMP_DIR"
    # log_info may not be available if we exit very early; use plain echo
    echo -e "  ${DIM}Temporary files removed  →  ${_TMP_DIR}${RESET}" >&2
  fi
}

# ── Detect download tool (curl or wget) ───────────────────────────────────────
_detect_downloader() {
  if command -v curl > /dev/null 2>&1; then
    echo "curl"
  elif command -v wget > /dev/null 2>&1; then
    echo "wget"
  else
    log_fail "Neither curl nor wget found. Install one and re-run."
  fi
}

# ── Download a single file ────────────────────────────────────────────────────
_download_file() {
  local url="$1"
  local dest="$2"
  local downloader
  downloader="$(_detect_downloader)"

  if [[ "$downloader" == "curl" ]]; then
    curl -fsSL "$url" -o "$dest"
  else
    wget -qO "$dest" "$url"
  fi
}

# ── Asset preparation layer ───────────────────────────────────────────────────
# Detects local vs download mode based solely on the presence of required files.
# Sets the global variables COMMAND_DIR, SCHEMA_FILE, GENERATOR.
# In download mode, also sets _TMP_DIR and registers a trap for cleanup.
prepare_assets() {
  local local_command_dir="${SCRIPT_DIR}/command"
  local local_schema="${SCRIPT_DIR}/jarvis-schema.json"
  local local_generator="${SCRIPT_DIR}/generate-completions.py"

  if [[ -d "$local_command_dir" && -f "$local_schema" && -f "$local_generator" ]]; then
    # ── Local mode ──────────────────────────────────────────────────────────
    log_info "Local assets detected  →  using local files (no download needed)"
    COMMAND_DIR="$local_command_dir"
    SCHEMA_FILE="$local_schema"
    GENERATOR="$local_generator"
  else
    # ── Download mode ────────────────────────────────────────────────────────
    log_info "Local assets not found  →  switching to download mode"
    echo

    _TMP_DIR="$(mktemp -d /tmp/jarvis-installer.XXXXXX)"
    trap cleanup EXIT

    log_info "Temporary directory  →  ${_TMP_DIR}"
    echo

    local tmp_command_dir="${_TMP_DIR}/command"
    mkdir -p "$tmp_command_dir"

    log_info "Downloading jarvis command…"
    _download_file "$GITHUB_ASSET_COMMAND" "${tmp_command_dir}/jarvis"
    chmod +x "${tmp_command_dir}/jarvis"
    log_ok "Downloaded  →  ${tmp_command_dir}/jarvis"

    log_info "Downloading jarvis-schema.json…"
    _download_file "$GITHUB_ASSET_SCHEMA" "${_TMP_DIR}/jarvis-schema.json"
    log_ok "Downloaded  →  ${_TMP_DIR}/jarvis-schema.json"

    log_info "Downloading generate-completions.py…"
    _download_file "$GITHUB_ASSET_GENERATOR" "${_TMP_DIR}/generate-completions.py"
    log_ok "Downloaded  →  ${_TMP_DIR}/generate-completions.py"

    COMMAND_DIR="$tmp_command_dir"
    SCHEMA_FILE="${_TMP_DIR}/jarvis-schema.json"
    GENERATOR="${_TMP_DIR}/generate-completions.py"
  fi

  # Derive the completion output path from wherever GENERATOR lives
  COMPLETION_FILE="$(dirname "$GENERATOR")/_jarvis"
}

# ── Resolve jarvis file from COMMAND_DIR ──────────────────────────────────────
resolve_jarvis() {
  if [[ ! -d "$COMMAND_DIR" ]]; then
    log_fail "Directory not found: ${COMMAND_DIR}
Expected the jarvis script inside: ${COMMAND_DIR}/"
  fi
  local file
  file=$(find "$COMMAND_DIR" -maxdepth 1 -type f | sort | head -n 1)
  if [[ -z "$file" ]]; then
    log_fail "No file found inside ${COMMAND_DIR}/"
  fi
  echo "$file"
}

# ── Backup helper ─────────────────────────────────────────────────────────────
backup_file() {
  local target="$1"
  if [[ -f "$target" ]]; then
    local backup="${target}.bak.$(date +%Y%m%d_%H%M%S)"
    if [[ -w "$(dirname "$target")" ]]; then
      cp "$target" "$backup"
    else
      sudo cp "$target" "$backup"
    fi
    log_info "Backed up  →  ${DIM}${backup}${RESET}"
  fi
}

# ── Check / install Python 3 ──────────────────────────────────────────────────
ensure_python() {
  if command -v python3 > /dev/null 2>&1; then
    log_ok "Python 3 found  →  $(python3 --version 2>&1)"
    return 0
  fi

  log_warn "python3 not found."
  echo
  if prompt_yn "Install python3 via apt?"; then
    echo
    log_info "Running: sudo apt update && sudo apt install -y python3"
    sudo apt update -qq
    sudo apt install -y python3
    log_ok "Python 3 installed."
  else
    log_fail "python3 is required to generate completions. Install it and re-run."
  fi
}

# ── Check / install Oh My Zsh ─────────────────────────────────────────────────
ensure_omz() {
  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    log_ok "Oh My Zsh found  →  ${HOME}/.oh-my-zsh"
    return 0
  fi

  log_warn "Oh My Zsh is not installed."
  echo
  if ! prompt_yn "Install Oh My Zsh now? (recommended for completions)"; then
    log_fail "Oh My Zsh is required for completions to auto-load. Install it and re-run."
  fi

  echo
  log_info "Detecting download tool…"

  local install_cmd=""
  if command -v wget > /dev/null 2>&1; then
    log_ok "Using wget"
    install_cmd='wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh'
  elif command -v curl > /dev/null 2>&1; then
    log_ok "Using curl"
    install_cmd='curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh'
  else
    log_warn "Neither wget nor curl found. Attempting to install curl via apt…"
    sudo apt update -qq
    sudo apt install -y curl
    if command -v curl > /dev/null 2>&1; then
      log_ok "curl installed."
      install_cmd='curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh'
    else
      log_fail "Could not install curl. Please install curl or wget manually and re-run."
    fi
  fi

  echo
  log_info "Installing Oh My Zsh (RUNZSH=no CHSH=no — won't touch your .zshrc or change shell)…"
  echo
  RUNZSH=no CHSH=no sh -c "$($install_cmd)"
  echo
  log_ok "Oh My Zsh installed."
}

# ── Generate completion file ──────────────────────────────────────────────────
generate_completion() {
  if [[ ! -f "$SCHEMA_FILE" ]]; then
    log_fail "Schema file not found: ${SCHEMA_FILE}"
  fi
  if [[ ! -f "$GENERATOR" ]]; then
    log_fail "Generator not found: ${GENERATOR}"
  fi

  log_info "Generating completion file from schema…"
  # Run the generator from its own directory so relative paths inside it work
  (cd "$(dirname "$GENERATOR")" && python3 "$(basename "$GENERATOR")")
  log_ok "Completion file generated  →  ${COMPLETION_FILE}"
}

# ── Install completion file ───────────────────────────────────────────────────
install_completion() {
  local dest="${OMZ_COMPLETION_DIR}/_jarvis"

  if [[ ! -d "$OMZ_COMPLETION_DIR" ]]; then
    log_info "Creating completions directory: ${OMZ_COMPLETION_DIR}"
    mkdir -p "$OMZ_COMPLETION_DIR"
  fi

  backup_file "$dest"
  cp "$COMPLETION_FILE" "$dest"
  log_ok "Completion installed  →  ${dest}"
}

# ── Remove completion file ────────────────────────────────────────────────────
remove_completion() {
  local dest="${OMZ_COMPLETION_DIR}/_jarvis"
  if [[ -f "$dest" ]]; then
    rm -f "$dest"
    log_ok "Completion removed  →  ${dest}"
  else
    log_warn "Completion file not found, skipping: ${dest}"
  fi
}

# ── Subcommand: install / update ──────────────────────────────────────────────
cmd_install() {
  local auto=false
  for arg in "$@"; do
    case "$arg" in
      -y | y) auto=true ;;
      -*) log_fail "Unknown flag: ${arg}. Use --help for usage." ;;
    esac
  done

  show_banner

  # ── Step 0: Prepare assets (local or download) ────────────────────────────
  step "0" "Preparing assets"
  thin_div
  prepare_assets
  echo

  # ── Step 1: Resolve jarvis ────────────────────────────────────────────────
  step "1" "Resolving jarvis script"
  thin_div
  local file
  file=$(resolve_jarvis)
  local command_name
  command_name=$(basename "$file")
  local target_path="${INSTALL_DIR}/${command_name}"
  log_ok "Found  →  ${BOLD}${file}${RESET}"
  echo

  # ── Step 2: Python 3 ─────────────────────────────────────────────────────
  step "2" "Checking Python 3"
  thin_div
  ensure_python
  echo

  # ── Step 3: Oh My Zsh ────────────────────────────────────────────────────
  step "3" "Checking Oh My Zsh"
  thin_div
  ensure_omz
  echo

  # ── Step 4: Install jarvis ────────────────────────────────────────────────
  step "4" "Installing jarvis"
  thin_div
  if [[ -f "$target_path" ]]; then
    log_info "Updating existing install…"
    backup_file "$target_path"
  else
    log_info "Fresh install…"
  fi

  chmod +x "$file"
  local tmp_path="/tmp/${command_name}_$$"
  cp "$file" "$tmp_path"
  sudo mv "$tmp_path" "$target_path"
  sudo chmod +x "$target_path"
  log_ok "Installed  →  ${target_path}"
  echo

  # ── Step 5: Generate completion ───────────────────────────────────────────
  step "5" "Generating completion file"
  thin_div
  generate_completion
  echo

  # ── Step 6: Install completion ────────────────────────────────────────────
  step "6" "Installing completion"
  thin_div
  install_completion
  echo

  # ── Done ──────────────────────────────────────────────────────────────────
  divider
  echo
  echo -e "${BORANGE}  ╔══════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BORANGE}  ║${RESET}${BOLD}                    ✅  Done!                                   ${BORANGE}║${RESET}"
  echo -e "${BORANGE}  ╚══════════════════════════════════════════════════════════════════╝${RESET}"
  echo
  log_label "Command   :  ${command_name}"
  log_label "Installed :  ${target_path}"
  log_label "Completions: ${OMZ_COMPLETION_DIR}/_jarvis"
  echo
  divider
  echo
  echo -e "  ${BWHITE}To activate completions, reload your shell:${RESET}"
  echo
  echo -e "  ${BORANGE}Option 1${RESET}  ${DIM}(recommended)${RESET}"
  echo -e "    ${BGREEN}\$${RESET}  exec zsh"
  echo
  echo -e "  ${BORANGE}Option 2${RESET}"
  echo -e "    Close the terminal and open a new one."
  echo
  divider
  echo
}

# ── Subcommand: uninstall ─────────────────────────────────────────────────────
cmd_uninstall() {
  local auto=false
  for arg in "$@"; do
    case "$arg" in
      -y | y) auto=true ;;
      -*) log_fail "Unknown flag: ${arg}. Use --help for usage." ;;
    esac
  done

  show_banner

  # ── Step 0: Prepare assets (needed to resolve command name) ───────────────
  step "0" "Preparing assets"
  thin_div
  prepare_assets
  echo

  # Resolve command name
  local file
  file=$(resolve_jarvis)
  local command_name
  command_name=$(basename "$file")
  local target_path="${INSTALL_DIR}/${command_name}"

  log_info "Removing ${BOLD}${command_name}${RESET} and its completions…"
  echo

  # ── Remove jarvis ─────────────────────────────────────────────────────────
  step "1" "Removing jarvis from ${INSTALL_DIR}"
  thin_div
  if [[ -f "$target_path" ]]; then
    sudo rm -f "$target_path"
    log_ok "Removed  →  ${target_path}"
  else
    log_warn "'${command_name}' not found in ${INSTALL_DIR} — skipping."
  fi
  echo

  # ── Remove completion ─────────────────────────────────────────────────────
  step "2" "Removing completion file"
  thin_div
  remove_completion
  echo

  # ── Done ──────────────────────────────────────────────────────────────────
  divider
  echo
  echo -e "${BORANGE}  ╔══════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BORANGE}  ║${RESET}${BOLD}                    ✅  Done!                                   ${BORANGE}║${RESET}"
  echo -e "${BORANGE}  ╚══════════════════════════════════════════════════════════════════╝${RESET}"
  echo
  log_label "Command   :  ${command_name}"
  log_label "Removed   :  ${target_path}"
  log_label "Completion:  ${OMZ_COMPLETION_DIR}/_jarvis"
  echo
  divider
  echo
  echo -e "  ${BWHITE}Reload your shell to clear the cached completions:${RESET}"
  echo
  echo -e "  ${BORANGE}Option 1${RESET}  ${DIM}(recommended)${RESET}"
  echo -e "    ${BGREEN}\$${RESET}  exec zsh"
  echo
  echo -e "  ${BORANGE}Option 2${RESET}"
  echo -e "    Close the terminal and open a new one."
  echo
  divider
  echo
}

# ── Entry point ───────────────────────────────────────────────────────────────
case "${1:-}" in
  -h | --help)    show_help;  exit 0 ;;
  -v | --version) echo "${SCRIPT_NAME} v${VERSION}"; exit 0 ;;
esac

SUBCOMMAND="${1:-}"
shift || true

case "$SUBCOMMAND" in
  install | i)             cmd_install   "$@" ;;
  update  | u)             cmd_install   "$@" ;;   # update is an alias for install
  uninstall | remove | rm) cmd_uninstall "$@" ;;
  "")                      show_help; exit 0 ;;
  *) log_fail "Unknown subcommand: '${SUBCOMMAND}'. Use --help for usage." ;;
esac
