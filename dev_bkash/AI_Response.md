## 📁 File Structure

First, create this structure in your project directory:

```txt
~/my-cli-tools/
├── jarvis                   # Your main script (renamed from jarvis.sh)
├── .jarvis-schema.json      # The configuration file you'll edit
├── generate-completions.py  # The generator script
└── README.md                # Instructions
```

## Step 1: Create the JSON Schema

Save this as `.jarvis-schema.json` in the same directory as your script:

```json
{
  "name": "jarvis",
  "version": "1.13.0",
  "description": "Personal CLI Tool",
  "commands": {
    "lights": {
      "aliases": ["light", "ram", "rams", "led", "leds", "lt", "lts"],
      "description": "Control RAM LED color",
      "subcommands": {
        "on": {
          "aliases": ["1"],
          "description": "Turn RAM LED on",
          "args": []
        },
        "off": {
          "aliases": ["0"],
          "description": "Turn RAM LED off",
          "args": []
        },
        "help": {
          "aliases": [],
          "description": "Show lights help",
          "args": []
        }
      }
    },
    "lock": {
      "aliases": [],
      "description": "Lock screen with optional delay",
      "args": [
        {
          "name": "delay",
          "type": "number",
          "description": "Delay in minutes",
          "optional": true,
          "suggestions": ["1", "2", "3", "4", "5", "10", "15", "30", "45", "60"]
        }
      ]
    },
    "unlock": {
      "aliases": [],
      "description": "Unlock screen",
      "args": []
    },
    "observe": {
      "aliases": ["monitor"],
      "description": "Monitor vault observer log",
      "args": []
    },
    "tree": {
      "aliases": ["list", "lst", "ls"],
      "description": "Show directory tree (git-aware)",
      "args": []
    },
    "power": {
      "aliases": ["poweroff", "pwr", "shutdown"],
      "description": "System shutdown",
      "args": []
    },
    "attendance": {
      "aliases": ["attend", "att"],
      "description": "Generate attendance sheet",
      "flags": {
        "-h": {
          "aliases": ["--help"],
          "description": "Show help"
        }
      }
    },
    "nmhunter": {
      "aliases": ["nmhunt", "nm", "hunt", "hunter"],
      "description": "Hunt and delete node_modules directories",
      "flags": {
        "--dry-run": {
          "aliases": [],
          "description": "Preview only, no deletion"
        },
        "-y": {
          "aliases": ["--yes"],
          "description": "Skip confirmation prompt"
        },
        "-h": {
          "aliases": ["--help"],
          "description": "Show help"
        }
      },
      "args": [
        {
          "name": "directory",
          "type": "path",
          "description": "Directory to scan",
          "optional": true,
          "default": "~/projects"
        }
      ]
    },
    "bkash": {
      "aliases": ["bk"],
      "description": "bKash MFS calculator",
      "subcommands": {
        "cashout": {
          "description": "Calculate cash out",
          "subcommands": {
            "from": {
              "description": "From balance (I have X)",
              "args": [
                {
                  "name": "amount",
                  "type": "number",
                  "description": "Amount in BDT",
                  "optional": false
                },
                {
                  "name": "rate",
                  "type": "number",
                  "description": "Charge rate per 1000 BDT",
                  "optional": true,
                  "default": "18.5",
                  "suggestions": [
                    "14.5",
                    "15.0",
                    "16.0",
                    "17.0",
                    "18.0",
                    "18.5",
                    "19.0",
                    "20.0"
                  ]
                }
              ]
            },
            "for": {
              "description": "For target amount (I want X)",
              "args": [
                {
                  "name": "amount",
                  "type": "number",
                  "description": "Amount in BDT",
                  "optional": false
                },
                {
                  "name": "rate",
                  "type": "number",
                  "description": "Charge rate per 1000 BDT",
                  "optional": true,
                  "default": "18.5",
                  "suggestions": [
                    "14.5",
                    "15.0",
                    "16.0",
                    "17.0",
                    "18.0",
                    "18.5",
                    "19.0",
                    "20.0"
                  ]
                }
              ]
            }
          }
        },
        "sendmoney": {
          "aliases": ["cashin"],
          "description": "Calculate send money",
          "args": [
            {
              "name": "amount",
              "type": "number",
              "description": "Amount in BDT",
              "optional": false
            },
            {
              "name": "rate",
              "type": "number",
              "description": "Charge rate per 1000 BDT",
              "optional": true,
              "default": "18.5",
              "suggestions": [
                "14.5",
                "15.0",
                "16.0",
                "17.0",
                "18.0",
                "18.5",
                "19.0",
                "20.0"
              ]
            }
          ]
        }
      }
    },
    "version": {
      "aliases": [],
      "description": "Show version info",
      "args": []
    },
    "help": {
      "aliases": ["h"],
      "description": "Show help",
      "args": []
    }
  },
  "global_flags": {
    "-h": {
      "aliases": ["--help"],
      "description": "Show help"
    },
    "-v": {
      "aliases": ["--version"],
      "description": "Show version"
    }
  }
}
```

