#!/usr/bin/env bash
# installer.sh — install / update / uninstall jarvis + Zsh completions
set -euo pipefail

VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GITHUB_RAW="https://raw.githubusercontent.com/MdSakifHossain/jarvis-command/main"
OMZ_DIR="${HOME}/.oh-my-zsh"

# ── Colors ────────────────────────────────────────────────────────────────────
R='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
ORANGE='\033[38;5;209m'
BORANGE='\033[1;38;5;209m'
DIM_ORANGE='\033[2;38;5;209m'

# ── Logging ───────────────────────────────────────────────────────────────────
info() { echo -e "  ${ORANGE}⦿${R}  $*"; }
ok() { echo -e "  ${BORANGE}🟅${R}  $*"; }
fail() {
  echo -e "  ${BORANGE}✖${R}  $*" >&2
  exit 1
}
ask() {
  echo -ne "  ${BORANGE}?${R}  $* ${DIM}[y/N]${R} ${ORANGE}›${R} "
  read -r _a
  [[ "${_a,,}" == y* ]]
}

# ── Termux detection ──────────────────────────────────────────────────────────
is_termux() { [[ -n "${TERMUX_VERSION:-}" || "${PREFIX:-}" == *"com.termux"* ]]; }
INSTALL_DIR="$(is_termux && echo "${PREFIX}/bin" || echo "/usr/local/bin")"

# ── Temp dir (PWD-based, works on Termux and Linux, cleaned up on exit) ───────
TMP_DIR="$(pwd)/.jarvis-tmp"
mkdir -p "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT

# ── Banner ────────────────────────────────────────────────────────────────────
banner() {
  clear
  echo
  echo -e "${BORANGE}  ██╗███╗  ██╗███████╗████████╗ █████╗ ██╗     ██╗     ${R}"
  echo -e "${BORANGE}  ██║████╗ ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ${R}"
  echo -e "${BORANGE}  ██║██╔██╗██║███████╗   ██║   ███████║██║     ██║     ${R}"
  echo -e "${ORANGE}  ██║██║╚████║╚════██║   ██║   ██╔══██║██║     ██║     ${R}"
  echo -e "${ORANGE}  ██║██║ ╚███║███████║   ██║   ██║  ██║███████╗███████╗${R}"
  echo -e "${DIM_ORANGE}  ╚═╝╚═╝  ╚══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝${R}"
  echo
  echo -e "  ${DIM}v${VERSION} · Pure Bash · No dependencies${R}"
  echo
}

# ── Download helper ───────────────────────────────────────────────────────────
fetch() {
  local url="$1" dest="$2"
  if command -v curl &> /dev/null; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget &> /dev/null; then
    wget -qO "$dest" "$url"
  else fail "curl or wget is required"; fi
}

# ── Asset preparation ─────────────────────────────────────────────────────────
# Local mode  : uses files sitting next to installer.sh, nothing downloaded.
# Online mode : downloads everything into TMP_DIR.
# Either way  : TMP_DIR is always cleaned up on exit via the trap above.
CMD_DIR=""
SCHEMA=""
GEN=""
prepare_assets() {
  local ldir="${SCRIPT_DIR}/command"
  local lschema="${SCRIPT_DIR}/jarvis-schema.json"
  local lgen="${SCRIPT_DIR}/generate-completions.py"

  if [[ -d "$ldir" && -f "$lschema" && -f "$lgen" ]]; then
    info "Local assets detected, skipping download"
    CMD_DIR="$ldir"
    SCHEMA="$lschema"
    GEN="$lgen"
  else
    mkdir -p "${TMP_DIR}/command"
    info "Downloading jarvis…"
    fetch "${GITHUB_RAW}/command/jarvis" "${TMP_DIR}/command/jarvis"
    if ! is_termux; then
      info "Downloading schema and generator…"
      fetch "${GITHUB_RAW}/jarvis-schema.json" "${TMP_DIR}/jarvis-schema.json"
      fetch "${GITHUB_RAW}/generate-completions.py" "${TMP_DIR}/generate-completions.py"
      SCHEMA="${TMP_DIR}/jarvis-schema.json"
      GEN="${TMP_DIR}/generate-completions.py"
    fi
    CMD_DIR="${TMP_DIR}/command"
  fi
}

