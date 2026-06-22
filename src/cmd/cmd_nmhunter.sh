# =================================================================================
# == Node Modules Hunter ==========================================================
# =================================================================================

# ── Banner ────────────────────────────────────────────────────────────────────

_show_nmhunter_banner() {
    echo
    log_clr_l2 "  ███╗   ██╗ ██████╗ ██████╗ ███████╗"
    log_clr_l2 "  ████╗  ██║██╔═══██╗██╔══██╗██╔════╝"
    log_clr_l2 "  ██╔██╗ ██║██║   ██║██║  ██║█████╗  "
    log_clr_l1 "  ██║╚██╗██║██║   ██║██║  ██║██╔══╝  "
    log_clr_l1 "  ██║ ╚████║╚██████╔╝██████╔╝███████╗"
    log_clr_l3 "  ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝"
    echo
    log_clr_l2 "  ███╗   ███╗ ██████╗ ██████╗ ██╗   ██╗██╗     ███████╗███████╗"
    log_clr_l2 "  ████╗ ████║██╔═══██╗██╔══██╗██║   ██║██║     ██╔════╝██╔════╝"
    log_clr_l2 "  ██╔████╔██║██║   ██║██║  ██║██║   ██║██║     █████╗  ███████╗"
    log_clr_l1 "  ██║╚██╔╝██║██║   ██║██║  ██║██║   ██║██║     ██╔══╝  ╚════██║"
    log_clr_l1 "  ██║ ╚═╝ ██║╚██████╔╝██████╔╝╚██████╔╝███████╗███████╗███████║"
    log_clr_l3 "  ╚═╝     ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝╚══════╝╚══════╝"
    echo
    log_clr_l2 "  ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗ "
    log_clr_l2 "  ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗"
    log_clr_l1 "  ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝"
    log_clr_l1 "  ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗"
    log_clr_l1 "  ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║"
    log_clr_l3 "  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝"
    echo
    log_txt_dm "  Node Modules Hunter · Part of ${script_name} v${version}"
    echo
    show_divider
    echo
}

# ── Help ──────────────────────────────────────────────────────────────────────

_show_nmhunter_help() {
    cat << EOF

  Hunt and eliminate node_modules directories recursively.
  Scans a target directory, previews all targets with sizes,
  then deletes them after confirmation.

  Usage:

      ${script_name} nmhunter
      ${script_name} nmhunter [flags] [directory]

  Arguments:

      directory       Path to scan  (default: ~/projects)

  Flags:

      --dry-run       Scan and preview targets. No files are deleted.
      -y, --yes       Skip confirmation prompt and delete immediately.
      -h, --help      Show this help message.

  Examples:

      ${script_name} nmhunter
      ${script_name} nmhunter ~/work
      ${script_name} nmhunter --dry-run
      ${script_name} nmhunter --yes ~/work

EOF
}

# ── Helpers ───────────────────────────────────────────────────────────────────

_nmhunter_bytes_to_human() {
    local b="$1"
    if ((b >= 1073741824)); then
        echo "$((b / 1073741824)) GB"
    elif ((b >= 1048576)); then
        echo "$((b / 1048576)) MB"
    elif ((b >= 1024)); then
        echo "$((b / 1024)) KB"
    else
        echo "${b} B"
    fi
}

# ── Subcommand: nmhunter ──────────────────────────────────────────────────────