## Step 2: Create the Python Generator Script

Save this as `generate-completions.py`:

```python
#!/usr/bin/env python3
"""
Auto-completion generator for jarvis CLI
Usage: python3 generate-completions.py
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Any

def generate_zsh_completion(schema: Dict[str, Any]) -> str:
    """Generate Zsh completion function from schema"""

    lines = []
    lines.append("#compdef jarvis\n")
    lines.append("# Auto-generated from .jarvis-schema.json - DO NOT EDIT DIRECTLY")
    lines.append(f"# Generated for {schema['name']} v{schema['version']}\n")

    # Main completion function
    lines.append("_jarvis() {\n")
    lines.append("  local curcontext=\"$curcontext\" ret=1\n")
    lines.append("  local -a context line state state_descr\n")
    lines.append("  local cur=\"${words[CURRENT]}\" prev=\"${words[CURRENT-1]}\" cmd=\"${words[2]}\"\n")
    lines.append("  local subcmd=\"${words[3]}\"\n\n")

    # Generate global flags
    global_flags = []
    for flag, data in schema.get('global_flags', {}).items():
        global_flags.append(f"'{flag}[{data['description']}]'")
        for alias in data.get('aliases', []):
            global_flags.append(f"'{alias}[{data['description']}]'")

    if global_flags:
        lines.append(f"  local -a global_flags=({ ' '.join(global_flags) })\n\n")

    # Generate main commands list
    commands = []
    for cmd, data in schema['commands'].items():
        commands.append(f"'{cmd}:{data.get('description', '')}'")
        for alias in data.get('aliases', []):
            commands.append(f"'{alias}:{data.get('description', '')}'")

    lines.append(f"  local -a commands=({ ' '.join(commands) })\n\n")

    # Handle first argument (main command)
    lines.append("  if [[ CURRENT -eq 2 ]]; then\n")
    lines.append("    _alternative \\\n")
    lines.append("      'flags:global flags:global_flags' \\\n")
    lines.append("      'commands:commands:commands'\n")
    lines.append("    return\n")
    lines.append("  fi\n\n")

    # Handle subcommands based on main command
    lines.append("  case \"$cmd\" in\n")

    for cmd, data in schema['commands'].items():
        aliases = "|".join([cmd] + data.get('aliases', []))
        lines.append(f"    {aliases})\n")

        # Check if command has subcommands
        if 'subcommands' in data and data['subcommands']:
            # Generate subcommands list
            subcmds = []
            for sub, subdata in data['subcommands'].items():
                subcmds.append(f"'{sub}:{subdata.get('description', '')}'")
                for alias in subdata.get('aliases', []):
                    subcmds.append(f"'{alias}:{subdata.get('description', '')}'")

            lines.append(f"      local -a subcmds=({ ' '.join(subcmds) })\n")
            lines.append("      \n")
            lines.append("      if [[ CURRENT -eq 3 ]]; then\n")
            lines.append("        _describe -t subcmds 'subcommand' subcmds\n")
            lines.append("        return\n")
            lines.append("      fi\n")
            lines.append("      \n")

            # Handle nested subcommands (like bkash cashout from)
            lines.append("      case \"$subcmd\" in\n")

            for sub, subdata in data['subcommands'].items():
                sub_aliases = "|".join([sub] + subdata.get('aliases', []))
                lines.append(f"        {sub_aliases})\n")

                # Handle further nesting
                if 'subcommands' in subdata and subdata['subcommands']:
                    lines.append(f"          local -a subsubcmds=(")
                    subsubs = []
                    for subsub, subsubdata in subdata['subcommands'].items():
                        subsubs.append(f"'{subsub}:{subsubdata.get('description', '')}'")
                    lines.append(f"{ ' '.join(subsubs) })\n")
                    lines.append("          \n")
                    lines.append("          if [[ CURRENT -eq 4 ]]; then\n")
                    lines.append("            _describe -t subsubcmds 'subcommand' subsubcmds\n")
                    lines.append("            return\n")
                    lines.append("          fi\n")

                    # Handle args for deepest level
                    for subsub, subsubdata in subdata['subcommands'].items():
                        if 'args' in subsubdata and subsubdata['args']:
                            lines.append(f"          if [[ \"${{words[4]}}\" == \"{subsub}\" ]]; then\n")
                            lines.append(f"            _arguments \\\n")
                            for i, arg in enumerate(subsubdata['args'], 1):
                                if arg.get('suggestions'):
                                    suggestions = ' '.join([f'"{s}"' for s in arg['suggestions']])
                                    lines.append(f"              '{i}:{arg['description']}:({suggestions})' \\\n")
                                elif arg['type'] == 'path':
                                    lines.append(f"              '{i}:{arg['description']}:_files -/'\n")
                                else:
                                    lines.append(f"              '{i}:{arg['description']}:'\n")
                            lines.append("            return\n")
                            lines.append("          fi\n")
                    lines.append("          ;;\n")

                # Handle args for this level
                elif 'args' in subdata and subdata['args']:
                    lines.append(f"          _arguments \\\n")
                    for i, arg in enumerate(subdata['args'], 1):
                        if arg.get('suggestions'):
                            suggestions = ' '.join([f'"{s}"' for s in arg['suggestions']])
                            lines.append(f"            '{i}:{arg['description']}:({suggestions})' \\\n")
                        elif arg['type'] == 'path':
                            lines.append(f"            '{i}:{arg['description']}:_files -/'\n")
                        else:
                            lines.append(f"            '{i}:{arg['description']}:'\n")
                    lines.append("          return\n")
                    lines.append("          ;;\n")
                else:
                    lines.append("          ;;\n")

            lines.append("      esac\n")

        # Handle flags for commands
        flags = []
        if 'flags' in data:
            for flag, flagdata in data['flags'].items():
                flags.append(f"'{flag}[{flagdata['description']}]'")
                for alias in flagdata.get('aliases', []):
                    flags.append(f"'{alias}[{flagdata['description']}]'")

        # Handle args for commands
        if 'args' in data and data['args']:
            lines.append(f"      local -a cmd_flags=({ ' '.join(flags) })\n") if flags else None
            lines.append(f"      _arguments \\\n")
            if flags:
                lines.append(f"        $cmd_flags \\\n")
            for i, arg in enumerate(data['args'], 1):
                if arg.get('optional', False):
                    lines.append(f"        '{i}:{arg['description']}:')
                else:
                    lines.append(f"        '{i}:{arg['description']}:')

                if arg.get('suggestions'):
                    suggestions = ' '.join([f'"{s}"' for s in arg['suggestions']])
                    lines.append(f"({suggestions})' \\\n")
                elif arg['type'] == 'path':
                    lines.append(f"_files -/' \\\n")
                else:
                    lines.append(f"' \\\n")
            lines.append("      return\n")

        elif flags:
            lines.append(f"      _arguments -S { ' '.join(flags) }\n")

        lines.append("      ;;\n")

    lines.append("  esac\n")
    lines.append("  return ret\n")
    lines.append("}\n\n")

    # Register completion
    lines.append("compdef _jarvis jarvis\n")

    return ''.join(lines)

def generate_bash_completion(schema: Dict[str, Any]) -> str:
    """Generate Bash completion function from schema"""

    lines = []
    lines.append("# Auto-generated from .jarvis-schema.json - DO NOT EDIT DIRECTLY\n")
    lines.append(f"# Generated for {schema['name']} v{schema['version']}\n")

    # Main completion function
    lines.append("_jarvis_bash_completion() {\n")
    lines.append("    local cur prev words cword cmd subcmd\n")
    lines.append("    COMPREPLY=()\n")
    lines.append("    cur=\"${COMP_WORDS[COMP_CWORD]}\"\n")
    lines.append("    prev=\"${COMP_WORDS[COMP_CWORD-1]}\"\n")
    lines.append("    cmd=\"${COMP_WORDS[1]}\"\n")
    lines.append("    subcmd=\"${COMP_WORDS[2]}\"\n\n")

    # Generate main commands
    commands = []
    for cmd, data in schema['commands'].items():
        commands.append(cmd)
        commands.extend(data.get('aliases', []))

    lines.append(f"    local commands=\"{' '.join(commands)}\"\n")

    # Generate global flags
    flags = []
    for flag, data in schema.get('global_flags', {}).items():
        flags.append(flag)
        flags.extend(data.get('aliases', []))

    lines.append(f"    local global_flags=\"{' '.join(flags)}\"\n\n")

    # Case statement for commands
    lines.append("    case \"$cmd\" in\n")

    for cmd, data in schema['commands'].items():
        aliases = "|".join([cmd] + data.get('aliases', []))
        lines.append(f"        {aliases})\n")

        # Handle subcommands
        if 'subcommands' in data:
            subcmds = []
            for sub, subdata in data['subcommands'].items():
                subcmds.append(sub)
                subcmds.extend(subdata.get('aliases', []))
            lines.append(f"            if [[ COMP_CWORD -eq 2 ]]; then\n")
            lines.append(f"                COMPREPLY=($(compgen -W \"{' '.join(subcmds)}\" -- \"$cur\"))\n")
            lines.append(f"                return 0\n")
            lines.append(f"            fi\n")

            # Handle nested (bkash cashout from)
            lines.append(f"            case \"$subcmd\" in\n")
            for sub, subdata in data['subcommands'].items():
                if 'subcommands' in subdata:
                    sub_aliases = "|".join([sub] + subdata.get('aliases', []))
                    lines.append(f"                {sub_aliases})\n")
                    subsubs = []
                    for subsub in subdata['subcommands'].keys():
                        subsubs.append(subsub)
                    lines.append(f"                    if [[ COMP_CWORD -eq 3 ]]; then\n")
                    lines.append(f"                        COMPREPLY=($(compgen -W \"{' '.join(subsubs)}\" -- \"$cur\"))\n")
                    lines.append(f"                        return 0\n")
                    lines.append(f"                    fi\n")
                    lines.append(f"                    ;;\n")
            lines.append(f"            esac\n")

        # Handle flags
        flags_list = []
        if 'flags' in data:
            for flag in data['flags'].keys():
                flags_list.append(flag)
                flags_list.extend(data['flags'][flag].get('aliases', []))

        if flags_list:
            lines.append(f"            if [[ \"$cur\" == -* ]]; then\n")
            lines.append(f"                COMPREPLY=($(compgen -W \"{' '.join(flags_list)}\" -- \"$cur\"))\n")
            lines.append(f"                return 0\n")
            lines.append(f"            fi\n")

        # Handle args
        if 'args' in data:
            for arg in data['args']:
                if arg.get('suggestions'):
                    lines.append(f"            COMPREPLY=($(compgen -W \"{' '.join(arg['suggestions'])}\" -- \"$cur\"))\n")
                elif arg['type'] == 'path':
                    lines.append(f"            COMPREPLY=($(compgen -d -- \"$cur\"))\n")
                lines.append(f"            return 0\n")

        lines.append(f"            ;;\n")

    # Default case
    lines.append("        *)\n")
    lines.append("            if [[ \"$cur\" == -* ]]; then\n")
    lines.append("                COMPREPLY=($(compgen -W \"$global_flags\" -- \"$cur\"))\n")
    lines.append("            else\n")
    lines.append("                COMPREPLY=($(compgen -W \"$commands\" -- \"$cur\"))\n")
    lines.append("            fi\n")
    lines.append("            ;;\n")
    lines.append("    esac\n")
    lines.append("}\n\n")
    lines.append("complete -F _jarvis_bash_completion jarvis\n")

    return ''.join(lines)

def main():
    """Main generator function"""

    # Find the schema file
    schema_path = Path('.jarvis-schema.json')
    if not schema_path.exists():
        print("❌ Error: .jarvis-schema.json not found in current directory")
        print("   Please create the schema file first.")
        sys.exit(1)

    # Load schema
    try:
        with open(schema_path, 'r') as f:
            schema = json.load(f)
        print(f"✅ Loaded schema for {schema['name']} v{schema['version']}")
    except json.JSONDecodeError as e:
        print(f"❌ Error parsing JSON: {e}")
        sys.exit(1)

    # Generate Zsh completion
    try:
        zsh_content = generate_zsh_completion(schema)
        zsh_path = Path('_jarvis')
        with open(zsh_path, 'w') as f:
            f.write(zsh_content)
        print(f"✅ Generated Zsh completion: {zsh_path}")
    except Exception as e:
        print(f"❌ Error generating Zsh completion: {e}")

    # Generate Bash completion
    try:
        bash_content = generate_bash_completion(schema)
        bash_path = Path('jarvis-completion.bash')
        with open(bash_path, 'w') as f:
            f.write(bash_content)
        print(f"✅ Generated Bash completion: {bash_path}")
    except Exception as e:
        print(f"❌ Error generating Bash completion: {e}")

    print("\n" + "="*50)
    print("✨ Generation complete!")
    print("="*50)

if __name__ == "__main__":
    main()
```

