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
