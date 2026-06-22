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
BLUE='\033[94m'
BBLUE='\033[1;94m'

# ── Color helpers ─────────────────────────────────────────────────────────────
log_clr_l1() { echo -e "${ORANGE}${1}${RESET}"; }
log_clr_l2() { echo -e "${BORANGE}${1}${RESET}"; }
log_clr_l3() { echo -e "${DIM_ORANGE}${1}${RESET}"; }

# ── Text helpers ──────────────────────────────────────────────────────────────
log_txt_nm() { echo -e "${1}"; }
log_txt_bd() { echo -e "${BOLD}${1}${RESET}"; }
log_txt_dm() { echo -e "${DIM}${1}${RESET}"; }

# ── Semantic logging ──────────────────────────────────────────────────────────
log_info() { log_txt_nm "${BLUE}[INFO]${RESET} $*"; }
log_ok() { echo -e "  ${BGREEN}✔${RESET}  $*"; }
log_warn() { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
log_fail() {
    log_txt_nm "${RED}[ERROR]${RESET} $* \n" >&2
    exit 1
}
log_label() { echo -e "  ${BORANGE}▸${RESET}  ${BWHITE}$*${RESET}"; }

# ── UI helpers ────────────────────────────────────────────────────────────────
show_divider() { log_clr_l3 "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }
divider_small() { log_clr_l3 "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }
thin_div() { log_txt_dm "  ──────────────────────────────────────────────────────────────────"; }

prompt_line() {
    # $1 = prompt text   $2 = default value to display
    echo -ne "  ${BORANGE}?${RESET}  ${BWHITE}${1}${RESET} ${DIM}(default: ${2})${RESET} ${ORANGE}›${RESET} "
}

step() {
    # $1 = step number   $2 = step title
    echo -e "  ${BORANGE}[${1}]${RESET}  ${BWHITE}${2}${RESET}"
}

# ── Help ────────────────────────────────────────────────────────────────────
show_help() {
    cat << EOF
${script_name} - ${small_desc}

Usage:

    ${script_name} [command]
    ${script_name} [flags]

Available commands:

    lights, lock, unlock, observe, monitor,
    tree, power, attendance, nmhunt, bkash, version, help

Flags:

    -v, --version   Show Version Info
    -h, --help      Show Help

For more info, Run:

    ${script_name} <command> --help


EOF
}

show_version() {
    log_txt_nm "${script_name} v${version}"
}
