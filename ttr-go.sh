#!/usr/bin/env bash

# TTR-go: A navigation and favorites management system
# Author: TTR
# Description: Manage favorites, jump locations, and navigation history

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAVORITES_FILE="$SCRIPT_DIR/go-favorites.txt"
HISTORY_FILE="$SCRIPT_DIR/go-history.txt"
# Jump file that gets cleared on session exit
JUMP_FILE="$SCRIPT_DIR/go-jump.txt"

# Editor to use for opening files
EDITOR="$(which kak)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to extract path from new format line
extract_path() {
    local line="$1"
    # Remove "Directory: " or "File: " prefix
    echo "$line" | sed -E 's/^(Directory|File): //'
}

# Function to add path with type prefix
format_path() {
    local path="$1"
    if [ -d "$path" ]; then
        echo "Directory: $path"
    elif [ -f "$path" ]; then
        echo "File: $path"
    else
        # Default to directory if we can't determine
        echo "Directory: $path"
    fi
}

# Function to display help
show_help() {
    echo "TTR-go - Navigation and Favorites Management"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  add-favorite     Add current directory or file to favorites (gF alias)"
    echo "  open-favorite    Open favorite file/directory (gf alias)"
    echo "  list-favorites   List all favorites"
    echo "  remove-favorite  Remove a favorite"
    echo "  open-history     Open from navigation history (gh alias)"
    echo "  list-history     List navigation history"
    echo "  clear-history    Clear navigation history"
    echo "  add-history      Add item to history (internal use)"
    echo "  open-jump        Open from jump list (gj alias)"
    echo "  add-jump         Add item to jump list (internal use)"
    echo "  list-jump        List jump locations (session-only)"
    echo "  clear-jump       Clear jump list"
    echo "  help            Show this help message"
    echo ""
    echo "Aliases:"
    echo "  gF              Add to favorites"
    echo "  gf              Open favorite"
    echo "  gh              Open from history"
    echo "  gj              Open from jump list"
    echo "  gfl             List favorites"
    echo "  gfr             Remove favorite"
    echo "  ghl             List history"
    echo "  ghc             Clear history"
    echo "  gjl             List jump locations"
    echo "  gjc             Clear jump list"
}

