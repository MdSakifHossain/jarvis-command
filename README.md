# Jarvis-Command

A flexible installer for turning any script into a system-wide command.

---

## Features

- Install **`command/jarvis`** as a global command

```shell
jarvis - Personal CLI Tool

Usage:

    jarvis [command]
    jarvis [flags]

Available commands:

    lights, lock, unlock, observe, monitor,
    version, help

Flags:

    -v, --version   Show Version Info
    -h, --help      Show Help

For more info, Run:

    jarvis <command> --help


```

---

## Project Structure (Recommended)

```bash
.
├── command     # This folder should only have one command file
│   └── jarvis  # This file will be Installed
├── install.sh
├── README.md
└── uninstall.sh

2 directories, 4 files
```

---

## Installation

### 1. Make scripts executable

```bash
chmod +x install.sh uninstall.sh
```

### Install (Interactive mode)

```bash
./install.sh
```

or

### Install (Direct mode)

```bash
./install.sh command/jarvis
```

---

## Updating

Modify your script, then run:

```bash
./install.sh
```

or

```bash
./install.sh command/jarvis
```

---

## Uninstallation

### Uninstall (Interactive mode)

```bash
./uninstall.sh
```

### Uninstall (Direct mode)

```bash
./uninstall.sh command/jarvis
```

---

## Important Notes

- Requires `sudo` (writes to `/usr/local/bin`)
- If a directory is provided:
  - Only the **first file** is used
  - File selection order may vary
- Keep only **one file inside `command/`** for predictable behavior
- Use meaningful filenames
- Test locally before installing:

```bash
./command/jarvis
```

---

## Compatibility

- Linux distributions
- Shells: `bash`, `zsh`
