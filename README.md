# TTR-go Navigation System

TTR-go is an intelligent navigation and file management system that provides three complementary ways to quickly access your files and directories using `fzf` for interactive selection.

## Quick Setup

Git clone and download:

```
mkdir -p ~/.scripts/TTR-Scripts/
cd ~/.scripts/TTR-Scripts/ 
git clone https://github.com/TheTechRun/ttr-go.git
```

Add TTR-Go aliases to your ~/.bashrc:

```bash
echo "# For ttr-go:" >> ~/.bashrc
echo "source ~/.scripts/TTR-Scripts/TTR-go/alias.txt" >> ~/.bashrc
source ~/.bashrc
```

## Overview

### 🌟 **Favorites** (Persistent, Manual)
- Manually curated important files and directories
- Persists across all sessions
- Perfect for frequently accessed project files, configs, etc.

### 📚 **History** (Persistent, Automatic)  
- Automatically tracks all navigation and file access
- Persists across all sessions
- Great for recently worked on files and directories

### 🚀 **Jump** (Session-only, Automatic)
- Automatically tracks navigation like history
- Clears when shell session ends
- Perfect for temporary work within a session

## Installation

1. **Ensure files are in place**:
   ```
   ~/.scripts/TTR-Scripts/TTR-go/
   ├── ttr-go.sh          # Main script
   ├── auto-track.sh      # Auto-tracking functions
   ├── alias.txt          # Aliases and functions
   ├── go-favorites.txt   # Favorites storage
   ├── go-history.txt     # History storage  
   ├── go-jump.txt        # Jump storage (session-only)
   └── knowledge/         # Documentation
   ```

2. **Add to your `.bashrc`**:
   ```bash
   echo "source ~/.scripts/TTR-Scripts/TTR-go/alias.txt" >> ~/.bashrc
   source ~/.bashrc
   ```

3. **Verify installation**:
   ```bash
   gF --help  # Should show TTR-go help
   ```

## Commands

### Favorites Commands
| Command | Description |
|---------|-------------|
| `gF` | Add files/directories from current location to favorites |
| `gf` | Browse and open favorites |
| `gfl` | List all favorites |
| `gfr` | Remove favorites |

### History Commands  
| Command | Description |
|---------|-------------|
| `gh` | Browse and open from navigation history |
| `ghl` | List navigation history |
| `ghc` | Clear navigation history |

### Jump Commands
| Command | Description |
|---------|-------------|
| `gj` | Browse and open from jump list |
| `gjl` | List jump locations (session-only) |
| `gjc` | Clear jump list |

## auto-track.sh Functionality

**auto-track.sh** is the **automatic tracking component** of the TTR-go navigation system. It provides seamless, transparent tracking of your file and directory access without requiring manual intervention.

### Key Features:

**Automatic Directory Tracking**: Wraps the `cd` command to automatically add every directory you navigate to into both the history and jump lists.

**Automatic File Access Tracking**: Wraps common file viewing/editing commands (`vim`, `nvim`, `nano`, `cat`, `less`, `more`) and automatically adds files you open/view to both history and jump lists.

**Session Management**: Sets up a cleanup trap that clears the jump list when your shell session exits, keeping the jump list session-only while preserving history across sessions.

**Manual Addition Function**: Provides `gha` command to manually add files/directories to both history and jump lists.

### How auto-track.sh Works:

The script creates wrapper functions around common commands. When you use these commands, they:
1. Execute the original command normally
2. Automatically track the accessed files/directories by calling the main ttr-go.sh script
3. Add items to both persistent history and session-only jump lists

This creates a completely automatic navigation history that learns from your actual usage patterns, making the TTR-go system intelligent and responsive to your workflow without any conscious effort on your part.

## How Auto-tracking Works

TTR-go automatically tracks your navigation and file access through wrapper functions:

### **What gets tracked:**
- **Directory changes**: Every `cd` command
- **File editing**: `vim`, `nvim`, `nano`
- **File viewing**: `cat`, `less`, `more`
- **Manual additions**: `gha <file/directory>`

### **Where it goes:**
- **History**: All tracked items (persistent)
- **Jump**: All tracked items (cleared on shell exit)
- **Favorites**: Only manual additions via `gF`

