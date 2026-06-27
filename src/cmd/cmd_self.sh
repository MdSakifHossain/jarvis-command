# =================================================================================
# == Self Management ==============================================================
# =================================================================================

# ── Constants ─────────────────────────────────────────────────────────────────

_SELF_REPO_URL="https://github.com/MdSakifHossain/jarvis-command"
_SELF_INSTALL_URL="https://tr.ee/s7OmWT"

# ── Help ──────────────────────────────────────────────────────────────────────

_show_self_help() {
    cat << EOF

  Manage the jarvis installation itself — update, uninstall, or inspect.

  Usage:

      ${script_name} self <subcommand>

  Subcommands:

      update      Pull and apply the latest version from the repository
      uninstall   Remove jarvis and its shell completions from the system
      source      Clone the source repository into the current directory
      info        Show install path, version, shell, and completion status

  Examples:

      ${script_name} self update
      ${script_name} self uninstall
      ${script_name} self source
      ${script_name} self info

EOF
}

# ── Helpers ───────────────────────────────────────────────────────────────────

_self_require_curl() {
    require_apt_package "curl"
}

_self_completion_status() {
    # Returns "Installed" if the _jarvis completion file is found anywhere in fpath,
    # "Not installed" otherwise.
    local comp_file
    comp_file="$(find /usr/local/share/zsh/site-functions \
        /usr/share/zsh/site-functions \
        "${HOME}/.zsh/completions" \
        "${HOME}/.local/share/zsh/site-functions" \
        -name "_jarvis" 2> /dev/null | head -n1)"
    if [[ -n "$comp_file" ]]; then
        echo "Installed"
    else
        echo "Not installed"
    fi
}

_self_install_path() {
    command -v "${script_name}" 2> /dev/null || echo "(not found in PATH)"
}

_self_detect_shell() {
    # SHELL env var is the login shell; $0 inside bash is the running shell.
    basename "${SHELL:-bash}"
}

# ── Subcommand handlers ───────────────────────────────────────────────────────

_self_update() {
    _self_require_curl

    echo
    log_info "Fetching the latest version of ${script_name}..."
    echo

    if curl -fsSL "${_SELF_INSTALL_URL}" | bash; then
        echo
        log_ok "Update complete."
        echo
        log_txt_dm "  Reload your shell to use the new version:"
        echo
        echo -e "      ${BORANGE}exec \$SHELL${RESET}"
        echo
    else
        echo
        log_fail "Update failed. Check your internet connection and try again."
    fi
}

_self_uninstall() {
    _self_require_curl

    echo
    log_warn "This will remove ${script_name} and its shell completions from your system."
    echo
    prompt_line "Type 'yes' to confirm" "no"
    read -r CONFIRM
    CONFIRM="${CONFIRM:-no}"

    if [[ "$CONFIRM" != "yes" ]]; then
        echo
        log_info "Uninstall cancelled."
        echo
        return 0
    fi

    echo
    log_info "Running uninstaller..."
    echo

    if curl -fsSL "${_SELF_INSTALL_URL}" | bash -s -- uninstall; then
        echo
        log_ok "${script_name} has been uninstalled."
        echo
        log_txt_dm "  Close and re-open your terminal to finish cleaning up."
        echo
    else
        echo
        log_fail "Uninstall failed. Check your internet connection and try again."
    fi
}

_self_source() {
    require_apt_package "git"

    echo
    log_info "Cloning ${script_name} repository into the current directory..."
    echo

    if git clone "${_SELF_REPO_URL}"; then
        echo
        log_ok "Repository cloned → ${PWD}/jarvis-command"
        echo
    else
        echo
        log_fail "Clone failed. Check your internet connection and try again."
    fi
}

_self_info() {
    local install_path version_str completion shell_name

    install_path="$(_self_install_path)"
    version_str="${version:-unknown}"
    completion="$(_self_completion_status)"
    shell_name="$(_self_detect_shell)"

    echo
    show_divider
    echo
    log_clr_l2 "  ${script_name^} v${version_str}"
    echo
    log_label "Install        :  ${install_path}"
    log_label "Repository     :  ${_SELF_REPO_URL}"
    log_label "Shell          :  ${shell_name}"
    log_label "Completions    :  ${completion}"
    echo
    show_divider
    echo
}

# ── Subcommand: self ──────────────────────────────────────────────────────────

cmd_self() {
    # No args → show help
    if [[ $# -eq 0 ]]; then
        _show_self_help
        return 0
    fi

    case "${1:-}" in
        -h | --help | h | help)
            _show_self_help
            return 0
            ;;
    esac

    local SUBCMD="${1:-}"
    shift || true

    case "$SUBCMD" in
        update)
            _self_update
            ;;
        uninstall)
            _self_uninstall
            ;;
        source)
            _self_source
            ;;
        info)
            _self_info
            ;;
        *)
            log_fail "Unknown subcommand '${SUBCMD}'. Run '${script_name} self --help' for usage."
            ;;
    esac
}
