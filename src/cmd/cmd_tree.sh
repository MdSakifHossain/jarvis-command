# ── Subcommand: tree ─────────────────────────────────────────────────────────
cmd_tree() {
    require_apt_package "tree"
    tree --gitignore --dirsfirst
}
