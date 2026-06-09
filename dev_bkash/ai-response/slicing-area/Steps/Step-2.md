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
