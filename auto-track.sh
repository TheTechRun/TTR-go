#!/usr/bin/env bash

# TTR-go History Auto-tracking
# Add this to your .bashrc to automatically track navigation

# Cleanup function for jump file
cleanup_jump_file() {
    # Clear jump file when shell exits (session-only)
    local script_dir="/home/ttr/.scripts/TTR-Scripts/TTR-go"
    > "$script_dir/go-jump.txt" 2>/dev/null
}

# Set up cleanup on shell exit
trap cleanup_jump_file EXIT

# Track directory changes with cd
cd() {
    builtin cd "$@" && {
        local current_dir="$(pwd)"
        # Add to both history and jump
        /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-history "$current_dir"
        /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-jump "$current_dir"
    }
}

# Track file access with common editors
vim() {
    command vim "$@"
    # Add files to both history and jump
    for file in "$@"; do
        if [ -f "$file" ]; then
            local full_path="$(realpath "$file")"
            /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-history "$full_path"
            /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-jump "$full_path"
        fi
    done
}

nvim() {
    command nvim "$@"
    # Add files to both history and jump
    for file in "$@"; do
        if [ -f "$file" ]; then
            local full_path="$(realpath "$file")"
            /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-history "$full_path"
            /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-jump "$full_path"
        fi
    done
}

nano() {
    command nano "$@"
    # Add files to both history and jump
    for file in "$@"; do
        if [ -f "$file" ]; then
            local full_path="$(realpath "$file")"
            /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-history "$full_path"
            /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-jump "$full_path"
        fi
    done
}

# Track files opened with common commands
cat() {
    command cat "$@"
    # Add files to both history and jump
    for file in "$@"; do
        if [ -f "$file" ]; then
            local full_path="$(realpath "$file")"
            /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-history "$full_path"
            /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-jump "$full_path"
        fi
    done
}

less() {
    command less "$@"
    # Add files to both history and jump
    for file in "$@"; do
        if [ -f "$file" ]; then
            local full_path="$(realpath "$file")"
            /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-history "$full_path"
            /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-jump "$full_path"
        fi
    done
}

more() {
    command more "$@"
    # Add files to both history and jump
    for file in "$@"; do
        if [ -f "$file" ]; then
            local full_path="$(realpath "$file")"
            /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-history "$full_path"
            /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-jump "$full_path"
        fi
    done
}

# Function to manually add a file/directory to history and jump
gha() {
    if [ $# -eq 0 ]; then
        echo "Usage: gha <file_or_directory>"
        return 1
    fi
    
    for item in "$@"; do
        if [ -e "$item" ]; then
            local full_path="$(realpath "$item")"
            /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-history "$full_path"
            /home/ttr/.scripts/TTR-Scripts/TTR-go/ttr-go.sh add-jump "$full_path"
            echo "Added to history and jump: $full_path"
        else
            echo "Error: $item does not exist"
        fi
    done
}
