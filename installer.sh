#!/usr/bin/env bash
# =============================================================================
#  installer.sh — install or uninstall a script to/from /usr/local/bin
#  Pure bash · No dependencies
# =============================================================================

set -euo pipefail

# ── Identity ──────────────────────────────────────────────────────────────────
SCRIPT_NAME="$(basename "$0")"
VERSION="1.0.1"

# ── Config ────────────────────────────────────────────────────────────────────
DEFAULT_DIR="command"
INSTALL_DIR="/usr/local/bin"

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
log_ok() { echo -e "  ${BGREEN}✔${RESET}  $*"; }
log_warn() { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
log_fail() {
  echo -e "\n  ${RED}✖  ERROR:${RESET}  $*\n" >&2
  exit 1
}
log_label() { echo -e "  ${BORANGE}▸${RESET}  ${BWHITE}$*${RESET}"; }

# ── UI helpers ────────────────────────────────────────────────────────────────
divider() { log_clr_l3 "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }
thin_div() { log_txt_dm "  ──────────────────────────────────────────────────────────────────"; }

prompt_line() {
  echo -ne "  ${BORANGE}?${RESET}  ${BWHITE}${1}${RESET} ${DIM}(default: ${2})${RESET} ${ORANGE}›${RESET} "
}

step() {
  echo -e "  ${BORANGE}[${1}]${RESET}  ${BWHITE}${2}${RESET}"
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
  echo -e "  ${BWHITE}Install or uninstall a script to/from ${INSTALL_DIR}.${RESET}"
  echo
  echo -e "  ${BORANGE}Usage${RESET}"
  thin_div
  echo -e "    ${BWHITE}./${SCRIPT_NAME} ${DIM}<subcommand> [source] [flags]${RESET}"
  echo
  echo -e "  ${BORANGE}Subcommands${RESET}"
  thin_div
  echo -e "    ${BWHITE}install, i${RESET}              Install or update a script."
  echo -e "    ${BWHITE}uninstall, remove, rm${RESET}   Remove an installed script."
  echo
  echo -e "  ${BORANGE}Arguments${RESET}"
  thin_div
  echo -e "    ${BWHITE}[source]${RESET}   Path to a script file or a directory."
  echo -e "             ${DIM}If a directory, the first file inside is used.${RESET}"
  echo -e "             ${DIM}Defaults to: ./${DEFAULT_DIR}/${RESET}"
  echo
  echo -e "  ${BORANGE}Flags${RESET}"
  thin_div
  echo -e "    ${BWHITE}-y, y${RESET}           Skip prompt, use default source (${DEFAULT_DIR}/)."
  echo -e "    ${BWHITE}-h, --help${RESET}      Show this help message."
  echo -e "    ${BWHITE}-v, --version${RESET}   Show version number."
  echo
  echo -e "  ${BORANGE}Examples${RESET}"
  thin_div
  echo -e "    ${DIM}\$${RESET} ./${SCRIPT_NAME} install"
  echo -e "    ${DIM}\$${RESET} ./${SCRIPT_NAME} i -y"
  echo -e "    ${DIM}\$${RESET} ./${SCRIPT_NAME} install path/to/myscript.sh"
  echo -e "    ${DIM}\$${RESET} ./${SCRIPT_NAME} uninstall"
  echo -e "    ${DIM}\$${RESET} ./${SCRIPT_NAME} rm -y"
  echo
  divider
  echo
}

# ── Resolve source path → file ────────────────────────────────────────────────
resolve_source() {
  local src="$1"

  if [[ -d "$src" ]]; then
    local file
    file=$(find "$src" -maxdepth 1 -type f | sort | head -n 1)
    [[ -z "$file" ]] && log_fail "No files found in directory '${src}'"
    echo "$file"
  elif [[ -f "$src" ]]; then
    echo "$src"
  else
    log_fail "File or directory '${src}' not found."
  fi
}

# ── Subcommand: install ───────────────────────────────────────────────────────
cmd_install() {
  local auto=false
  local raw_src=""

  # Parse args
  for arg in "$@"; do
    case "$arg" in
      -y | y) auto=true ;;
      -*) log_fail "Unknown flag: ${arg}. Use --help for usage." ;;
      *) raw_src="$arg" ;;
    esac
  done

  show_banner

  local src
  if $auto; then
    src="$DEFAULT_DIR"
    log_info "Auto mode — using default source: ${BOLD}${src}${RESET}"
    echo
  else
    step "1" "Script Source"
    thin_div
    log_info "Path to a script file or a directory containing one."
    log_info "If a directory is given, the first file inside will be used."
    echo
    if [[ -n "$raw_src" ]]; then
      src="$raw_src"
      log_info "Using provided source: ${BOLD}${src}${RESET}"
    else
      prompt_line "Script path or directory" "${DEFAULT_DIR}/"
      read -r input
      src="${input:-$DEFAULT_DIR}"
    fi
    echo
  fi

  local file
  file=$(resolve_source "$src")
  local command_name
  command_name=$(basename "$file")
  local target_path="${INSTALL_DIR}/${command_name}"

  if $auto; then
    log_ok "Source resolved  →  ${BOLD}${file}${RESET}"
  else
    log_ok "Source resolved to ${BOLD}${file}${RESET}"
    echo
  fi

  divider
  echo

  if [[ -f "$target_path" ]]; then
    log_info "Updating ${BOLD}${command_name}${RESET} in ${INSTALL_DIR}…"
  else
    log_info "Installing ${BOLD}${command_name}${RESET} to ${INSTALL_DIR}…"
  fi
  echo

  chmod +x "$file"

  local tmp_path="/tmp/${command_name}_$$"
  cp "$file" "$tmp_path"
  sudo mv "$tmp_path" "$target_path"
  sudo chmod +x "$target_path"

  divider
  echo
  echo -e "${BORANGE}  ╔══════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BORANGE}  ║${RESET}${BOLD}                    ✅  Done!                                   ${BORANGE}║${RESET}"
  echo -e "${BORANGE}  ╚══════════════════════════════════════════════════════════════════╝${RESET}"
  echo
  log_label "Command   :  ${command_name}"
  log_label "Installed :  ${target_path}"
  log_label "Run with  :  ${command_name}"
  echo
  divider
  echo
}

