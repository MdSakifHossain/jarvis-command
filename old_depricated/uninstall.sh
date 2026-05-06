#!/usr/bin/env bash

DEFAULT_DIR="command"

# Resolve input
if [ -n "$1" ]; then
    src="$1"
else
    read -p "Enter script name or path [default: $DEFAULT_DIR/]: " input
    src="${input:-$DEFAULT_DIR}"
fi

# If directory, infer command name from first file
if [ -d "$src" ]; then
    file=$(find "$src" -maxdepth 1 -type f | head -n 1)
    if [ -z "$file" ]; then
        echo "❌ No files found in directory '$src'"
        exit 1
    fi
    command_name=$(basename "$file")
else
    command_name=$(basename "$src")
fi

target_path="/usr/local/bin/$command_name"

echo "Removing '$command_name'..."

if [ -f "$target_path" ]; then
    sudo rm -f "$target_path"
    echo "✅ Removed successfully."
else
    echo "⚠️ '$command_name' not found in /usr/local/bin"
fi
