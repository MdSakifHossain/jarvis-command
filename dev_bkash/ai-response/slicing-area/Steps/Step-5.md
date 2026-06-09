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
