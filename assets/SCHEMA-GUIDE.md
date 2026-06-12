# jarvis-schema.json — Complete Guide

How to read, edit, and extend the completion schema.  
After every change, re-run `python3 generate-completions.py` and then `./installer.sh update` to apply.

---

## File Layout

```
your-folder/
├── command/
│   └── jarvis                  ← the main script
├── jarvis-schema.json          ← you edit this
├── generate-completions.py     ← reads the schema, writes _jarvis
├── _jarvis                     ← auto-generated, do not edit by hand
└── installer.sh                ← installs everything
```

---

## Top-Level Structure

```json
{
  "_comment": "Human note — ignored by the generator",
  "_version": "1.0.0",

  "name": "jarvis",
  "description": "Personal CLI Tool",

  "global_flags": [ ... ],
  "commands":     [ ... ]
}
```

| Key | Required | What it does |
|---|---|---|
| `name` | ✅ | Must match the actual command name |
| `description` | ✅ | Shown in the top-level completion menu |
| `global_flags` | optional | Flags that work everywhere (e.g. `--help`) |
| `commands` | ✅ | List of all top-level commands |

---

## Scenario 1 — Simple command with no arguments

Use when the command just runs with no options (like `jarvis unlock`).

```json
{
  "name": "unlock",
  "description": "Unlock the screen"
}
```

Tab behaviour: `jarvis unlock [TAB]` → nothing (correct).

---

## Scenario 2 — Command with subcommands (one level deep)

Use when a command has a fixed set of sub-actions (like `jarvis lights on/off`).

```json
{
  "name": "lights",
  "description": "Control RAM LED lighting",
  "subcommands": [
    { "name": "on",   "description": "Turn RAM LED on (white)" },
    { "name": "off",  "description": "Turn RAM LED off" }
  ]
}
```

Tab behaviour:
- `jarvis lights [TAB]` → shows `on`, `off`
- `jarvis lights on [TAB]` → nothing (leaf command)

---

## Scenario 3 — Command with subcommands (two levels deep)

Use when a subcommand itself has further sub-actions (like `jarvis bkash cashout from/for`).

```json
{
  "name": "bkash",
  "description": "bKash calculator",
  "subcommands": [
    {
      "name": "cashout",
      "description": "Cash out calculator",
      "subcommands": [
        { "name": "from", "description": "You have X — how much do you receive?" },
        { "name": "for",  "description": "You want X in hand — what balance do you need?" }
      ]
    }
  ]
}
```

Tab behaviour:
- `jarvis bkash [TAB]` → shows `cashout`
- `jarvis bkash cashout [TAB]` → shows `from`, `for`

You can nest as deep as you need. There is no hard limit.

---

## Scenario 4 — Command with flags

Use when a command accepts `--flags` (like `jarvis nmhunter --dry-run`).

```json
{
  "name": "nmhunter",
  "description": "Hunt and delete node_modules",
  "flags": [
    { "flag": "--dry-run", "description": "Preview without deleting" },
    { "flag": "-y",        "description": "Skip confirmation" },
    { "flag": "--yes",     "description": "Skip confirmation" },
    { "flag": "-h",        "description": "Show help" },
    { "flag": "--help",    "description": "Show help" }
  ]
}
```

Tab behaviour: `jarvis nmhunter --[TAB]` → shows all `--` flags with descriptions.

---

## Scenario 5 — Command with a path argument

Use when a command expects a file or directory path as input.

```json
{
  "name": "nmhunter",
  "description": "Hunt and delete node_modules",
  "arguments": [
    {
      "name": "directory",
      "description": "Directory to scan",
      "type": "path",
      "optional": true
    }
  ]
}
```

Tab behaviour: `jarvis nmhunter ~/[TAB]` → filesystem completion (directories only).

---

## Scenario 6 — Command with a numeric argument and suggestions

Use when a command takes a number but you want to hint common values (like `jarvis lock 5`).

