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
curl -fsSL https://tr.ee/s7OmWT | bash
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
curl -fsSL https://tr.ee/s7OmWT | bash -s -- uninstall
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

Clone the repo:

```bash
git clone https://github.com/MdSakifHossain/jarvis-command
cd jarvis-command
chmod +x installer.sh build dev
```

### Repo structure

```
jarvis-command/
├── src/
│   ├── core/
│   │   ├── header.sh          # identity: script_name, version, small_desc
│   │   ├── globals.sh         # color variables
│   │   ├── helpers.sh         # logging, UI helpers, guards, banner, show_help
│   │   └── main.sh            # dispatcher — the case statement
│   └── cmd/
│       ├── cmd_lights.sh
│       ├── cmd_lock.sh
│       ├── cmd_attendance.sh
│       └── ...                # one file per command
│
├── command/
│   └── jarvis                 # built output — do not edit directly
│
├── build                      # concatenates src/ → command/jarvis
├── dev                        # runs directly from src/ (no build step)
├── installer.sh               # installs command/jarvis to the system
├── jarvis-schema.json         # completion schema — edit when adding commands
└── generate-completions.py    # generates _jarvis Zsh completion from the schema
```

### The two scripts you'll use every day

**`./dev`** — run jarvis directly from source, no build needed:

```bash
./dev --help
./dev lights on
./dev bkash cashout from 1000
```

Use this while you're working on a feature. Changes in `src/` are reflected immediately.

**`./build`** — produce the distributable before committing:

```bash
./build
```

Concatenates all `src/` files into `command/jarvis`. Run this once when you're done with a feature and ready to push. The built `command/jarvis` is committed to git so the online installer can download it.

### Adding a new command

The short version — full details in [`assets/IMPLEMENTATION-GUIDE.md`](./assets/IMPLEMENTATION-GUIDE.md):

1. Bump the version in `src/core/header.sh`
2. Create `src/cmd/cmd_myfeature.sh` with your helpers + `cmd_myfeature()` function
3. Add the command to `show_help()` in `src/core/helpers.sh`
4. Add a `case` entry to the dispatcher in `src/core/main.sh`
5. Add the command to `jarvis-schema.json` and run `python3 generate-completions.py`
6. Test with `./dev mycommand --help`
7. Run `./build`, then `./installer.sh update`

### Testing without installing

```bash
./dev mycommand --help        # run from source (fastest during dev)
./command/jarvis mycommand    # run the built file
```

### Updating completions

Edit `jarvis-schema.json`, regenerate, then reinstall:

```bash
python3 generate-completions.py
./installer.sh update
exec zsh
```

---

## Assets

- 🧠 [Implementation Guide](./assets/IMPLEMENTATION-GUIDE.md)
- 🌬️ [Schema Guide (CLI Completions)](./assets/SCHEMA-GUIDE.md)

---

## License

MIT — do whatever you want, no warranty.
