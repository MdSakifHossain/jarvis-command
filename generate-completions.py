#!/usr/bin/env python3
"""
generate-completions.py
-----------------------
Reads jarvis-schema.json and generates a Zsh completion file (_jarvis).
Both files are expected to be in the same directory as this script.

Usage:
    python3 generate-completions.py                        # standalone: reads/writes next to this script
    python3 generate-completions.py <schema> <output>      # explicit paths (used by installer)

Output:
    _jarvis  (written next to this script, or to <output> if specified)

Requirements:
    Python 3.6+  ·  No external dependencies
"""

import json
import sys
import os
from datetime import datetime, timezone

# ── Path resolution ────────────────────────────────────────────────────────────
# Accepts optional CLI args for installer use:
#   python3 generate-completions.py [schema_path] [output_path]
# Falls back to sibling-file defaults when run standalone.
SCRIPT_DIR  = os.path.dirname(os.path.realpath(__file__))
SCHEMA_FILE = sys.argv[1] if len(sys.argv) > 1 else os.path.join(SCRIPT_DIR, "jarvis-schema.json")
OUTPUT_FILE = sys.argv[2] if len(sys.argv) > 2 else os.path.join(SCRIPT_DIR, "_jarvis")


# ── Helpers ────────────────────────────────────────────────────────────────────

def load_schema(path):
    if not os.path.isfile(path):
        print("  [ERROR] Schema file not found: " + path, file=sys.stderr)
        print("        Make sure jarvis-schema.json is in the same directory as this script.", file=sys.stderr)
        sys.exit(1)
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return json.load(fh)
    except json.JSONDecodeError as exc:
        print("  [ERROR] Failed to parse {}: {}".format(path, exc), file=sys.stderr)
        sys.exit(1)


def zq(s):
    """Escape single quotes for use inside Zsh single-quoted strings."""
    return s.replace("'", "'\\''")


def func_name(parts):
    """Turn a list of command parts into a valid Zsh function name."""
    return "_jarvis_" + "_".join(p.replace("-", "_") for p in parts)


# ── Argument / flag completion block ──────────────────────────────────────────

def emit_args_flags(args, flags, lines, ind="    "):
    """Append completion lines for a leaf command with args and/or flags."""

    if flags:
        specs = []
        for f in flags:
            specs.append("'{flag}[{desc}]'".format(flag=zq(f["flag"]), desc=zq(f["description"])))
        lines.append(ind + "local -a _flags")
        lines.append(ind + "_flags=(")
        for s in specs:
            lines.append(ind + "    " + s)
        lines.append(ind + ")")
        lines.append("")

    if args:
        lines.append(ind + "local arg_pos=$(( CURRENT - 1 ))")
        lines.append("")
        lines.append(ind + "case $arg_pos in")
        for i, arg in enumerate(args, start=1):
            atype       = arg.get("type", "string")
            suggestions = arg.get("suggestions", [])
            desc        = zq(arg.get("description", arg["name"]))
            lines.append(ind + "    {})".format(i))
            if suggestions:
                svals = " ".join("'{}'".format(zq(s)) for s in suggestions)
                lines.append(ind + "        _values '{}' {}".format(desc, svals))
            elif atype == "path":
                lines.append(ind + "        _files -/")
            elif atype == "number":
                lines.append(ind + "        # numeric — no file completion")
                lines.append(ind + "        return 0")
            else:
                lines.append(ind + "        _message '{}'".format(desc))
            lines.append(ind + "        ;;")
        lines.append(ind + "    *)")
        if flags:
            lines.append(ind + "        _arguments $_flags")
        else:
            lines.append(ind + "        return 0")
        lines.append(ind + "        ;;")
        lines.append(ind + "esac")
    elif flags:
        lines.append(ind + "_arguments $_flags")

    lines.append("")


# ── Recursive function generator ──────────────────────────────────────────────

