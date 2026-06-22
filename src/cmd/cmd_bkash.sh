# =================================================================================
# == bKash Calculator =============================================================
# =================================================================================

# ── Math helpers ──────────────────────────────────────────────────────────────

_bkash_calc() {
    # $1 = awk expression   returns: computed value rounded to 2 decimal places
    awk "BEGIN { printf \"%.2f\", $1 }"
}

_bkash_get_sendmoney_fee() {
    local amount="$1"
    # Send money fee slabs (fixed, not percentage)
    # 0 – 50        → 0 BDT
    # 50.01 – 25000 → 5 BDT
    # 25000+        → 10 BDT
    awk -v a="$amount" 'BEGIN {
        if (a <= 50)    print "0.00"
        else if (a <= 25000) print "5.00"
        else            print "10.00"
    }'
}

# ── Banner ────────────────────────────────────────────────────────────────────

_show_bkash_banner() {
    echo
    log_clr_l2 "  ██████╗ ██╗  ██╗ █████╗ ███████╗██╗  ██╗"
    log_clr_l2 "  ██╔══██╗██║ ██╔╝██╔══██╗██╔════╝██║  ██║"
    log_clr_l2 "  ██████╔╝█████╔╝ ███████║███████╗███████║"
    log_clr_l1 "  ██╔══██╗██╔═██╗ ██╔══██║╚════██║██╔══██║"
    log_clr_l1 "  ██████╔╝██║  ██╗██║  ██║███████║██║  ██║"
    log_clr_l3 "  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
    echo
    log_clr_l2 "   ██████╗ █████╗ ██╗      ██████╗"
    log_clr_l2 "  ██╔════╝██╔══██╗██║     ██╔════╝"
    log_clr_l2 "  ██║     ███████║██║     ██║     "
    log_clr_l1 "  ██║     ██╔══██║██║     ██║     "
    log_clr_l1 "  ╚██████╗██║  ██║███████╗╚██████╗"
    log_clr_l3 "   ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝"
    echo
    log_txt_dm "  bKash Calculator · Part of ${script_name} v${version}"
    echo
    show_divider
    echo
}

# ── Help ──────────────────────────────────────────────────────────────────────

_show_bkash_help() {
    cat << EOF

  MFS (Mobile Financial Service) calculator for bKash operations.
  Handles cash out and send money math so you never do it in your head.

  Usage:

      ${script_name} bkash <subcommand> [args]
      ${script_name} bkash                        Interactive mode

  Subcommands:

      cashout from <amount> [rate]   You have X — how much do you receive?
      cashout for  <amount> [rate]   You want X in hand — what balance do you need?
      sendmoney    <amount> [rate]   Someone sends you X — what must they have?
      cashin       <amount> [rate]   Alias for sendmoney

  Arguments:

      amount   The BDT amount (required)
      rate     Cash out charge per 1000 BDT (default: 18.5)

  Examples:

      ${script_name} bkash cashout from 1000
      ${script_name} bkash cashout for 1000 14.5
      ${script_name} bkash sendmoney 1000
      ${script_name} bkash cashin 5000 18.5

  Flags:

      -h, --help   Show this help message

EOF
}

# ── Output formatters ─────────────────────────────────────────────────────────

_bkash_show_cashout_from() {
    local amount="$1" rate="$2"
    local charge receivable

    charge=$(_bkash_calc "${amount}/1000*${rate}")
    receivable=$(_bkash_calc "${amount}-${charge}")

    echo
    show_divider
    echo
    log_clr_l2 "  Cash Out — From Balance"
    log_txt_dm "  You have ${amount} BDT. Here is what happens when you cash out."
    echo
    log_label "Your balance      :  ${amount} BDT"
    log_label "Cash out charge   :  ${charge} BDT  ${DIM}(@ ${rate} per 1000)${RESET}"
    log_label "You receive       :  ${receivable} BDT"
    echo
    show_divider
    echo
}

_bkash_show_cashout_for() {
    local amount="$1" rate="$2"
    local charge needed

    charge=$(_bkash_calc "${amount}/1000*${rate}")
    needed=$(_bkash_calc "${amount}+${charge}")

    echo
    show_divider
    echo
    log_clr_l2 "  Cash Out — For Target Amount"
    log_txt_dm "  You want ${amount} BDT in hand. Here is what your wallet must have."
    echo
    log_label "You want in hand  :  ${amount} BDT"
    log_label "Cash out charge   :  ${charge} BDT  ${DIM}(@ ${rate} per 1000)${RESET}"
    log_label "Required balance  :  ${needed} BDT"
    echo
    show_divider
    echo
}

_bkash_show_sendmoney() {
    local amount="$1" rate="$2"
    local charge fee total

    charge=$(_bkash_calc "${amount}/1000*${rate}")
    fee=$(_bkash_get_sendmoney_fee "$amount")
    total=$(_bkash_calc "${amount}+${charge}+${fee}")

    echo
    show_divider
    echo
    log_clr_l2 "  Send Money / Cash In"
    log_txt_dm "  You want ${amount} BDT in hand. Here is what the sender must have."
    echo
    log_label "You want in hand  :  ${amount} BDT"
    log_label "Cash out charge   :  ${charge} BDT  ${DIM}(@ ${rate} per 1000)${RESET}"
    log_label "Send money fee    :  ${fee} BDT  ${DIM}(paid by sender)${RESET}"
    log_label "Sender must have  :  ${total} BDT"
    echo
    show_divider
    echo
}