## Step 3: Make Scripts Executable

```bash
# Make the generator executable
chmod +x generate-completions.py

# If your main script isn't executable yet
chmod +x jarvis
```

## Step 4: Complete Installation Guide

Save this as `INSTALL.md`:

````markdown
# Complete Installation Guide for jarvis CLI with Auto-completion

## 📋 Prerequisites

- Zsh or Bash shell
- Python 3.6+ (for generator only)
- Your jarvis script in PATH

## 🚀 Step-by-Step Installation

### Part 1: Set up your jarvis command

1. **Rename and move your script:**

```bash
# Remove .sh extension and make it a proper command
mv jarvis.sh jarvis

# Make it executable
chmod +x jarvis

# Move to a directory in your PATH (choose one)
# Option A: User local bin (recommended)
mkdir -p ~/.local/bin
mv jarvis ~/.local/bin/

# Option B: System bin (needs sudo)
sudo mv jarvis /usr/local/bin/

# Option C: Keep in current directory but add to PATH
export PATH="$PATH:$(pwd)"
# Add above line to ~/.bashrc or ~/.zshrc to make permanent
```

2. **Verify it works:**

```bash
jarvis --version
jarvis help
```

### Part 2: Set up the completion generator

1. **Create a directory for your configs:**

```bash
mkdir -p ~/.config/jarvis
cd ~/.config/jarvis
```

