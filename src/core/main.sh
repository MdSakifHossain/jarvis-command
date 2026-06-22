# =================================================================================
# == Main Function ================================================================
# =================================================================================

main() {
    case "${1:-}" in
        v | -v | version | --version)
            show_version
            exit 0
            ;;
        h | -h | help | --help)
            show_help
            exit 0
            ;;
    esac

    local SUBCOMMAND="${1:-}"
    shift || true

    case "$SUBCOMMAND" in
        light | lights | ram | rams | led | leds | lt | lts)
            cmd_lights "$@"
            exit 0
            ;;
        lock)
            cmd_lock "$@"
            exit 0
            ;;
        unlock)
            cmd_unlock
            exit 0
            ;;
        observe | monitor)
            cmd_observe_vault_log
            ;;
        poweroff | power | pwr | shutdown)
            sudo shutdown now
            ;;
        tree | list | lst | ls)
            cmd_tree
            exit 0
            ;;
        attendance | attend | att)
            cmd_attendance "$@"
            exit 0
            ;;
        nmhunter | nmhunt | nm | hunt | hunter)
            cmd_nmhunter "$@"
            exit 0
            ;;
        bkash | bk)
            cmd_bkash "$@"
            exit 0
            ;;
        *)
            show_help
            exit 0
            ;;
    esac
}