# Function to add favorite
add_favorite() {
    # Check if fzf is available
    if ! command -v fzf &> /dev/null; then
        echo -e "${RED}Error: fzf is not installed or not in PATH${NC}"
        return 1
    fi

    local current_dir="$(pwd)"
    local items=()
    
    # Add "Directory" option first
    items+=("Directory")
    
    # Add files and directories from current location
    while IFS= read -r -d '' item; do
        items+=("$(basename "$item")")
    done < <(find "$current_dir" -maxdepth 1 -type f -print0 2>/dev/null)
    
    while IFS= read -r -d '' item; do
        items+=("$(basename "$item")/")
    done < <(find "$current_dir" -maxdepth 1 -type d ! -path "$current_dir" -print0 2>/dev/null)
    
    if [ ${#items[@]} -eq 1 ]; then
        echo -e "${YELLOW}No files or directories found in current location${NC}"
        return 1
    fi
    
    # Use fzf to select item
    local selected
    selected=$(printf '%s\n' "${items[@]}" | fzf --prompt="Add to favorites: " --height=40% --border)
    
    if [ -z "$selected" ]; then
        echo -e "${YELLOW}No selection made${NC}"
        return 0
    fi
    
    local full_path
    local formatted_entry
    if [ "$selected" = "Directory" ]; then
        full_path="$current_dir"
        formatted_entry="Directory: $full_path"
        echo -e "${GREEN}Added directory to favorites: $full_path${NC}"
    else
        # Remove trailing slash if it's a directory
        selected="${selected%/}"
        full_path="$current_dir/$selected"
        if [ ! -e "$full_path" ]; then
            echo -e "${RED}Error: Selected item does not exist${NC}"
            return 1
        fi
        formatted_entry=$(format_path "$full_path")
        echo -e "${GREEN}Added to favorites: $full_path${NC}"
    fi
    
    # Check if already in favorites
    if [ -f "$FAVORITES_FILE" ] && grep -Fxq "$formatted_entry" "$FAVORITES_FILE"; then
        echo -e "${YELLOW}Item already in favorites${NC}"
        return 0
    fi
    
    # Add to favorites file
    echo "$formatted_entry" >> "$FAVORITES_FILE"
}

# Function to remove item from favorites file
remove_from_favorites() {
    local item_to_remove="$1"
    local temp_file=$(mktemp)
    
    if [ -f "$FAVORITES_FILE" ]; then
        grep -Fxv "$item_to_remove" "$FAVORITES_FILE" > "$temp_file" 2>/dev/null || true
        mv "$temp_file" "$FAVORITES_FILE"
    fi
}

open_favorite_wrapper() {
    # Check if fzf is available
    if ! command -v fzf > /dev/null 2>&1; then
        echo "echo -e '\033[0;31mError: fzf is not installed or not in PATH\033[0m'"
        return 1
    fi
    
    # Check if favorites file exists and has content
    if [ ! -f "$FAVORITES_FILE" ] || [ ! -s "$FAVORITES_FILE" ]; then
        echo "echo -e '\033[1;33mNo favorites found. Use gF to add favorites.\033[0m'"
        return 0
    fi
    
# Use fzf to select favorite with custom keybinds
local selected
selected=$(cat "$FAVORITES_FILE" | fzf \
    --prompt="Open favorite: " \
    --height=80% \
    --layout=reverse-list \
    --border \
    --preview="path=\$(echo {} | sed -E 's/^(Directory|File): //'); if [ -d \"\$path\" ]; then ls -la \"\$path\"; elif [ -f \"\$path\" ]; then head -20 \"\$path\"; fi" \
    --preview-window="down:40%:wrap" \
    --bind="tab:clear-query" \
    --bind="del:execute(echo {} > /tmp/ttr-go-delete)+abort" \
    --bind="ctrl-t:reload(grep '^Directory:' '$FAVORITES_FILE'; grep '^File:' '$FAVORITES_FILE')" \
    --bind="ctrl-f:reload(grep '^File:' '$FAVORITES_FILE'; grep '^Directory:' '$FAVORITES_FILE')" \
    --bind="ctrl-r:reload(tac '$FAVORITES_FILE')" \
    --bind="ctrl-n:reload(cat '$FAVORITES_FILE')" \
    --bind="ctrl-a:reload(sort '$FAVORITES_FILE')" \
    --header="TAB: clear | DEL: delete | CTRL-T: dirs first | CTRL-F: files first | CTRL-R: reverse | CTRL-N: normal | CTRL-A: alpha sort")   

    # Check if we need to delete an item
    if [ -f "/tmp/ttr-go-delete" ]; then
        local item_to_delete=$(cat "/tmp/ttr-go-delete")
        rm -f "/tmp/ttr-go-delete"
        
        if [ -n "$item_to_delete" ]; then
            remove_from_favorites "$item_to_delete"
            echo "echo -e '\033[0;32mRemoved from favorites: $item_to_delete\033[0m'"
            echo "echo -e '\033[1;33mRun gf again to see updated favorites\033[0m'"
            return 0
        fi
    fi
    
    if [ -z "$selected" ]; then
        echo "echo -e '\033[1;33mNo selection made\033[0m'"
        return 0
    fi
    
    # Extract the actual path from the formatted entry
    local actual_path
    actual_path=$(extract_path "$selected")
    
    # Check if selected item exists
    if [ ! -e "$actual_path" ]; then
        echo "echo -e '\033[0;31mError: Selected item no longer exists: $actual_path\033[0m'"
        echo "echo -e '\033[1;33mConsider removing it from favorites\033[0m'"
        return 1
    fi
    
    # Output commands based on type
    if [ -d "$actual_path" ]; then
        # It's a directory - output cd command
        echo "echo -e '\033[0;32mChanging to directory: $actual_path\033[0m'"
        echo "cd '$actual_path' && ls -a"
    else
        # It's a file - open with default editor
        echo "echo -e '\033[0;32mOpening file: $actual_path\033[0m'"
        echo "$EDITOR '$actual_path'"
    fi
}

# Function to list favorites
list_favorites() {
    if [ ! -f "$FAVORITES_FILE" ] || [ ! -s "$FAVORITES_FILE" ]; then
        echo -e "${YELLOW}No favorites found${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Current Favorites:${NC}"
    echo "=================="
    local count=1
    while IFS= read -r line; do
        local path
        path=$(extract_path "$line")
        if [ -e "$path" ]; then
            echo -e "$count. ${GREEN}$line${NC}"
        else
            echo -e "$count. ${RED}[MISSING] $line${NC}"
        fi
        ((count++))
    done < "$FAVORITES_FILE"
}

# Function to remove favorite
remove_favorite() {
    if [ ! -f "$FAVORITES_FILE" ] || [ ! -s "$FAVORITES_FILE" ]; then
        echo -e "${YELLOW}No favorites to remove${NC}"
        return 0
    fi
    
    # Check if fzf is available
    if ! command -v fzf &> /dev/null; then
        echo -e "${RED}Error: fzf is not installed or not in PATH${NC}"
        return 1
    fi
    
    # Use fzf to select favorite to remove
    local selected
    selected=$(cat "$FAVORITES_FILE" | fzf --prompt="Remove favorite: " --height=40% --border)
    
    if [ -z "$selected" ]; then
        echo -e "${YELLOW}No selection made${NC}"
        return 0
    fi
    
    # Remove from favorites file
    local temp_file=$(mktemp)
    grep -Fxv "$selected" "$FAVORITES_FILE" > "$temp_file"
    mv "$temp_file" "$FAVORITES_FILE"
    
    echo -e "${GREEN}Removed from favorites: $selected${NC}"
}

# Function to add to history
add_to_history() {
    local item="$1"
    
    # Don't add if item doesn't exist
    if [ ! -e "$item" ]; then
        return 1
    fi
    
    # Create history file if it doesn't exist
    touch "$HISTORY_FILE"
    
    local formatted_entry
    formatted_entry=$(format_path "$item")
    
    # Remove item if it already exists (to avoid duplicates and move to top)
    if [ -f "$HISTORY_FILE" ]; then
        local temp_file=$(mktemp)
        grep -Fxv "$formatted_entry" "$HISTORY_FILE" > "$temp_file" 2>/dev/null || true
        mv "$temp_file" "$HISTORY_FILE"
    fi
    
    # Add item to top of history
    local temp_file=$(mktemp)
    echo "$formatted_entry" > "$temp_file"
    if [ -f "$HISTORY_FILE" ]; then
        cat "$HISTORY_FILE" >> "$temp_file"
    fi
    
    # Keep only the first 25 lines (most recent)
    head -25 "$temp_file" > "$HISTORY_FILE"
    rm "$temp_file"
}

# Function to remove item from history file
remove_from_history() {
    local item_to_remove="$1"
    local temp_file=$(mktemp)
    
    if [ -f "$HISTORY_FILE" ]; then
        grep -Fxv "$item_to_remove" "$HISTORY_FILE" > "$temp_file" 2>/dev/null || true
        mv "$temp_file" "$HISTORY_FILE"
    fi
}

# Function to open history item (wrapper mode - outputs commands for eval)
open_history_wrapper() {
    # Check if fzf is available
    if ! command -v fzf > /dev/null 2>&1; then
        echo "echo -e '\033[0;31mError: fzf is not installed or not in PATH\033[0m'"
        return 1
    fi
    
    # Check if history file exists and has content
    if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
        echo "echo -e '\033[1;33mNo history found. Navigation history will build automatically.\033[0m'"
        return 0
    fi
    
# Use fzf to select from history with custom keybinds
local selected
selected=$(cat "$HISTORY_FILE" | fzf \
    --prompt="Open from history: " \
    --height=80% \
    --layout=reverse-list \
    --border \
    --preview="path=\$(echo {} | sed -E 's/^(Directory|File): //'); if [ -d \"\$path\" ]; then ls -la \"\$path\"; elif [ -f \"\$path\" ]; then head -20 \"\$path\"; fi" \
    --preview-window="down:40%:wrap" \
    --bind="tab:clear-query" \
    --bind="del:execute(echo {} > /tmp/ttr-go-delete-history)+abort" \
    --bind="ctrl-t:reload(grep '^Directory:' '$HISTORY_FILE'; grep '^File:' '$HISTORY_FILE')" \
    --bind="ctrl-f:reload(grep '^File:' '$HISTORY_FILE'; grep '^Directory:' '$HISTORY_FILE')" \
    --bind="ctrl-r:reload(tac '$HISTORY_FILE')" \
    --bind="ctrl-n:reload(cat '$HISTORY_FILE')" \
    --bind="ctrl-a:reload(sort '$HISTORY_FILE')" \
    --header="TAB: clear | DEL: delete | CTRL-T: dirs first | CTRL-F: files first | CTRL-R: reverse | CTRL-N: normal | CTRL-A: alpha sort")

    # Check if we need to delete an item
    if [ -f "/tmp/ttr-go-delete-history" ]; then
        local item_to_delete=$(cat "/tmp/ttr-go-delete-history")
        rm -f "/tmp/ttr-go-delete-history"
        
        if [ -n "$item_to_delete" ]; then
            remove_from_history "$item_to_delete"
            echo "echo -e '\033[0;32mRemoved from history: $item_to_delete\033[0m'"
            echo "echo -e '\033[1;33mRun gh again to see updated history\033[0m'"
            return 0
        fi
    fi
    
    if [ -z "$selected" ]; then
        echo "echo -e '\033[1;33mNo selection made\033[0m'"
        return 0
    fi
    
    # Extract the actual path from the formatted entry
    local actual_path
    actual_path=$(extract_path "$selected")
    
    # Check if selected item exists
    if [ ! -e "$actual_path" ]; then
        echo "echo -e '\033[0;31mError: Selected item no longer exists: $actual_path\033[0m'"
        echo "echo -e '\033[1;33mRemoving from history...\033[0m'"
        # Remove the missing item from history
        local temp_file=$(mktemp)
        grep -Fxv "$selected" "$HISTORY_FILE" > "$temp_file" 2>/dev/null || true
        mv "$temp_file" "$HISTORY_FILE"
        return 1
    fi
    
    # Add to history (moves to top)
    add_to_history "$actual_path"
    
    # Output commands based on type
    if [ -d "$actual_path" ]; then
        # It's a directory - output cd command
        echo "echo -e '\033[0;32mChanging to directory: $actual_path\033[0m'"
        echo "cd '$actual_path' && ls -a"
    else
        # It's a file - open with default editor
        echo "echo -e '\033[0;32mOpening file: $actual_path\033[0m'"
        echo "$EDITOR '$actual_path'"
    fi
}

# Function to list history
list_history() {
    if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
        echo -e "${YELLOW}No history found${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Navigation History (Most Recent First):${NC}"
    echo "======================================="
    local count=1
    while IFS= read -r line; do
        local path
        path=$(extract_path "$line")
        if [ -e "$path" ]; then
            echo -e "$count. ${GREEN}$line${NC}"
        else
            echo -e "$count. ${RED}[MISSING] $line${NC}"
        fi
        ((count++))
    done < "$HISTORY_FILE"
}

# Function to clear history
clear_history() {
    if [ -f "$HISTORY_FILE" ]; then
        > "$HISTORY_FILE"
        echo -e "${GREEN}History cleared${NC}"
    else
        echo -e "${YELLOW}No history file to clear${NC}"
    fi
}

# Function to add to jump list
add_to_jump() {
    local item="$1"
    
    # Don't add if item doesn't exist
    if [ ! -e "$item" ]; then
        return 1
    fi
    
    # Create jump file if it doesn't exist
    touch "$JUMP_FILE"
    
    local formatted_entry
    formatted_entry=$(format_path "$item")
    
    # Remove item if it already exists (to avoid duplicates and move to top)
    if [ -f "$JUMP_FILE" ]; then
        local temp_file=$(mktemp)
        grep -Fxv "$formatted_entry" "$JUMP_FILE" > "$temp_file" 2>/dev/null || true
        mv "$temp_file" "$JUMP_FILE"
    fi
    
    # Add item to top of jump list
    local temp_file=$(mktemp)
    echo "$formatted_entry" > "$temp_file"
    if [ -f "$JUMP_FILE" ]; then
        cat "$JUMP_FILE" >> "$temp_file"
    fi
    
    # Keep only the first 10 lines (most recent) - smaller limit for session-only
    head -10 "$temp_file" > "$JUMP_FILE"
    rm "$temp_file"
}

# Function to remove item from jump file
remove_from_jump() {
    local item_to_remove="$1"
    local temp_file=$(mktemp)
    
    if [ -f "$JUMP_FILE" ]; then
        grep -Fxv "$item_to_remove" "$JUMP_FILE" > "$temp_file" 2>/dev/null || true
        mv "$temp_file" "$JUMP_FILE"
    fi
}

# Function to open jump item (wrapper mode - outputs commands for eval)
open_jump_wrapper() {
    # Check if fzf is available
    if ! command -v fzf > /dev/null 2>&1; then
        echo "echo -e '\033[0;31mError: fzf is not installed or not in PATH\033[0m'"
        return 1
    fi
    
    # Check if jump file exists and has content
    if [ ! -f "$JUMP_FILE" ] || [ ! -s "$JUMP_FILE" ]; then
        echo "echo -e '\033[1;33mNo jump locations found. Use gJ to add jump locations.\033[0m'"
        return 0
    fi
    
# Use fzf to select from jump list with custom keybinds
local selected
selected=$(cat "$JUMP_FILE" | fzf \
    --prompt="Jump to: " \
    --height=80% \
    --layout=reverse-list \
    --border \
    --preview="path=\$(echo {} | sed -E 's/^(Directory|File): //'); if [ -d \"\$path\" ]; then ls -la \"\$path\"; elif [ -f \"\$path\" ]; then head -20 \"\$path\"; fi" \
    --preview-window="down:40%:wrap" \
    --bind="tab:clear-query" \
    --bind="del:execute(echo {} > /tmp/ttr-go-delete-jump)+abort" \
    --bind="ctrl-t:reload(grep '^Directory:' '$JUMP_FILE'; grep '^File:' '$JUMP_FILE')" \
    --bind="ctrl-f:reload(grep '^File:' '$JUMP_FILE'; grep '^Directory:' '$JUMP_FILE')" \
    --bind="ctrl-r:reload(tac '$JUMP_FILE')" \
    --bind="ctrl-n:reload(cat '$JUMP_FILE')" \
    --bind="ctrl-a:reload(sort '$JUMP_FILE')" \
    --header="TAB: clear | DEL: delete | CTRL-T: dirs first | CTRL-F: files first | CTRL-R: reverse | CTRL-N: normal | CTRL-A: alpha sort")

    # Check if we need to delete an item
    if [ -f "/tmp/ttr-go-delete-jump" ]; then
        local item_to_delete=$(cat "/tmp/ttr-go-delete-jump")
        rm -f "/tmp/ttr-go-delete-jump"
        
        if [ -n "$item_to_delete" ]; then
            remove_from_jump "$item_to_delete"
            echo "echo -e '\033[0;32mRemoved from jump list: $item_to_delete\033[0m'"
            echo "echo -e '\033[1;33mRun gj again to see updated jump list\033[0m'"
            return 0
        fi
    fi
    
    if [ -z "$selected" ]; then
        echo "echo -e '\033[1;33mNo selection made\033[0m'"
        return 0
    fi
    
    # Extract the actual path from the formatted entry
    local actual_path
    actual_path=$(extract_path "$selected")
    
    # Check if selected item exists
    if [ ! -e "$actual_path" ]; then
        echo "echo -e '\033[0;31mError: Selected item no longer exists: $actual_path\033[0m'"
        echo "echo -e '\033[1;33mRemoving from jump list...\033[0m'"
        # Remove the missing item from jump list
        local temp_file=$(mktemp)
        grep -Fxv "$selected" "$JUMP_FILE" > "$temp_file" 2>/dev/null || true
        mv "$temp_file" "$JUMP_FILE"
        return 1
    fi
    
    # Add to jump list (moves to top)
    add_to_jump "$actual_path"
    
    # Output commands based on type
    if [ -d "$actual_path" ]; then
        # It's a directory - output cd command
        echo "echo -e '\033[0;32mJumping to directory: $actual_path\033[0m'"
        echo "cd '$actual_path' && ls -a"
    else
        # It's a file - open with default editor
        echo "echo -e '\033[0;32mOpening file: $actual_path\033[0m'"
        echo "$EDITOR '$actual_path'"
    fi
}

# Function to list jump locations
list_jump() {
    if [ ! -f "$JUMP_FILE" ] || [ ! -s "$JUMP_FILE" ]; then
        echo -e "${YELLOW}No jump locations found (session-only)${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Jump Locations (This Session Only):${NC}"
    echo "===================================="
    local count=1
    while IFS= read -r line; do
        local path
        path=$(extract_path "$line")
        if [ -e "$path" ]; then
            echo -e "$count. ${GREEN}$line${NC}"
        else
            echo -e "$count. ${RED}[MISSING] $line${NC}"
        fi
        ((count++))
    done < "$JUMP_FILE"
}

# Function to clear jump list
clear_jump() {
    if [ -f "$JUMP_FILE" ]; then
        rm "$JUMP_FILE"
        echo -e "${GREEN}Jump list cleared${NC}"
    else
        echo -e "${YELLOW}No jump list to clear${NC}"
    fi
}

# Main script logic
case "${1:-}" in
    "add-favorite")
        add_favorite
        ;;
    "open-favorite")
        open_favorite
        ;;
    "open-favorite-wrapper")
        open_favorite_wrapper
        ;;
    "list-favorites")
        list_favorites
        ;;
    "remove-favorite")
        remove_favorite
        ;;
    "add-history")
        if [ -n "$2" ]; then
            add_to_history "$2"
        else
            echo -e "${RED}Error: add-history requires a path argument${NC}"
            exit 1
        fi
        ;;
    "open-history")
        open_history_wrapper
        ;;
    "list-history")
        list_history
        ;;
    "clear-history")
        clear_history
        ;;
    "add-jump")
        if [ -n "$2" ]; then
            add_to_jump "$2"
        else
            echo -e "${RED}Error: add-jump requires a path argument${NC}"
            exit 1
        fi
        ;;
    "open-jump")
        open_jump_wrapper
        ;;
    "list-jump")
        list_jump
        ;;
    "clear-jump")
        clear_jump
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    "")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