2. **Copy the required files to this directory:**

```bash
# Copy these files from where you created them:
cp ~/path/to/your/.jarvis-schema.json .
cp ~/path/to/your/generate-completions.py .
```

3. **Test the generator:**

```bash
python3 generate-completions.py
```

You should see:

```
✅ Loaded schema for jarvis v1.13.0
✅ Generated Zsh completion: _jarvis
✅ Generated Bash completion: jarvis-completion.bash
```

### Part 3: Install the completion (CHOOSE YOUR SHELL)

#### For Zsh users (recommended, more features):

1. **Create completions directory if it doesn't exist:**

```bash
mkdir -p ~/.zsh/completions
```

2. **Copy the completion file:**

```bash
cp _jarvis ~/.zsh/completions/
```

3. **Add to ~/.zshrc:**

```bash
echo '# jarvis completion' >> ~/.zshrc
echo 'fpath=(~/.zsh/completions $fpath)' >> ~/.zshrc
echo 'autoload -U compinit && compinit' >> ~/.zshrc
```

4. **Reload your shell:**

```bash
source ~/.zshrc
# OR open a new terminal
```

#### For Bash users:

1. **Copy the completion file:**

```bash
cp jarvis-completion.bash ~/.jarvis-completion.bash
```

2. **Add to ~/.bashrc:**