# ── Helpers: python3, omz ─────────────────────────────────────────────────────
ensure_python() {
  command -v python3 &> /dev/null && {
    ok "python3 $(python3 --version 2>&1)"
    return
  }
  ask "python3 not found. Install via apt?" || fail "python3 is required for completions"
  sudo apt update -qq && sudo apt install -y python3
  ok "python3 installed"
}

ensure_omz() {
  [[ -d "$OMZ_DIR" ]] && {
    ok "Oh My Zsh found"
    return
  }
  ask "Oh My Zsh not found. Install now?" || fail "Oh My Zsh is required for completions"
  RUNZSH=no CHSH=no sh -c "$(fetch "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" /dev/stdout 2> /dev/null || true)"
  ok "Oh My Zsh installed"
}

# ── Install / update ──────────────────────────────────────────────────────────
cmd_install() {
  [[ "${1:-}" == -* && "${1:-}" != "-y" ]] && fail "Unknown flag: ${1}. Use --help"
  banner
  prepare_assets

  local file
  file="$(find "$CMD_DIR" -maxdepth 1 -type f | sort | head -1)"
  [[ -n "$file" ]] || fail "No file found in ${CMD_DIR}/"
  local name
  name="$(basename "$file")"
  chmod +x "$file"

  if is_termux; then
    cp "$file" "${INSTALL_DIR}/${name}"
    ok "Installed → ${INSTALL_DIR}/${name}"
    echo
    info "Run: jarvis --help"
  else
    ensure_python
    ensure_omz

    # Stage binary through TMP_DIR so sudo mv is atomic
    cp "$file" "${TMP_DIR}/${name}"
    sudo mv "${TMP_DIR}/${name}" "${INSTALL_DIR}/${name}"
    sudo chmod +x "${INSTALL_DIR}/${name}"
    ok "Installed → ${INSTALL_DIR}/${name}"

    # Generate completion into TMP_DIR — trap will delete it after cp
    info "Generating completions…"
    python3 "$GEN" "$SCHEMA" "${TMP_DIR}/_jarvis"
    mkdir -p "${OMZ_DIR}/completions"
    cp "${TMP_DIR}/_jarvis" "${OMZ_DIR}/completions/_jarvis"
    ok "Completions → ${OMZ_DIR}/completions/_jarvis"
    echo
    info "Reload your shell to activate completions:  exec zsh"
  fi
  echo
}

# ── Uninstall ─────────────────────────────────────────────────────────────────
cmd_uninstall() {
  banner
  prepare_assets

  local file
  file="$(find "$CMD_DIR" -maxdepth 1 -type f | sort | head -1)"
  [[ -n "$file" ]] || fail "No file found in ${CMD_DIR}/"
  local name
  name="$(basename "$file")"
  local target="${INSTALL_DIR}/${name}"

  if is_termux; then
    [[ -f "$target" ]] && rm -f "$target" && ok "Removed → ${target}" || info "${name} not found, skipping"
  else
    [[ -f "$target" ]] && sudo rm -f "$target" && ok "Removed → ${target}" || info "${name} not found, skipping"
    local comp="${OMZ_DIR}/completions/_jarvis"
    [[ -f "$comp" ]] && rm -f "$comp" && ok "Removed → ${comp}" || info "Completion not found, skipping"
    echo
    info "Run: exec zsh"
  fi
  echo
}

# ── Help ──────────────────────────────────────────────────────────────────────
show_help() {
  echo -e "
  ${BORANGE}installer.sh${R} ${DIM}v${VERSION}${R}

  Usage:  ./installer.sh [install|update|uninstall] [-y]
  
  ${ORANGE}install, i, update, u${R}  Install / re-install jarvis
  ${ORANGE}uninstall, rm${R}          Remove jarvis and completions
  ${ORANGE}-y${R}                     Skip prompts
  ${ORANGE}-h, --help${R}             This message
  ${ORANGE}-v, --version${R}          Print version
  "
}

# ── Entry point ───────────────────────────────────────────────────────────────
case "${1:-}" in
  -h | --help | h | help | hlp)
    show_help
    exit 0
    ;;
  -v | --version)
    echo "installer.sh v${VERSION}"
    exit 0
    ;;
esac

SUBCOMMAND="${1:-}"
shift || true

case "$SUBCOMMAND" in
  install | i | update | u | "") cmd_install "$@" ;;
  uninstall | remove | rm) cmd_uninstall "$@" ;;
  *) fail "Unknown subcommand: '${SUBCOMMAND}'. Use --help" ;;
esac