# ── Input validators ──────────────────────────────────────────────────────────

_bkash_validate_amount() {
    local val="$1"
    [[ "$val" =~ ^[0-9]+([.][0-9]+)?$ ]] || log_fail "Amount must be a positive number. Got: '${val}'"
    awk -v v="$val" 'BEGIN { if (v <= 0) { print "Amount must be greater than 0." > "/dev/stderr"; exit 1 } }'
}

_bkash_validate_rate() {
    local val="$1"
    [[ "$val" =~ ^[0-9]+([.][0-9]+)?$ ]] || log_fail "Rate must be a positive number. Got: '${val}'"
}

# ── Interactive mode ──────────────────────────────────────────────────────────

_bkash_interactive() {
    clear
    _show_bkash_banner

    local DEFAULT_RATE="18.5"

    # Step 1 — Operation
    step "1" "What do you want to calculate?"
    thin_div
    echo -e "  ${ORANGE}1${RESET}  ${BWHITE}cashout from${RESET}  ${DIM}— I have X, how much do I receive?${RESET}"
    echo -e "  ${ORANGE}2${RESET}  ${BWHITE}cashout for${RESET}   ${DIM}— I want X in hand, what balance do I need?${RESET}"
    echo -e "  ${ORANGE}3${RESET}  ${BWHITE}sendmoney${RESET}     ${DIM}— I want X in hand, what must the sender have?${RESET}"
    echo
    prompt_line "Enter 1, 2 or 3" "1"
    read -r INPUT_OP
    INPUT_OP="${INPUT_OP:-1}"

    [[ "$INPUT_OP" =~ ^[123]$ ]] || log_fail "Invalid choice '${INPUT_OP}'. Enter 1, 2, or 3."
    echo

    # Step 2 — Amount
    step "2" "Amount"
    thin_div
    prompt_line "Enter amount (BDT)" ""
    read -r INPUT_AMOUNT
    _bkash_validate_amount "$INPUT_AMOUNT"
    log_ok "Amount → ${BOLD}${INPUT_AMOUNT} BDT${RESET}"
    echo

    # Step 3 — Rate
    step "3" "Cash Out Charge Rate"
    thin_div
    prompt_line "Rate per 1000 BDT" "${DEFAULT_RATE}"
    read -r INPUT_RATE
    INPUT_RATE="${INPUT_RATE:-${DEFAULT_RATE}}"
    _bkash_validate_rate "$INPUT_RATE"
    log_ok "Rate   → ${BOLD}${INPUT_RATE} per 1000${RESET}"

    case "$INPUT_OP" in
        1) _bkash_show_cashout_from "$INPUT_AMOUNT" "$INPUT_RATE" ;;
        2) _bkash_show_cashout_for "$INPUT_AMOUNT" "$INPUT_RATE" ;;
        3) _bkash_show_sendmoney "$INPUT_AMOUNT" "$INPUT_RATE" ;;
    esac
}

# ── Subcommand: bkash ─────────────────────────────────────────────────────────

cmd_bkash() {
    local DEFAULT_RATE="18.5"

    # No args → interactive
    if [[ $# -eq 0 ]]; then
        _bkash_interactive
        return 0
    fi

    # Help flag
    case "${1:-}" in
        -h | --help | h | help)
            _show_bkash_help
            return 0
            ;;
    esac

    local SUBCMD="${1:-}"
    shift || true

    case "$SUBCMD" in

        cashout)
            local DIRECTION="${1:-}"
            shift || true

            case "$DIRECTION" in
                from)
                    local AMOUNT="${1:-}"
                    local RATE="${2:-${DEFAULT_RATE}}"
                    [[ -z "$AMOUNT" ]] && log_fail "Amount required. Usage: ${script_name} bkash cashout from <amount> [rate]"
                    _bkash_validate_amount "$AMOUNT"
                    _bkash_validate_rate "$RATE"
                    _bkash_show_cashout_from "$AMOUNT" "$RATE"
                    ;;
                for)
                    local AMOUNT="${1:-}"
                    local RATE="${2:-${DEFAULT_RATE}}"
                    [[ -z "$AMOUNT" ]] && log_fail "Amount required. Usage: ${script_name} bkash cashout for <amount> [rate]"
                    _bkash_validate_amount "$AMOUNT"
                    _bkash_validate_rate "$RATE"
                    _bkash_show_cashout_for "$AMOUNT" "$RATE"
                    ;;
                "")
                    log_fail "Missing direction. Use: cashout from <amount>  or  cashout for <amount>"
                    ;;
                *)
                    log_fail "Unknown cashout direction '${DIRECTION}'. Use 'from' or 'for'."
                    ;;
            esac
            ;;

        sendmoney | cashin)
            local AMOUNT="${1:-}"
            local RATE="${2:-${DEFAULT_RATE}}"
            [[ -z "$AMOUNT" ]] && log_fail "Amount required. Usage: ${script_name} bkash sendmoney <amount> [rate]"
            _bkash_validate_amount "$AMOUNT"
            _bkash_validate_rate "$RATE"
            _bkash_show_sendmoney "$AMOUNT" "$RATE"
            ;;

        *)
            log_fail "Unknown subcommand '${SUBCMD}'. Run '${script_name} bkash --help' for usage."
            ;;
    esac
}