```bash
echo '# jarvis completion' >> ~/.bashrc
echo 'source ~/.jarvis-completion.bash' >> ~/.bashrc
```

3. **Reload your shell:**

```bash
source ~/.bashrc
```

### Part 4: For Oh My Zsh users (if applicable)

1. **Copy to Oh My Zsh completions:**

```bash
cp _jarvis ~/.oh-my-zsh/completions/
```

2. **Ensure completion is enabled in ~/.zshrc:**

```zsh
# This should already be there in Oh My Zsh
autoload -U compinit && compinit
```

3. **Restart zsh:**

```bash
exec zsh
```

## 🔄 How to Update When You Change Your Script

Whenever you add new commands or change existing ones:

1. **Edit the schema file:**

```bash
nano ~/.config/jarvis/.jarvis-schema.json
```

2. **Regenerate completions:**

```bash
cd ~/.config/jarvis
python3 generate-completions.py
```

3. **Reinstall the completion (just copy again):**

```bash
# For Zsh
cp _jarvis ~/.zsh/completions/

# For Bash
cp jarvis-completion.bash ~/.jarvis-completion.bash

# For Oh My Zsh
cp _jarvis ~/.oh-my-zsh/completions/
```

4. **Reload completion (Zsh):**

```bash
# Either restart terminal, or:
rm -f ~/.zcompdump
compinit
```

