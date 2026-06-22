# ── Helpers ───────────────────────────────────────────────────────────────────
require_apt_package() {
    local cmd="$1"
    local pkg="${2:-$1}"

    if command -v "$cmd" > /dev/null 2>&1; then
        return 0
    fi

    echo
    log_fail "Missing dependency: $cmd

Install it using:
    sudo apt install $pkg"
}

require_external_dependency() {
    local cmd="$1"
    local message="${2:-No installation instructions provided}"

    if command -v "$cmd" > /dev/null 2>&1; then
        return 0
    fi

    echo
    log_fail "Missing dependency: $cmd

Hint:
$message"
}

require_openrgb() {
    require_external_dependency openrgb "Go to https://openrgb.org/releases.html and instll the 'Linux amd64 (Debian Bookworm .deb)'"
}

require_dbus() {
    require_apt_package dbus-send dbus-x11
}

require_gnome_screensaver() {
    dbus-send --session \
        --dest=org.gnome.ScreenSaver \
        --print-reply \
        /org/gnome/ScreenSaver \
        org.gnome.ScreenSaver.GetActive \
        > /dev/null 2>&1 \
        || log_fail "Screen lock is not available (GNOME desktop not detected).\n\nTry running this command inside your normal Ubuntu desktop session."
}

require_gnome_lock() {
    require_dbus
    require_gnome_screensaver
}
