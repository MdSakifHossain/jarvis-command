# =================================================================================
# == Attendance Sheet Generator ===================================================
# =================================================================================

# ── Date helpers ──────────────────────────────────────────────────────────────

_month_name_to_num() {
    case "${1,,}" in
        january | jan) echo "1" ;;
        february | feb) echo "2" ;;
        march | mar) echo "3" ;;
        april | apr) echo "4" ;;
        may) echo "5" ;;
        june | jun) echo "6" ;;
        july | jul) echo "7" ;;
        august | aug) echo "8" ;;
        september | sep) echo "9" ;;
        october | oct) echo "10" ;;
        november | nov) echo "11" ;;
        december | dec) echo "12" ;;
        *) echo "" ;;
    esac
}

_is_leap_year() {
    local y="$1"
    if ((y % 400 == 0)); then
        echo 1
    elif ((y % 100 == 0)); then
        echo 0
    elif ((y % 4 == 0)); then
        echo 1
    else
        echo 0
    fi
}

_days_in_month() {
    local m="$1" y="$2"
    case "$m" in
        1 | 3 | 5 | 7 | 8 | 10 | 12) echo 31 ;;
        4 | 6 | 9 | 11) echo 30 ;;
        2) [[ $(_is_leap_year "$y") == "1" ]] && echo 29 || echo 28 ;;
    esac
}

_weekday_name() {
    local d="$1" m="$2" y="$3"
    if ((m < 3)); then
        ((m += 12))
        ((y -= 1))
    fi
    local k=$((y % 100))
    local j=$((y / 100))
    local h=$(((d + (13 * (m + 1)) / 5 + k + k / 4 + j / 4 - 2 * j) % 7))
    ((h < 0)) && ((h += 7))
    local days=("Sat" "Sun" "Mon" "Tue" "Wed" "Thu" "Fri")
    echo "${days[$h]}"
}

# ── Markdown table builder ────────────────────────────────────────────────────

_build_week_section() {
    local title="$1"
    local start="$2"
    local end="$3"
    local month="$4"
    local year="$5"

    local header="| Name | Class |"
    local sep="| :-------- | :---: |"

    for ((d = start; d <= end; d++)); do
        local wday
        wday=$(_weekday_name "$d" "$month" "$year")
        header+=" ${d}<br>\`(${wday})\` |"
        sep+=" :----------: |"
    done

    header+=" Total |"
    sep+=" :---: |"

    echo "### ${title}"
    echo
    echo "${header}"
    echo "${sep}"

    for ((i = 1; i <= STUDENT_COUNT; i++)); do
        local row="| Student_${i} | ? |"
        for ((d = start; d <= end; d++)); do
            local wday
            wday=$(_weekday_name "$d" "$month" "$year")
            if [[ "$wday" == "Fri" ]]; then
                row+="  x  |"
            else
                row+="  -  |"
            fi
        done
        row+="     |"
        echo "${row}"
    done

    echo
}

# ── Attendance banner ─────────────────────────────────────────────────────────

_show_attendance_banner() {
    echo
    log_clr_l2 "   █████╗ ████████╗████████╗███████╗███╗   ██╗██████╗  █████╗ ███╗   ██╗ ██████╗███████╗"
    log_clr_l2 "  ██╔══██╗╚══██╔══╝╚══██╔══╝██╔════╝████╗  ██║██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔════╝"
    log_clr_l1 "  ███████║   ██║      ██║   █████╗  ██╔██╗ ██║██║  ██║███████║██╔██╗ ██║██║     █████╗  "
    log_clr_l1 "  ██╔══██║   ██║      ██║   ██╔══╝  ██║╚██╗██║██║  ██║██╔══██║██║╚██╗██║██║     ██╔══╝  "
    log_clr_l1 "  ██║  ██║   ██║      ██║   ███████╗██║ ╚████║██████╔╝██║  ██║██║ ╚████║╚██████╗███████╗"
    log_clr_l3 "  ╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝"
    echo
    log_clr_l2 "  ███████╗██╗  ██╗███████╗███████╗████████╗"
    log_clr_l1 "  ██╔════╝██║  ██║██╔════╝██╔════╝╚══██╔══╝"
    log_clr_l1 "  ███████╗███████║█████╗  █████╗     ██║   "
    log_clr_l1 "  ╚════██║██╔══██║██╔══╝  ██╔══╝     ██║   "
    log_clr_l1 "  ███████║██║  ██║███████╗███████╗   ██║   "
    log_clr_l3 "  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝   "
    echo
    log_clr_l2 "   ██████╗ ███████╗███╗   ██╗███████╗██████╗  █████╗ ████████╗ ██████╗ ██████╗ "
    log_clr_l2 "  ██╔════╝ ██╔════╝████╗  ██║██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗"
    log_clr_l1 "  ██║  ███╗█████╗  ██╔██╗ ██║█████╗  ██████╔╝███████║   ██║   ██║   ██║██████╔╝"
    log_clr_l1 "  ██║   ██║██╔══╝  ██║╚██╗██║██╔══╝  ██╔══██╗██╔══██║   ██║   ██║   ██║██╔══██╗"
    log_clr_l1 "  ╚██████╔╝███████╗██║ ╚████║███████╗██║  ██║██║  ██║   ██║   ╚██████╔╝██║  ██║"
    log_clr_l3 "   ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝"
    echo
    log_txt_dm "  Attendance Sheet Generator · Part of ${script_name} v${version}"
    echo
    show_divider
    echo
}

# ── Attendance help ───────────────────────────────────────────────────────────