## ✅ Testing Your Completion

Try these commands and press TAB after each:

```bash
jarvis [TAB]                 # Shows all commands
jarvis l[TAB]                # Shows commands starting with 'l'
jarvis lights [TAB]          # Shows on/off
jarvis lock [TAB]            # Shows delay suggestions
jarvis nmhunter --[TAB]      # Shows flags
jarvis nmhunter ~/[TAB]      # Shows directory completion
jarvis bkash [TAB]           # Shows cashout/sendmoney
jarvis bkash cashout [TAB]   # Shows from/for
```

## 🐛 Troubleshooting

### Completion not working?

1. **Check if compinit is loaded:**

```bash
# For Zsh
echo $fpath | grep completions
which compinit

# For Bash
type complete
```

2. **Manual reload:**

```bash
# Zsh
autoload -U compinit && compinit

# Bash
source ~/.bashrc
```

3. **Verify file locations:**

```bash
# Zsh
ls -la ~/.zsh/completions/_jarvis

# Bash
ls -la ~/.jarvis-completion.bash
```

4. **Debug mode (Zsh):**

```bash
# Add to ~/.zshrc temporarily
zstyle ':completion:*' verbose yes
zstyle ':completion:*' debug true
```

5. **Check if jarvis is in PATH:**

```bash
which jarvis
# Should show the path to your jarvis command
```

## 📝 Example Schema Updates

### Adding a new command:

```json
"mynewcmd": {
  "aliases": ["mnc"],
  "description": "My new command",
  "args": [
    {
      "name": "filename",
      "type": "path",
      "description": "File to process"
    }
  ]
}
```

### Adding new subcommand to lights:

```json
"blink": {
  "aliases": ["bk"],
  "description": "Make LEDs blink",
  "args": [
    {
      "name": "interval",
      "type": "number",
      "suggestions": ["1", "2", "5"]
    }
  ]
}
```

## 🎉 You're done!

Now you have professional auto-completion for your CLI tool, just like git or npm!
````

## Step 5: Quick Setup Script

Save this as `setup.sh` to automate everything:

