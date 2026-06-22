_lock_helper() {
    dbus-send --session --dest=org.gnome.ScreenSaver \
        --type=method_call --print-reply \
        /org/gnome/ScreenSaver \
        org.gnome.ScreenSaver.Lock \
        > /dev/null 2>&1
}

# ── Subcommand: lock ─────────────────────────────────────────────────────────
cmd_lock() {
    require_gnome_lock
    echo
    delay_min="${1:-}"
    if [[ -n "$delay_min" && ! "$delay_min" =~ ^[0-9]+$ ]]; then
        log_fail "Delay must be a number (minutes)."
        exit 1
    fi

    if [[ -n "$delay_min" && "$delay_min" -gt 0 ]]; then
        log_info "Lock scheduled in ${BORANGE}${delay_min}${RESET} minute(s)..."

        (
            sleep "$((delay_min * 60))"
            _lock_helper
        ) > /dev/null 2>&1 &
        disown

    else
        log_info "Initializing command..."
        log_info "Locking Screen..."
        _lock_helper
        log_info "Command finished successfully"
    fi

    echo
}