# ── Subcommand: uninstall ─────────────────────────────────────────────────────
cmd_uninstall() {
  local auto=false
  local raw_src=""

  for arg in "$@"; do
    case "$arg" in
      -y | y) auto=true ;;
      -*) log_fail "Unknown flag: ${arg}. Use --help for usage." ;;
      *) raw_src="$arg" ;;
    esac
  done

  show_banner

  local src
  if $auto; then
    src="$DEFAULT_DIR"
    log_info "Auto mode — using default source: ${BOLD}${src}${RESET}"
    echo
  else
    step "1" "Script to Remove"
    thin_div
    log_info "Provide the name, file path, or directory of the installed command."
    log_info "Defaults to the '${DEFAULT_DIR}/' directory."
    echo
    if [[ -n "$raw_src" ]]; then
      src="$raw_src"
      log_info "Using provided source: ${BOLD}${src}${RESET}"
    else
      prompt_line "Script name, file, or directory" "${DEFAULT_DIR}/"
      read -r input
      src="${input:-$DEFAULT_DIR}"
    fi
    echo
  fi

  # Resolve command name — accept bare name, file path, or directory
  local command_name
  if [[ -d "$src" ]]; then
    local file
    file=$(find "$src" -maxdepth 1 -type f | sort | head -n 1)
    [[ -z "$file" ]] && log_fail "No files found in directory '${src}'"
    command_name=$(basename "$file")
  else
    command_name=$(basename "$src")
  fi

  local target_path="${INSTALL_DIR}/${command_name}"

  log_ok "Resolved command: ${BOLD}${command_name}${RESET}"
  echo

  divider
  echo
  log_info "Removing ${BOLD}${command_name}${RESET} from ${INSTALL_DIR}…"
  echo

  if [[ -f "$target_path" ]]; then
    sudo rm -f "$target_path"
  else
    log_warn "'${command_name}' not found in ${INSTALL_DIR} — nothing to remove."
    echo
    divider
    echo
    exit 0
  fi

  divider
  echo
  echo -e "${BORANGE}  ╔══════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BORANGE}  ║${RESET}${BOLD}                    ✅  Done!                                   ${BORANGE}║${RESET}"
  echo -e "${BORANGE}  ╚══════════════════════════════════════════════════════════════════╝${RESET}"
  echo
  log_label "Command   :  ${command_name}"
  log_label "Removed   :  ${target_path}"
  echo
  divider
  echo
}

# ── Entry point ───────────────────────────────────────────────────────────────
# Handle top-level flags before subcommand dispatch
case "${1:-}" in
  -h | --help)
    show_help
    exit 0
    ;;
  -v | --version)
    echo "${SCRIPT_NAME} v${VERSION}"
    exit 0
    ;;
esac

SUBCOMMAND="${1:-}"
shift || true

case "$SUBCOMMAND" in
  install | i) cmd_install "$@" ;;
  uninstall | remove | rm) cmd_uninstall "$@" ;;
  "")
    show_help
    exit 0
    ;;
  *) log_fail "Unknown subcommand: '${SUBCOMMAND}'. Use --help for usage." ;;
esac