```bash
#!/bin/bash
# Auto-setup script for jarvis completion

set -e

echo "🔧 jarvis CLI Completion Setup"
echo "================================"
echo

# Detect shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_TYPE="zsh"
    CONFIG_FILE="$HOME/.zshrc"
    COMPLETION_DIR="$HOME/.zsh/completions"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_TYPE="bash"
    CONFIG_FILE="$HOME/.bashrc"
    COMPLETION_DIR="$HOME/.bash_completion.d"
else
    echo "❌ Unsupported shell. Please use Zsh or Bash."
    exit 1
fi

echo "📌 Detected shell: $SHELL_TYPE"

# Create config directory
CONFIG_DIR="$HOME/.config/jarvis"
mkdir -p "$CONFIG_DIR"

# Check if files exist in current directory
if [ ! -f ".jarvis-schema.json" ]; then
    echo "❌ .jarvis-schema.json not found in current directory"
    echo "   Please make sure you're in the directory with the schema file"
    exit 1
fi

if [ ! -f "generate-completions.py" ]; then
    echo "❌ generate-completions.py not found"
    exit 1
fi

# Copy files to config directory
echo "📁 Copying files to $CONFIG_DIR"
cp .jarvis-schema.json "$CONFIG_DIR/"
cp generate-completions.py "$CONFIG_DIR/"

# Generate completions
echo "🔨 Generating completions..."
cd "$CONFIG_DIR"
python3 generate-completions.py

# Install completion
echo "📦 Installing completion for $SHELL_TYPE"

if [ "$SHELL_TYPE" = "zsh" ]; then
    mkdir -p "$COMPLETION_DIR"
    cp _jarvis "$COMPLETION_DIR/"

    # Add to .zshrc if not already there
    if ! grep -q "fpath=($COMPLETION_DIR" "$CONFIG_FILE"; then
        echo "" >> "$CONFIG_FILE"
        echo "# jarvis completion" >> "$CONFIG_FILE"
        echo "fpath=($COMPLETION_DIR \$fpath)" >> "$CONFIG_FILE"
        echo "autoload -U compinit && compinit" >> "$CONFIG_FILE"
        echo "✅ Added completion config to $CONFIG_FILE"
    else
        echo "✅ Completion already configured in $CONFIG_FILE"
    fi

else # bash
    mkdir -p "$COMPLETION_DIR"
    cp jarvis-completion.bash "$COMPLETION_DIR/jarvis"

    # Add to .bashrc if not already there
    if ! grep -q "source $COMPLETION_DIR/jarvis" "$CONFIG_FILE"; then
        echo "" >> "$CONFIG_FILE"
        echo "# jarvis completion" >> "$CONFIG_FILE"
        echo "source $COMPLETION_DIR/jarvis" >> "$CONFIG_FILE"
        echo "✅ Added completion config to $CONFIG_FILE"
    else
        echo "✅ Completion already configured in $CONFIG_FILE"
    fi
fi

echo
echo "✨ Setup complete!"
echo
echo "To start using completion:"
echo "  1. Restart your terminal, OR"
echo "  2. Run: source $CONFIG_FILE"
echo
echo "Test it with: jarvis [TAB]"
```

Make it executable:

```bash
chmod +x setup.sh
```

## 🎯 Final Steps

1. **Run the setup script:**

```bash
./setup.sh
```

2. **Restart your terminal** or run `source ~/.zshrc` (or `~/.bashrc`)

3. **Test it out:**

```bash
jarvis [TAB][TAB]  # Should show all commands
jarvis l[TAB]      # Should show lights, lock, etc.
jarvis lights [TAB] # Should show on/off
```

## 📝 Important Notes

1. **When you modify `jarvis` script**: Update `.jarvis-schema.json` first, then regenerate
2. **The generator is idempotent** - You can run it anytime, it will overwrite old completions
3. **Keep the schema and generator together** in `~/.config/jarvis/`
4. **The completion files are auto-generated** - Don't edit them directly, edit the schema instead

This system gives you:

- ✅ Single source of truth (JSON schema)
- ✅ Auto-generates both Zsh and Bash completions
- ✅ Easy to update when you add commands
- ✅ Professional tab completion like git/npm
- ✅ Works with your existing script without modifications

You're all set! 🎉
