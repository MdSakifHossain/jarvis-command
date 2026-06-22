_unlock_helper() {
    dbus-send --session --dest=org.gnome.ScreenSaver \
        --type=method_call --print-reply \
        /org/gnome/ScreenSaver \
        org.gnome.ScreenSaver.SetActive boolean:false \
        > /dev/null 2>&1
}

# ── Subcommand: unlock ───────────────────────────────────────────────────────
cmd_unlock() {
    require_gnome_lock
    echo
    log_info "Initializing command..."
    log_info "Unlocking Screen..."
    _unlock_helper
    log_info "Command finished successfully"
    echo
}