_show_attendance_help() {
    cat << EOF

  Generates a weekly Markdown attendance skeleton for a given month.
  Fridays are auto-marked X. All other days default to - (absent).
  Days 1-28 split into 4 weeks. Days 29-31 go into Extra Days.

  Usage:

      ${script_name} attendance
      ${script_name} attendance [flags]

  Flags:

      -h, --help    Show this help message.

EOF
}

# ── Subcommand: attendance ────────────────────────────────────────────────────

cmd_attendance() {
    case "${1:-}" in
        -h | --help | h | help)
            _show_attendance_help
            return 0
            ;;
    esac

    clear
    _show_attendance_banner

    log_info "Generates a Markdown attendance skeleton from your student roster."
    log_info "Fridays auto-marked ${BOLD}X${RESET}. All other days default to ${BOLD}-${RESET} (absent)."
    echo

    # ── STEP 1 — Month ────────────────────────────────────────────────────────
    local CURRENT_MONTH CURRENT_YEAR MONTH_NAME MONTH_NUM YEAR STUDENT_COUNT
    local TOTAL_DAYS FILENAME OUTPUT_PATH EXTRA_START EXTRA_END

    CURRENT_MONTH=$(date +"%B")
    CURRENT_YEAR=$(date +"%Y")

    step "1" "Month"
    thin_div
    prompt_line "Enter month name" "$CURRENT_MONTH"
    read -r INPUT_MONTH
    INPUT_MONTH="${INPUT_MONTH:-$CURRENT_MONTH}"

    MONTH_NAME="${INPUT_MONTH,,}"
    MONTH_NAME="${MONTH_NAME^}"

    MONTH_NUM=$(_month_name_to_num "$MONTH_NAME")
    [[ -z "$MONTH_NUM" ]] && log_fail "\"${INPUT_MONTH}\" is not a recognised month name."

    log_ok "Month → ${BOLD}${MONTH_NAME}${RESET}"
    echo

    # ── STEP 2 — Year ─────────────────────────────────────────────────────────
    step "2" "Year"
    thin_div
    prompt_line "Enter year (4-digit)" "$CURRENT_YEAR"
    read -r INPUT_YEAR
    INPUT_YEAR="${INPUT_YEAR:-$CURRENT_YEAR}"

    [[ ! "$INPUT_YEAR" =~ ^[0-9]{4}$ ]] && log_fail "\"${INPUT_YEAR}\" is not a valid 4-digit year."
    YEAR="$INPUT_YEAR"

    log_ok "Year  → ${BOLD}${YEAR}${RESET}"
    echo

    # ── STEP 3 — Student count ─────────────────────────────────────────────────
    step "3" "Student Count"
    thin_div
    prompt_line "How many students?" "2"
    read -r INPUT_COUNT
    INPUT_COUNT="${INPUT_COUNT:-2}"

    [[ ! "$INPUT_COUNT" =~ ^[0-9]+$ ]] && log_fail "\"${INPUT_COUNT}\" is not a valid number."
    ((INPUT_COUNT < 1 || INPUT_COUNT > 50)) && log_fail "Student count must be between 1 and 50."
    STUDENT_COUNT="$INPUT_COUNT"

    log_ok "Students → ${BOLD}${STUDENT_COUNT}${RESET}"
    echo

    # ── Build ──────────────────────────────────────────────────────────────────
    show_divider
    echo
    log_info "Building attendance skeleton…"
    echo

    TOTAL_DAYS=$(_days_in_month "$MONTH_NUM" "$YEAR")
    FILENAME="Attendance-${MONTH_NAME}-${YEAR}.md"
    OUTPUT_PATH="./${FILENAME}"
    EXTRA_START=29
    EXTRA_END="$TOTAL_DAYS"

    {
        echo "# Attendance - ${MONTH_NAME} ${YEAR}"
        echo
        echo "## System Codes"
        echo
        echo "| Code | Meaning                            |"
        echo "| :--: | :--------------------------------- |"
        echo "| \`P\`  | Present                            |"
        echo "| \`-\`  | Absent (was expected, didn't come) |"
        echo "| \`X\`  | No class (any reason)              |"
        echo "| \`N\`  | Not joined yet                     |"
        echo "| \`D\`  | Discontinued (no longer expected)  |"
        echo
        echo "## Sheets"
        echo

        _build_week_section "Week 1" 1 7 "$MONTH_NUM" "$YEAR"
        _build_week_section "Week 2" 8 14 "$MONTH_NUM" "$YEAR"
        _build_week_section "Week 3" 15 21 "$MONTH_NUM" "$YEAR"
        _build_week_section "Week 4" 22 28 "$MONTH_NUM" "$YEAR"

        if ((TOTAL_DAYS > 28)); then
            _build_week_section "Extra Days" "$EXTRA_START" "$EXTRA_END" "$MONTH_NUM" "$YEAR"
        fi
    } > "$OUTPUT_PATH"

    # ── Done ───────────────────────────────────────────────────────────────────
    show_divider
    echo
    echo -e "${BORANGE}  ╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BORANGE}  ║${RESET}${BOLD}               ✅  Attendance sheet created!                      ${BORANGE}║${RESET}"
    echo -e "${BORANGE}  ╚══════════════════════════════════════════════════════════════════╝${RESET}"
    echo
    log_label "File      :  ${FILENAME}"
    log_label "Saved to  :  ${OUTPUT_PATH}"
    log_label "Period    :  ${MONTH_NAME} ${YEAR}"
    log_label "Days      :  ${TOTAL_DAYS}"
    log_label "Students  :  ${STUDENT_COUNT}"
    log_label "Leap year :  $([[ $(_is_leap_year "$YEAR") == "1" ]] && echo "Yes" || echo "No")"
    echo
    show_divider
    echo
}
