_require_file() {
    local path="$1"
    local description="${2:-Required file}"

    [[ -f "$path" ]] || log_fail "$description not found.

Expected location:
    $path"
}

# ── Banner ────────────────────────────────────────────────────────────────────
_show_wlc_back_small_banner() {
    echo
    log_clr_l2 "    _      __      __                      "
    log_clr_l2 "   | | /| / /___  / /____ ___   __ _  ___  "
    log_clr_l2 "   | |/ |/ // -_)/ // __// _ \ /  ' \/ -_) "
    log_clr_l2 "   |__/|__/ \__//_/ \__/ \___//_/_/_/\__/  "
    log_clr_l2 "     ___              __      ____ _       "
    log_clr_l2 "    / _ ) ___ _ ____ / /__   / __/(_)____  "
    log_clr_l2 "   / _  |/ _ '// __//  '_/  _\ \ / // __/_ "
    log_clr_l2 "  /____/ \_,_/ \__//_/\_\  /___//_//_/  (_)"
    echo
}

_show_wlc_back_normal_banner() {
    echo
    log_clr_l2 "  ██╗    ██╗███████╗██╗      ██████╗ ██████╗ ███╗   ███╗███████╗"
    log_clr_l2 "  ██║    ██║██╔════╝██║     ██╔════╝██╔═══██╗████╗ ████║██╔════╝"
    log_clr_l2 "  ██║ █╗ ██║█████╗  ██║     ██║     ██║   ██║██╔████╔██║█████╗  "
    log_clr_l1 "  ██║███╗██║██╔══╝  ██║     ██║     ██║   ██║██║╚██╔╝██║██╔══╝  "
    log_clr_l1 "  ╚███╔███╔╝███████╗███████╗╚██████╗╚██████╔╝██║ ╚═╝ ██║███████╗"
    log_clr_l3 "   ╚══╝╚══╝ ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝"
    echo
    log_clr_l2 "  ██████╗  █████╗  ██████╗██╗  ██╗    ███████╗██╗██████╗        "
    log_clr_l2 "  ██╔══██╗██╔══██╗██╔════╝██║ ██╔╝    ██╔════╝██║██╔══██╗       "
    log_clr_l2 "  ██████╔╝███████║██║     █████╔╝     ███████╗██║██████╔╝       "
    log_clr_l1 "  ██╔══██╗██╔══██║██║     ██╔═██╗     ╚════██║██║██╔══██╗       "
    log_clr_l1 "  ██████╔╝██║  ██║╚██████╗██║  ██╗    ███████║██║██║  ██║██╗    "
    log_clr_l3 "  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝╚═╝╚═╝  ╚═╝╚═╝    "
    echo
}

_show_wlc_back_banner() {
    current_width=$(tput cols 2> /dev/null || echo 80) # Get current terminal width
    cutoff_width=60                                    # Define what counts as "small"

    is_small=false
    if [ "$current_width" -lt "$cutoff_width" ]; then
        is_small=true
    fi

    if $is_small; then
        _show_wlc_back_small_banner
    else
        _show_wlc_back_normal_banner
    fi

    log_txt_dm "  Type \"${script_name} --help\" for more details."

    if $is_small; then
        divider_small
    else
        show_divider
    fi

    echo
}

_refresh_wlc_back_banner() {
    clear
    _show_wlc_back_banner
}

# ── Subcommand: observe ──────────────────────────────────────────────────────
cmd_observe_vault_log() {
    local vault_log_file="$HOME/.local/logs/vault-observer.log"

    _require_file "$vault_log_file" "Vault observer log file"

    _refresh_wlc_back_banner
    tail -f "$vault_log_file"
}
