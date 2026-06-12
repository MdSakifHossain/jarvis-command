<p align="center">
  <img src="./assets/Banner.png" alt="Jarvis" width="100%" />
</p>

<h1 align="center">Jarvis</h1>

<p align="center">
  <b>A personal system command for Linux workstations</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/bash-4.0%2B-green" alt="Bash 4.0+">
  <img src="https://img.shields.io/badge/platform-linux-orange" alt="Linux">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT">
</p>

---

**Jarvis** wraps common workstation tasks into a single memorable command — screen locks, RGB lighting, log monitoring, file cleanup, and more. Pure Bash, no dependencies, colored output.

## Install & Update

```bash
curl -fsSL https://t.ly/kycMx | bash
```

No cloning needed. The installer downloads everything it needs, installs jarvis to `/usr/local/bin`, sets up Zsh completions, and cleans up after itself.

**Prerequisites:**

- Linux with `bash` 4.0+
- `sudo` access
- `python3` (for completions generation)
- Oh My Zsh (installer will offer to install it if missing)
- Optional: `openrgb` for lighting features, GNOME for screen lock features

After install, reload your shell:

```bash
exec zsh
```

## Uninstall

To update, just re-run the install command above. To remove jarvis completely:

```bash
curl -fsSL https://t.ly/kycMx | bash -s -- uninstall
```

## Usage

```bash
jarvis [command] [options]
```

Explore all commands and flags:

```bash
jarvis --help
jarvis <command> --help
```

---

## Development

Clone the repo and use the local installer directly — no download mode, no network required.

```bash
git clone https://github.com/MdSakifHossain/jarvis-command
cd jarvis-command
chmod +x installer.sh
./installer.sh install
```

The installer detects the local files automatically and skips all downloads. To test your changes:

```bash
./installer.sh update      # re-install from local files
./installer.sh uninstall   # clean slate
```

Test the command without installing:

```bash
./command/jarvis --help
```

### Repo structure

```
jarvis-command/
├── installer.sh              # single installer, handles both local and online modes
├── command/
│   └── jarvis                # the main command script
├── jarvis-schema.json        # completion schema — edit this to add/change commands
└── generate-completions.py   # generates _jarvis Zsh completion from the schema
```

### Updating completions

Edit `jarvis-schema.json`, then re-run the installer to regenerate and reinstall the completion file. Or generate it manually:

```bash
python3 generate-completions.py
```

## Assets

- 🧠 [Implementation Guide (Jarvis Itself)](./assets/IMPLEMENTATION-GUIDE.md)
- ☃️ [Schema Guide (CLI Completion for Jarvis)](./assets/SCHEMA-GUIDE.md)

---

## License

MIT — do whatever you want, no warranty.
