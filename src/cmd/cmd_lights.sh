_show_light_help() {
    local cmd_name="lights"

    cat << EOF
  Change Color of RAM LED
  
  Usage:
  
      ${script_name} ${cmd_name} [Command]
      ${script_name} ${cmd_name} [Flags]
  
  Available Commands:
  
      on        Turn on RAM LED
      off       Turn off RAM LED
      help      Show Help
  
  Flags:
  
      -h,       Show Help
      --help    Show Help
  
EOF
}

_lights_on_helper() {
    require_openrgb
    echo
    log_info "Turning lights ON..."
    openrgb --mode static --color ffffff > /dev/null 2>&1
    log_info "Command execution Completed"
    echo
}

_lights_off_helper() {
    require_openrgb
    echo
    log_info "Turning lights OFF..."
    openrgb --mode static --color 000000 > /dev/null 2>&1
    log_info "Command execution Completed"
    echo
}

# ── Subcommand: lights ───────────────────────────────────────────────────────
cmd_lights() {
    local cmd_name="lights"

    case "$@" in
        on | 1)
            _lights_on_helper
            ;;
        off | 0)
            _lights_off_helper
            ;;
        -h | --help | h | help)
            _show_light_help
            ;;
        *)
            _show_light_help
            ;;
    esac
}