### **Example workflow:**
```bash
cd ~/projects/myapp     # → Added to history + jump
vim src/main.py         # → Added to history + jump  
cat README.md           # → Added to history + jump
gh                      # → Shows all three items
gj                      # → Shows all three items
exit                    # → Jump cleared, history preserved
# New session
gh                      # → Still shows all items
gj                      # → Empty (cleared)
```

## Configuration

### **Adjusting Maximum Limits**

You can modify the maximum number of items stored by editing these lines in `ttr-go.sh`:

#### **History Limit (Default: 25)**
**File**: `ttr-go.sh`  
**Line**: ~136  
**Function**: `add_to_history()`
```bash
# Keep only the first 25 lines (most recent)
head -25 "$temp_file" > "$HISTORY_FILE"
```
Change `25` to your desired limit.

#### **Jump Limit (Default: 10)**  
**File**: `ttr-go.sh`  
**Line**: ~261  
**Function**: `add_to_jump()`
```bash
# Keep only the first 10 lines (most recent) - smaller limit for session-only
head -10 "$temp_file" > "$JUMP_FILE"
```
Change `10` to your desired limit.

### **Quick Limit Reference**
| Component | File | Line | Function | Current Limit |
|-----------|------|------|----------|---------------|
| History | `ttr-go.sh` | ~136 | `add_to_history()` | 25 |
| Jump | `ttr-go.sh` | ~261 | `add_to_jump()` | 10 |
| Favorites | N/A | N/A | N/A | Unlimited |

## Dependencies

- **Required**: `fzf` (fuzzy finder)
- **Optional**: `$EDITOR` environment variable for file editing
- **Optional**: `xdg-open` or `open` for default applications

### Installing fzf
```bash
# Most package managers
sudo apt install fzf          # Debian/Ubuntu
sudo pacman -S fzf            # Arch
brew install fzf              # macOS

# NixOS - add to configuration.nix:
environment.systemPackages = [ pkgs.fzf ];
```

## File Formats

### **go-favorites.txt**
Plain text, one absolute path per line:
```
~/nixos-config
~/.bashrc  
~/projects/myapp/src/main.py
```

### **go-history.txt**  
Same format as favorites, automatically managed:
```
~/current-work-dir
~/projects/myapp/README.md
~/Downloads
```

### **go-jump.txt**
Same format, cleared on shell exit:
```
/tmp/temp-work
~/current-session-files
```

## Advanced Usage

### **Manual File Addition**
```bash
gha /path/to/important/file    # Add to both history and jump
gha ~/projects/*/README.md     # Add multiple files
```

### **Preview in fzf**
All browse commands (`gf`, `gh`, `gj`) include preview:
- **Directories**: Shows `ls -la` listing
- **Files**: Shows first 20 lines with `head -20`

### **Missing File Handling**
- Browse commands automatically detect and remove missing files
- List commands show missing files with `[MISSING]` indicator

## Troubleshooting

### **"fzf not found"**
Install fzf through your package manager or ensure it's in your PATH.

### **Commands not recognized**
Ensure you've sourced the alias file:
```bash
source ~/.scripts/TTR-Scripts/TTR-go/alias.txt
```

### **Auto-tracking not working**
Check if auto-track.sh is being sourced (it's included in alias.txt).

### **Jump list not clearing**
The cleanup happens on shell EXIT. If you kill the terminal, cleanup may not run.

### **Functions not working in your shell**
TTR-go is designed for bash. Other shells may have compatibility issues.

## Technical Details

### **Session-only Implementation**
Jump uses a cleanup trap that runs when the shell exits:
```bash
trap cleanup_jump_file EXIT
```

### **Wrapper Script Architecture**  
Uses `eval` with command output to enable directory changes in current shell:
```bash
alias gf='eval "$(/path/to/ttr-go.sh open-favorite-wrapper)"'
```

### **Duplicate Prevention**
All systems remove duplicates and move accessed items to the top of their respective lists.

## Version History

- **v1.0**: Initial implementation with favorites
- **v1.1**: Added history system with auto-tracking
- **v1.2**: Added jump system with session-only behavior
- **v1.3**: Simplified by removing redundant manual directory additions

---

**Created**: August 2025  
**Author**: TTR  
**License**: MIT
# ttr-go
