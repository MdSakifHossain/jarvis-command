<p align="center">
  <img src="./Banner.png" alt="Jarvis" width="100%" />
</p>

<h1 align="center">Jarvis</h1>

<p align="center">
  <b>A personal system command for Linux workstations</b><br>****
  <a href="#installation">Install</a> · <a href="#usage">Usage</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/bash-4.0%2B-green" alt="Bash 4.0+">
  <img src="https://img.shields.io/badge/platform-linux-orange" alt="Linux">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT">
</p>

## Overview

**Jarvis** is a single-file personal CLI utility for Ubuntu. It wraps common workstation tasks — screen control, RGB lighting, log monitoring, file cleanup, and more — into one memorable command with colored output and responsive ASCII banners.

Built as a learning project for custom system command structure, installation, and distribution.

## Installation

### Prerequisites

- Ubuntu with `bash` 4.0+
- `sudo` access (for `/usr/local/bin`)
- Optional: `openrgb` for lighting, GNOME for screen lock features

### Quick Install

```bash
git clone https://github.com/MdSakifHossain/jarvis-command
cd jarvis-command
chmod +x installer.sh
./installer.sh install
```

### Update / Uninstall

```bash
./installer.sh update      # Re-install after changes
./installer.sh uninstall   # Remove completely
```

After install or update, reload your shell:

```bash
exec zsh
```

## Usage

```bash
jarvis [command] [options]
```

Discover all commands and flags:

```bash
jarvis --help
jarvis <command> --help
```

## Important Notes

- The installer writes to `/usr/local/bin` and requires `sudo`
- The `command/` directory should contain **one file** for predictable behavior
- Test locally before installing: `./command/jarvis --help`

## Compatibility

- **OS:** Linux distributions
- **Shell:** `bash`, `zsh`
- **Desktop:** GNOME (for screen lock/unlock features)

## License

MIT — do whatever you want, no warranty.