cmd_nmhunter() {
    # ── Flag parsing ──────────────────────────────────────────────────────────
    local DRY_RUN=false
    local SKIP_CONFIRM=false
    local SCAN_DIR=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help | h | help)
                _show_nmhunter_help
                return 0
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -y | --yes)
                SKIP_CONFIRM=true
                shift
                ;;
            -*)
                log_fail "Unknown flag: $1. Run '${script_name} nmhunter --help' for usage."
                ;;
            *)
                SCAN_DIR="$1"
                shift
                ;;
        esac
    done

    # ── Banner ────────────────────────────────────────────────────────────────
    clear
    _show_nmhunter_banner

    if [[ "$DRY_RUN" == true ]]; then
        log_info "${BOLD}Dry-run mode.${RESET} No files will be deleted."
        echo
    fi

    # ── Step 1 — Directory ────────────────────────────────────────────────────
    local DEFAULT_DIR="${HOME}/projects"

    if [[ -z "$SCAN_DIR" ]]; then
        step "1" "Target Directory"
        thin_div
        log_info "Where should I hunt for node_modules?"
        prompt_line "Enter path to scan" "$DEFAULT_DIR"
        read -r INPUT_DIR
        SCAN_DIR="${INPUT_DIR:-$DEFAULT_DIR}"
    fi

    # Expand ~ manually for safety
    SCAN_DIR="${SCAN_DIR/#\~/$HOME}"

    [[ ! -d "$SCAN_DIR" ]] && log_fail "Directory not found: \"${SCAN_DIR}\""

    log_ok "Scan target set to ${BOLD}${SCAN_DIR}${RESET}"
    echo

    # ── Scanning ──────────────────────────────────────────────────────────────
    show_divider
    echo
    log_info "Scanning for targets…"
    echo

    local TARGETS=()
    mapfile -t TARGETS < <(find "$SCAN_DIR" -type d -name "node_modules" -prune 2> /dev/null)

    local TARGET_COUNT=${#TARGETS[@]}

    # ── No targets ────────────────────────────────────────────────────────────
    if [[ "$TARGET_COUNT" -eq 0 ]]; then
        echo -e "${BGREEN}  ╔══════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${BGREEN}  ║${RESET}${BOLD}          ✅  No node_modules found. You're clean.                ${BGREEN}║${RESET}"
        echo -e "${BGREEN}  ╚══════════════════════════════════════════════════════════════════╝${RESET}"
        echo
        log_label "Scanned    :  ${SCAN_DIR}"
        log_label "Targets    :  0"
        echo
        show_divider
        echo
        return 0
    fi

    # ── Preview targets ───────────────────────────────────────────────────────
    log_clr_l2 "  Targets located:"
    echo

    local dir SIZE
    for dir in "${TARGETS[@]}"; do
        SIZE=$(du -sh "$dir" 2> /dev/null | cut -f1) || SIZE="unknown"
        echo -e "    ${ORANGE}◆${RESET}  ${BWHITE}${dir}${RESET}  ${DIM}(${SIZE})${RESET}"
    done
    echo

    local TOTAL_SIZE
    TOTAL_SIZE=$(du -sh "${TARGETS[@]}" 2> /dev/null | tail -1 | cut -f1) || TOTAL_SIZE="unknown"
    log_info "Found ${BOLD}${TARGET_COUNT}${RESET} target(s) — approx. ${BOLD}${TOTAL_SIZE}${RESET} total."
    echo

    # ── Dry-run exits here ────────────────────────────────────────────────────
    if [[ "$DRY_RUN" == true ]]; then
        show_divider
        echo
        echo -e "${BORANGE}  ╔══════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${BORANGE}  ║${RESET}${BOLD}           ◌  Dry run complete. Nothing was deleted.              ${BORANGE}║${RESET}"
        echo -e "${BORANGE}  ╚══════════════════════════════════════════════════════════════════╝${RESET}"
        echo
        log_label "Scanned    :  ${SCAN_DIR}"
        log_label "Found      :  ${TARGET_COUNT} target(s)"
        log_label "Total size :  ${TOTAL_SIZE}"
        log_label "Deleted    :  0 (dry run)"
        echo
        show_divider
        echo
        return 0
    fi

    # ── Confirmation ──────────────────────────────────────────────────────────
    if [[ "$SKIP_CONFIRM" == false ]]; then
        thin_div
        echo -ne "  ${BORANGE}?${RESET}  ${BWHITE}Found ${TARGET_COUNT} target(s). Proceed with elimination?${RESET} ${DIM}(Enter = yes, Ctrl+C = abort)${RESET} ${ORANGE}›${RESET} "
        read -r CONFIRM
        CONFIRM="${CONFIRM,,}"
        if [[ "$CONFIRM" == "n" || "$CONFIRM" == "no" ]]; then
            echo
            log_warn "Aborted. Nothing was deleted."
            echo
            show_divider
            echo
            return 0
        fi
        echo
    fi

    # ── Elimination ───────────────────────────────────────────────────────────
    show_divider
    echo
    log_info "Initiating elimination sequence…"
    echo

    local DELETED=0
    local FAILED=0
    local FREED=0
    local SIZE_BYTES SIZE_HUMAN

    for dir in "${TARGETS[@]}"; do
        SIZE_BYTES=$(du -sb "$dir" 2> /dev/null | cut -f1) || SIZE_BYTES=0
        SIZE_HUMAN=$(du -sh "$dir" 2> /dev/null | cut -f1) || SIZE_HUMAN="unknown"

        echo -e "  ${ORANGE}◆${RESET}  ${BWHITE}${dir}${RESET}  ${DIM}(${SIZE_HUMAN})${RESET}"

        if rm -rf "$dir" 2> /dev/null; then
            log_ok "Eliminated."
            ((DELETED++)) || true
            ((FREED += SIZE_BYTES)) || true
        else
            log_warn "Could not delete — permission denied or already gone."
            ((FAILED++)) || true
        fi
        echo
    done

    local FREED_HUMAN
    FREED_HUMAN=$(_nmhunter_bytes_to_human "$FREED")

    # ── Summary ───────────────────────────────────────────────────────────────
    show_divider
    echo
    echo -e "${BORANGE}  ╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BORANGE}  ║${RESET}${BOLD}                  ✅  Sweep complete.                             ${BORANGE}║${RESET}"
    echo -e "${BORANGE}  ╚══════════════════════════════════════════════════════════════════╝${RESET}"
    echo
    log_label "Scanned    :  ${SCAN_DIR}"
    log_label "Found      :  ${TARGET_COUNT} target(s)"
    log_label "Eliminated :  ${DELETED}"
    [[ "$FAILED" -gt 0 ]] && echo -e "  ${YELLOW}⚠${RESET}  ${BWHITE}Failed     :  ${FAILED} (check permissions)${RESET}"
    log_label "Space freed:  ${FREED_HUMAN}"
    echo
    show_divider
    echo
}