```json
{
  "name": "lock",
  "description": "Lock the screen with optional delay",
  "arguments": [
    {
      "name": "delay",
      "description": "Minutes before locking",
      "type": "number",
      "optional": true,
      "suggestions": ["1", "2", "5", "10", "15", "30", "45", "60"]
    }
  ]
}
```

Tab behaviour: `jarvis lock [TAB]` → shows `1 2 5 10 15 30 45 60`.

---

## Scenario 7 — Command with both flags AND a path argument

Flags and arguments can be combined. The generator handles them together.

```json
{
  "name": "nmhunter",
  "description": "Hunt and delete node_modules",
  "arguments": [
    {
      "name": "directory",
      "description": "Directory to scan",
      "type": "path",
      "optional": true
    }
  ],
  "flags": [
    { "flag": "--dry-run", "description": "Preview without deleting" },
    { "flag": "-y",        "description": "Skip confirmation" }
  ]
}
```

Tab behaviour:
- `jarvis nmhunter [TAB]` → directory completion
- `jarvis nmhunter ~/work --[TAB]` → flag completion

---

## Scenario 8 — Subcommand with its own arguments and rate suggestions

Use when a deep subcommand itself takes positional arguments.

```json
{
  "name": "cashout",
  "description": "Cash out calculator",
  "subcommands": [
    {
      "name": "from",
      "description": "You have X — how much do you receive?",
      "arguments": [
        {
          "name": "amount",
          "description": "Your wallet balance in BDT",
          "type": "number",
          "optional": false
        },
        {
          "name": "rate",
          "description": "Charge rate per 1000 BDT",
          "type": "number",
          "optional": true,
          "suggestions": ["14.9", "18.5", "20.0"]
        }
      ]
    }
  ]
}
```

Tab behaviour:
- `jarvis bkash cashout from [TAB]` → nothing (numeric arg, no hints)
- `jarvis bkash cashout from 1000 [TAB]` → shows `14.9 18.5 20.0`

---

## Argument `type` Reference

| `type` value | Tab behaviour |
|---|---|
| `"number"` | No completion (numbers are free-form) |
| `"path"` | Directory browser (`~/`, `/etc/` etc.) |
| `"string"` | Shows `_message` hint in the prompt |

If `suggestions` is set, it always overrides the type behaviour and shows the list instead.

---

## All Argument Fields

```json
{
  "name":        "delay",       // internal name (not shown to user)
  "description": "Minutes...",  // shown as hint in the completion menu
  "type":        "number",      // number | path | string
  "optional":    true,          // true/false — doesn't affect tab behaviour yet, for docs only
  "suggestions": ["1", "5"]     // if set, shown as selectable values
}
```

---

## All Flag Fields

```json
{
  "flag":        "--dry-run",              // the actual flag string
  "description": "Preview without deleting"  // shown next to the flag
}
```

---

## Adding a Brand New Top-Level Command

1. Open `jarvis-schema.json`
2. Add an entry to the `"commands"` array
3. Pick the right scenario above and match its structure
4. Run:

```bash
python3 generate-completions.py
./installer.sh update
exec zsh
```

### Example — adding a new `backup` command

```json
{
  "name": "backup",
  "description": "Back up home directory to external drive",
  "arguments": [
    {
      "name": "destination",
      "description": "Target directory for the backup",
      "type": "path",
      "optional": false
    }
  ],
  "flags": [
    { "flag": "--dry-run", "description": "Show what would be copied" },
    { "flag": "-v",        "description": "Verbose output" }
  ]
}
```

---

## Workflow Summary

```
Edit jarvis-schema.json
        ↓
python3 generate-completions.py   ← writes _jarvis
        ↓
./installer.sh update             ← copies jarvis + _jarvis to correct dirs
        ↓
exec zsh                          ← reloads shell, completions live
```

---

## Things That Do NOT Need a Schema Change

- Editing the logic inside the `jarvis` script (the actual commands)
- Changing colors, banners, or output formatting
- Adding aliases (they are intentionally hidden from completions)

You only need to update the schema when you **add, rename, or remove a command, subcommand, flag, or argument**.
