# JARVIS — Context & Implementation Guide

> **This file is the single source of truth for the `jarvis` script.**
> Read this before touching the code. Every rule here exists because
> something broke or looked wrong without it.

---

## Table of Contents

1. [What is jarvis](#1-what-is-jarvis)
2. [File structure](#2-file-structure)
3. [Versioning](#3-versioning)
4. [Color system](#4-color-system)
5. [Logging & UI helpers](#5-logging--ui-helpers)
6. [Guard / require helpers](#6-guard--require-helpers)
7. [Banner system](#7-banner-system)
8. [Help system](#8-help-system)
9. [Command anatomy](#9-command-anatomy)
10. [Dispatcher (Execution block)](#10-dispatcher-execution-block)
11. [Private functions — the `_` prefix convention](#11-private-functions--the-_-prefix-convention)
12. [Interactive input pattern](#12-interactive-input-pattern)
13. [Naming conventions](#13-naming-conventions)
14. [How to add a new command — step by step](#14-how-to-add-a-new-command--step-by-step)
15. [What not to do](#15-what-not-to-do)

---

## 1. What is jarvis

`jarvis` is a single-file personal CLI tool written in pure bash. It runs on Ubuntu. It has no build step, no package manager, no external runtime — just one file that you `chmod +x` and put on your `$PATH`.

It is intentionally a monolith. Everything lives in one file. There is no `source`-ing of external files, no plugin system, no config directory. If you are coming from JS and thinking "I'll split this into modules" — don't. The monolith is the design.

**Shell:** bash (not sh, not zsh)
**Platform:** Ubuntu (some commands are Ubuntu/GNOME-only)

---

## 2. File structure

The file is organized in this exact top-to-bottom order. Do not rearrange sections.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Identity
# Colors
# Color helpers
# Text helpers
# Semantic logging
# UI helpers
# Guard / require helpers
# Banner system
# Help system

# ── Feature sections ──────────────────────────────────────────────
# Each feature block looks like this:
#
# ═══════════════════════════════════════════
# == Feature Name ============================
# ═══════════════════════════════════════════
#
# (private helpers prefixed with _)
# (private banner prefixed with _show_<name>_banner)
# (private help prefixed with _show_<name>_help)
# (public cmd function: cmd_<name>)

# ── Execution block ───────────────────────
# case dispatcher — always last
```

The execution block (`case "$SUBCOMMAND"`) is **always the last thing in the file**.

---

## 3. Versioning

Version is stored in the `version` variable near the top:

```bash
version="1.13.0"
```

Format is `MAJOR.MINOR.PATCH`. Bump rules:

| Change type                          | Bump  |
| :----------------------------------- | :---- |
| New command added                    | MINOR |
| Bug fix inside an existing command   | PATCH |
| Breaking change to existing behavior | MAJOR |

**Always bump the version when making any change.** Even a one-line fix gets a PATCH bump.

---

## 4. Color system

These are the only color variables that exist. Do not add new ones without a real reason.

```bash
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
ORANGE='\033[38;5;209m'      # salmon-orange, primary brand color
BORANGE='\033[1;38;5;209m'   # bold orange, used for emphasis
DIM_ORANGE='\033[2;38;5;209m' # dim orange, used for decorative/secondary
BWHITE='\033[1;37m'           # bold white, used for labels and step titles
BGREEN='\033[1;32m'           # bold green, used for success (✔)
RED='\033[0;31m'              # red, used for errors only
YELLOW='\033[1;33m'           # yellow, used for warnings only
BLUE='\033[94m'               # blue, used for [INFO] tag only
BBLUE='\033[1;94m'            # bold blue, available but currently unused
```

The **brand palette is orange**. That's the identity of jarvis. Blue is reserved for `[INFO]` only. Green for success only. Red for errors only. Yellow for warnings only.

---

## 5. Logging & UI helpers

These are the only helpers you use inside any command. Never `echo` raw ANSI codes directly.

### Color wrappers (for ASCII art / banners only)

```bash
log_clr_l1()  # ORANGE    — mid brightness lines
log_clr_l2()  # BORANGE   — top/bright lines
log_clr_l3()  # DIM_ORANGE — dim/fade lines
```

These three are exclusively for multi-line ASCII art rendering. Do not use them for regular output.

### Text wrappers

```bash
log_txt_nm()  # plain echo (no color)
log_txt_bd()  # bold text
log_txt_dm()  # dim text — used for secondary/hint text
```

### Semantic logging

```bash
log_info()   # [INFO] in blue  — informational, non-critical messages
log_ok()     # ✔ in green      — confirms something succeeded
log_warn()   # ⚠ in yellow    — something is off but not fatal
log_fail()   # [ERROR] in red  — prints to stderr and exits 1
log_label()  # ▸ in orange     — used in summary blocks (key: value lines)
```

**`log_fail` always exits.** Never call it if you want to continue execution.

### UI structure helpers

```bash
show_divider()   # long ━━━ line in dim orange — major section separator
divider_small()  # shorter ━━━ line — used when terminal is narrow
thin_div()       # short ── line in dim — used under step headers
```

### Interactive input helpers

```bash
prompt_line "Question text" "default value"
# Renders:  ?  Question text (default: value) ›
# Does NOT read input — just prints the prompt.
# Always follow with: read -r VARIABLE_NAME

step "1" "Step Title"
# Renders:  [1]  Step Title
# Used to visually number steps in interactive commands.
```

---

## 6. Guard / require helpers

These check for a precondition and call `log_fail` (exit) if it's not met. Always call them at the top of a `cmd_*` function that needs them.

```bash
require_ubuntu
# Exits if not running on Ubuntu.

require_apt_package "cmd" "package-name"
# Exits if `cmd` is not in PATH.
# Second arg is the apt package name shown in the error message.
# If second arg is omitted, package name defaults to first arg.

require_external_dependency "cmd" "hint message"
# Same as above but for non-apt software.
# Second arg is a freeform hint shown in the error.

require_openrgb
# Shorthand for require_external_dependency for openrgb specifically.

require_dbus
# Checks for dbus-send.

require_gnome_screensaver
# Checks GNOME screen saver is reachable via dbus.

require_gnome_lock
# require_dbus + require_gnome_screensaver combined.

require_file "/path/to/file" "Description of the file"
# Exits if the file does not exist.
```

---

## 7. Banner system

Jarvis has a terminal-width-aware main banner. This is how it works:

```bash
show_banner()
# Detects terminal width via `tput cols`.
# If width < 60: renders show_banner_1 (compact ASCII art) + divider_small
# If width >= 60: renders show_banner_2 (full block ASCII art) + show_divider
# Always ends with a hint line: Type "jarvis --help" for more details.

refresh_banner()
# clear + show_banner. Used when a command wants to wipe the screen first.

show_banner_1()   # compact text art (for narrow terminals)
show_banner_2()   # full block art (for normal terminals)
```

**Feature-specific banners** follow a different pattern. Each feature that has its own interactive flow gets its own `_show_<feature>_banner()` function. It is a private function (underscore prefix). It always:

- Renders its own block ASCII art using `log_clr_l1/l2/l3`
- Ends with a `log_txt_dm` line: `"  <Feature Name> · Part of ${script_name} v${version}"`
- Calls `show_divider`
- Prints a blank `echo`

Example from `attendance`:

```bash
_show_attendance_banner() {
    echo
    # ... ASCII art lines using log_clr_l1/l2/l3 ...
    echo
    log_txt_dm "  Attendance Sheet Generator · Part of ${script_name} v${version}"
    echo
    show_divider
    echo
}
```

The feature banner is called with `clear` before it inside the `cmd_*` function, not inside the banner function itself.

---

## 8. Help system

There are two tiers of help.

### Tier 1 — global help

`show_help()` — called when the user runs `jarvis --help` or `jarvis help`. It lists all available commands. **Always update this list when adding a new command.**

```bash
show_help() {
    cat << EOF
${script_name} - ${small_desc}

Usage:
    ...

Available commands:
    lights, lock, unlock, observe, monitor,
    tree, power, attendance, version, help
    # ↑ add your new command here

...
EOF
}
```

### Tier 2 — per-command help

Each command that has sub-options or interactive steps gets its own help function. Named `_show_<command>_help()`. It is private (underscore prefix). It is called inside `cmd_<name>` when the user passes `-h` or `--help`.

Format uses a `cat << EOF` heredoc. No fancy formatting — plain text, indented with spaces. Keep it short: usage, flags, brief description. That's it.

---

## 9. Command anatomy

Every command follows this exact structure. Do not deviate.

```bash
# ── Subcommand: <name> ────────────────────────────────────────────

cmd_<name>() {
    # 1. Guard checks first (if needed)
    require_ubuntu
    require_apt_package "something"

    # 2. Flag/subcommand handling
    case "${1:-}" in
        -h|--help|h|help)
            _show_<name>_help
            return 0
            ;;
        # other subcommands...
    esac

    # 3. Declare all local variables up front
    local VAR_ONE VAR_TWO VAR_THREE

    # 4. If interactive: clear + show feature banner
    clear
    _show_<name>_banner

    # 5. Interactive steps (if any)
    step "1" "Step Title"
    thin_div
    prompt_line "Question?" "default"
    read -r INPUT
    # validate input
    log_ok "Confirmed → ${BOLD}${INPUT}${RESET}"
    echo

    # 6. Do the actual work

    # 7. Summary block at the end (if applicable)
    show_divider
    echo
    log_label "Key  :  Value"
    echo
    show_divider
    echo
}
```

**Critical rules:**

- All variables inside `cmd_*` functions must be declared `local`. No globals leaking out.
- Use `return 0` to exit a function, not `exit 0`. (`exit` kills the whole process from inside a function.)
- Always put guards at the very top before any other logic.

---

## 10. Dispatcher (Execution block)

The execution block is at the bottom of the file. It is a two-stage case statement.

**Stage 1** — flags that exit before any subcommand processing:

```bash
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
```

**Stage 2** — subcommand dispatch:

```bash
SUBCOMMAND="${1:-}"
shift || true   # shift safely even if no args

case "$SUBCOMMAND" in
    mycommand | mc | alias)
        cmd_mycommand "$@"
        exit 0
        ;;
    *)
        show_help
        exit 0
        ;;
esac
```

**Rules:**

- Every command gets `exit 0` after its `cmd_*` call (except `observe` which uses `tail -f` and blocks — it has no `exit`).
- The `*)` fallthrough always calls `show_help`. Never silently fail.
- `shift || true` is intentional — `set -e` would kill the script if `shift` is called with no args. The `|| true` prevents that.
- Aliases go in the same `case` pattern: `lights | light | ram | rams | led | leds | lt | lts`.

---

## 11. Private functions — the `_` prefix convention

Any function that is **not meant to be called directly by the dispatcher** gets an underscore prefix. This is the jarvis equivalent of "private" or "module-internal".

```bash
_month_name_to_num()    # private helper, only used inside attendance
_is_leap_year()         # private helper
_build_week_section()   # private builder
_show_attendance_banner() # private banner
_show_attendance_help()   # private help
```

Public functions (called by dispatcher or user-facing) have no underscore:

```bash
cmd_attendance()
cmd_lights()
show_banner()
log_info()
require_ubuntu()
```

This convention is not enforced by bash. It is a communication tool — it tells the next person "don't call this from the dispatcher, it's an implementation detail."

---

## 12. Interactive input pattern

Every interactive prompt in jarvis follows the same 5-line pattern:

```bash
prompt_line "Question text?" "default_value"
read -r RAW_INPUT
RAW_INPUT="${RAW_INPUT:-default_value}"

# Validate
[[ ! "$RAW_INPUT" =~ ^[0-9]+$ ]] && log_fail "Not a number."
(( RAW_INPUT < 1 || RAW_INPUT > 100 )) && log_fail "Out of range."

FINAL_VAR="$RAW_INPUT"
log_ok "Label → ${BOLD}${FINAL_VAR}${RESET}"
echo
```

**Validation rules:**

- Integer check: `[[ ! "$VAR" =~ ^[0-9]+$ ]]`
- 4-digit year: `[[ ! "$VAR" =~ ^[0-9]{4}$ ]]`
- Range check: `(( VAR < MIN || VAR > MAX ))`
- String from known set: `case`/`esac` that emits `""` on no match, then `[[ -z "$RESULT" ]]`

Always show `log_ok` after a successful input. Always print a blank `echo` after `log_ok` to separate steps visually.

---

## 13. Naming conventions

These are the rules for naming things so you don't break existing code.

### The underscore prefix

- **Public functions** (called by the dispatcher or user-facing): no underscore. Example: `cmd_lights()`, `show_banner()`.
- **Private functions** (implementation details): underscore prefix. Example: `_is_leap_year()`, `_show_attendance_banner()`.

### Reserved namespaces

Do not create new functions or global variables that collide with these patterns. They are reserved for specific purposes:

| Prefix | Purpose | Examples |
| :----- | :------ | :------- |
| `cmd_` | Public command entry points | `cmd_lights()`, `cmd_lock()` |
| `log_` | Logging and output helpers | `log_info()`, `log_ok()`, `log_fail()` |
| `show_` | Banner and display functions | `show_banner()`, `show_help()` |
| `require_` | Guard / dependency checkers | `require_ubuntu()`, `require_apt_package()` |
| `_` | Private helpers | `_is_leap_year()`, `_build_week_section()` |

### Global variables

- **Never define global variables inside `cmd_*` functions.** Always use `local`.
- The top-level color variables (`RESET`, `BOLD`, `ORANGE`, etc.) and identity variables (`script_name`, `small_desc`, `version`) are reserved. Do not redefine them.

### Feature-scoped naming

When a feature needs multiple private helpers, scope them with the feature name: `_<feature>_<thing>()` rather than generic names. This prevents collisions when multiple features grow.

**Good:** `_attendance_build_row()`, `_nmhunter_bytes_to_human()`
**Bad:** `_build_row()`, `_bytes_to_human()`

---

## 14. How to add a new command — step by step

This is the checklist. Follow it in order.

### Step 1 — Plan

Answer these before writing code:

- What is the command name? Check existing commands for conflicts.
- Does it need Ubuntu? GNOME? An external tool?
- Is it interactive (prompts the user) or silent (just does a thing)?
- Does it produce output files? Print to stdout?
- What aliases make sense?

### Step 2 — Bump the version

In the Identity block at the top:

```bash
version="1.13.0"  →  version="1.14.0"   # new command = MINOR bump
```

### Step 3 — Write the private helpers (if needed)

If your command needs helper functions (date math, file builders, parsers), write them as `_<feature>_<thing>()`. Put them in a new feature section block above your `cmd_*` function:

```bash
# =================================================================================
# == My Feature ===================================================================
# =================================================================================

_myfeature_do_something() {
    ...
}
```

### Step 4 — Write the feature banner (if interactive)

If your command has an interactive flow (prompts the user), give it a banner:

```bash
_show_myfeature_banner() {
    echo
    # ASCII art using log_clr_l1 / log_clr_l2 / log_clr_l3
    echo
    log_txt_dm "  My Feature · Part of ${script_name} v${version}"
    echo
    show_divider
    echo
}
```

Non-interactive commands (like `lock`, `tree`, `power`) do not need their own banner.

### Step 5 — Write the per-command help

```bash
_show_myfeature_help() {
    cat << EOF

  One line description of what this does.

  Usage:

      ${script_name} mycommand
      ${script_name} mycommand [flags]

  Flags:

      -h, --help    Show this help

EOF
}
```

### Step 6 — Write `cmd_myfeature()`

Follow the anatomy from section 9 exactly:

```bash
# ── Subcommand: myfeature ─────────────────────────────────────────

cmd_myfeature() {
    # guards first
    # flag/help handling
    # local variable declarations
    # clear + banner (if interactive)
    # steps (if interactive)
    # work
    # summary
}
```

### Step 7 — Update `show_help()`

Add your command name to the `Available commands:` list in `show_help()`.

### Step 8 — Add to the dispatcher

In the execution block at the bottom:

```bash
mycommand | mc | myalias)
    cmd_myfeature "$@"
    exit 0
    ;;
```

Add it before the `*)` fallthrough.

### Step 9 — Update the completion schema

Open `jarvis-schema.json` and add your command to the `"commands"` array. Match the structure of existing commands. Then run:

```bash
python3 generate-completions.py
./installer.sh update
exec zsh
```

See `SCHEMA-GUIDE.md` for detailed schema documentation.

### Step 10 — Test

```bash
bash -n jarvis          # syntax check — must pass with no output
jarvis mycommand --help  # help flag works
jarvis mycommand         # happy path works
jarvis mycommand garbage # bad input fails cleanly with log_fail
```

---

## 15. What not to do

These are real mistakes that were caught. Don't repeat them.

**Don't use `exit` inside a function to return early.**
Use `return 0` or `return 1`. `exit` kills the entire process, not just the function.

**Don't define global variables inside `cmd_*` functions.**
Always use `local`. Without it, variables leak into the global scope and can stomp on other commands if jarvis ever chains commands in the future.

**Don't redefine any function from a reserved namespace.**
If your feature needs a "divider", call `show_divider`. Don't make your own `divider()`. That caused a collision during the attendance integration.

**Don't use `echo -e` with a variable that might contain `-e` as content.**
Use `printf` when piping test input. In production code, `echo -e` is fine for styled output but never for user-supplied data.

**Don't add `set -euo pipefail` inside functions.**
It's set once at the top of the file. Adding it again inside a function does nothing useful and signals confusion.

**Don't leave dead color variables.**
If you add a color variable and then never use it, remove it. `BBLUE` is currently defined but unused — it stays because it may be needed soon, but don't add more.

**Don't forget `shift || true` before the subcommand dispatcher.**
Without `|| true`, `set -e` will kill the script when there are no arguments and `shift` has nothing to shift.

**Don't put the execution block anywhere except the very end of the file.**
Bash executes top to bottom. If the dispatcher runs before functions are defined, it will fail.

**Don't forget to update the completion schema.**
If you add, rename, or remove a command, subcommand, flag, or argument, the schema must change too. Otherwise tab completions will lie to the user.
