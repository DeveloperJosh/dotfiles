#!/bin/bash

# --- Variables ---
DOTFILES_DIR="$HOME/.dotfiles"
REPO_URL="https://github.com/DeveloperJosh/dotfiles.git"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config_backups_$(date +%Y%m%d_%H%M%S)"
CONFIGS_TO_LINK=(
    "hypr"
    "kitty"
    "waybar"
    "fastfetch"
    "mako"
)

print_message() {
    local color=$1
    local message=$2
    case $color in
        "green") echo -e "\e[32m✔ ${message}\e[0m" ;;
        "yellow") echo -e "\e[33m! ${message}\e[0m" ;;
        "blue") echo -e "\e[34m➜ ${message}\e[0m" ;;
        "red") echo -e "\e[31m✖ ${message}\e[0m" ;;
    esac
}

# --- Main Script ---

# Navigate to the home directory
cd "$HOME" || exit

print_message "blue" "Starting dotfiles setup..."

# 1. Clone the dotfiles repository if it doesn't exist
if [ ! -d "$DOTFILES_DIR" ]; then
    print_message "blue" "Cloning dotfiles repository from GitHub..."
    if git clone "$REPO_URL" "$DOTFILES_DIR"; then
        print_message "green" "Repository cloned successfully to $DOTFILES_DIR"
    else
        print_message "red" "Failed to clone repository. Aborting."
        exit 1
    fi
else
    print_message "yellow" "Dotfiles repository already exists at $DOTFILES_DIR. Skipping clone."
fi

# 2. Create backup and config directories
print_message "blue" "Creating backup directory at $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$CONFIG_DIR"

# 3. Backup existing configs and create symlinks
for config in "${CONFIGS_TO_LINK[@]}"; do
    source_path="$DOTFILES_DIR/$config"
    target_path="$CONFIG_DIR/$config"

    print_message "blue" "Processing '$config' configuration..."

    # Check if the source directory exists in the dotfiles repo
    if [ ! -d "$source_path" ]; then
        print_message "yellow" "Source directory '$source_path' not found. Skipping."
        continue
    fi

    # If an existing config is found, move it to the backup directory
    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        print_message "yellow" "Existing configuration found at '$target_path'. Backing it up."
        if mv "$target_path" "$BACKUP_DIR/"; then
            print_message "green" "Backup of '$config' created in $BACKUP_DIR"
        else
            print_message "red" "Failed to back up '$config'. Skipping."
            continue
        fi
    fi

    print_message "blue" "Creating symbolic link for '$config'..."
    if ln -s "$source_path" "$target_path"; then
        print_message "green" "Successfully linked '$config' to $target_path"
    else
        print_message "red" "Failed to create symbolic link for '$config'."
    fi
    echo 
done

print_message "green" "------------------------------------------------"
print_message "green" "Dotfiles setup complete! ✅"
print_message "yellow" "Original configurations (if any) are backed up in: $BACKUP_DIR"
print_message "blue" "You may need to log out and back in for all changes to take effect."