def gen_func(node, path, bucket):
    """
    Generate a Zsh completion function for node and append it to bucket.
    path  = list of name segments, e.g. ['bkash', 'cashout']
    """
    fname       = func_name(path)
    subcommands = node.get("subcommands", [])
    flags       = node.get("flags", [])
    args        = node.get("arguments", [])
    label       = path[-1]

    lines = []
    lines.append("{}() {{".format(fname))

    if subcommands:
        lines.append("    local -a _subcmds")
        lines.append("    _subcmds=(")
        for sc in subcommands:
            lines.append("        '{n}:{d}'".format(n=zq(sc["name"]), d=zq(sc["description"])))
        lines.append("    )")
        lines.append("")
        lines.append("    if (( CURRENT == 2 )); then")
        lines.append("        _describe '{} commands' _subcmds".format(label))
        lines.append("        return")
        lines.append("    fi")
        lines.append("")
        lines.append("    case $words[2] in")
        for sc in subcommands:
            child_path  = path + [sc["name"]]
            child_fname = func_name(child_path)
            lines.append("        {})".format(sc["name"]))
            lines.append("            (( CURRENT-- ))")
            lines.append("            shift words")
            lines.append("            {}".format(child_fname))
            lines.append("            ;;")
            # Recurse
            gen_func(sc, child_path, bucket)
        lines.append("    esac")

    elif args or flags:
        emit_args_flags(args, flags, lines)

    lines.append("}")
    lines.append("")
    bucket.append("\n".join(lines))


# ── Top-level file generator ───────────────────────────────────────────────────

def generate(schema):
    """Return the full content of the _jarvis completion file as a string."""
    tool        = schema["name"]
    description = schema.get("description", "CLI tool")
    commands    = schema.get("commands", [])
    gflags      = schema.get("global_flags", [])
    timestamp   = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    # Generate all sub-functions
    bucket = []
    for cmd in commands:
        if cmd.get("subcommands") or cmd.get("arguments") or cmd.get("flags"):
            gen_func(cmd, [cmd["name"]], bucket)

    # Build top-level command list
    cmd_specs = []
    for cmd in commands:
        cmd_specs.append("    '{n}:{d}'".format(n=zq(cmd["name"]), d=zq(cmd["description"])))

    # Build global flag list
    gflag_specs = []
    for gf in gflags:
        gflag_specs.append("    '{f}[{d}]'".format(f=zq(gf["flag"]), d=zq(gf["description"])))

    # Build top-level case dispatch
    top_cases = []
    for cmd in commands:
        if cmd.get("subcommands") or cmd.get("arguments") or cmd.get("flags"):
            fn = func_name([cmd["name"]])
            top_cases.append("        {})".format(cmd["name"]))
            top_cases.append("            (( CURRENT-- ))")
            top_cases.append("            shift words")
            top_cases.append("            {}".format(fn))
            top_cases.append("            ;;")

    # ── Assemble ───────────────────────────────────────────────────────────────
    out = []
    out.append("#compdef " + tool)
    out.append("# " + "=" * 77)
    out.append("#  _jarvis — Zsh completion for " + tool)
    out.append("#  Auto-generated by generate-completions.py on " + timestamp)
    out.append("#  DO NOT EDIT BY HAND — edit jarvis-schema.json and re-run the generator.")
    out.append("# " + "=" * 77)
    out.append("")

    for fn_body in bucket:
        out.append(fn_body)

    out.append("_{}() {{".format(tool))
    out.append("    local context state state_descr line")
    out.append("    typeset -A opt_args")
    out.append("")
    out.append("    local -a _commands")
    out.append("    _commands=(")
    out.extend(cmd_specs)
    out.append("    )")
    out.append("")

    if gflag_specs:
        out.append("    local -a _gflags")
        out.append("    _gflags=(")
        out.extend(gflag_specs)
        out.append("    )")
        out.append("")

    out.append("    if (( CURRENT == 2 )); then")
    if gflag_specs:
        out.append("        _arguments $_gflags")
    out.append("        _describe '{}' _commands".format(description))
    out.append("        return")
    out.append("    fi")
    out.append("")

    if top_cases:
        out.append("    case $words[2] in")
        out.extend(top_cases)
        out.append("    esac")

    out.append("}")
    out.append("")
    out.append("_{} \"$@\"".format(tool))
    out.append("")

    return "\n".join(out)


# ── Entry point ────────────────────────────────────────────────────────────────

def main():
    print("  [INFO] Reading schema  : " + SCHEMA_FILE)
    schema = load_schema(SCHEMA_FILE)

    print("  [INFO] Generating      : " + OUTPUT_FILE)
    content = generate(schema)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as fh:
        fh.write(content)

    print("  [OK]   Written         : " + OUTPUT_FILE)
    print("  [OK]   Done.")


if __name__ == "__main__":
    main()
