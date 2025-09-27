#!/bin/bash

# --- Variables ---
DOTFILES_DIR="$HOME/.dotfiles"
REPO_URL="https://github.com/DeveloperJosh/dotfiles.git"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config_backups_$(date +%s)" 
CONFIGS_TO_LINK=(
    "hypr"
    "kitty"
    "waybar"
    "fastfetch"
    "mako"
)

# --- Applications to Install ---
APPS_TO_INSTALL=(
    "yazi"
    "wlogout"
    "mako"
    "fastfetch"
    "waybar"
    "kitty"
    "fish"
    "ttf-nerd-fonts-symbols" # Symbols Nerd Font Mono
    "ttf-jetbrains-mono-nerd" # JetBrainsMono Nerd Font
    "brightnessctl"
)
# A subset of apps to check for after installation
CORE_APPS_TO_CHECK=(
    "fish"
    "yay"
    "kitty"
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

# --- Helper Functions ---

# Function to install yay (AUR Helper) using the specified sequence
install_yay() {
    if command -v yay &> /dev/null; then
        print_message "yellow" "yay is already installed. Skipping installation."
        return 0
    fi

    print_message "blue" "Attempting to install yay (AUR helper) using the specified commands."
    
    # 1. Install prerequisites (git and base-devel)
    print_message "blue" "Installing git and base-devel with pacman..."
    if ! sudo pacman -S --needed --noconfirm git base-devel; then
        print_message "red" "Failed to install git or base-devel. Aborting yay setup."
        return 1
    fi

    local YAY_BUILD_DIR="$HOME/yay_build_temp"
    rm -rf "$YAY_BUILD_DIR"
    mkdir -p "$YAY_BUILD_DIR"
    cd "$YAY_BUILD_DIR" || return 1

    # 2. Clone the yay repository
    print_message "blue" "Cloning yay repository..."
    if ! git clone https://aur.archlinux.org/yay.git; then
        print_message "red" "Failed to clone the yay git repository. Cleaning up and aborting."
        cd "$HOME"
        rm -rf "$YAY_BUILD_DIR"
        return 1
    fi

    # 3. Change into the cloned directory
    cd yay || {
        print_message "red" "Cloned 'yay' directory not found. Cleaning up and aborting."
        cd "$HOME"
        rm -rf "$YAY_BUILD_DIR"
        return 1
    }

    # 4. Build and install yay
    print_message "blue" "Building and installing yay with makepkg..."
    if makepkg -si --noconfirm; then
        print_message "green" "yay installed successfully! 🎉"
    else
        print_message "red" "Failed to build and install yay with makepkg. Check the output above."
        cd "$HOME"
        rm -rf "$YAY_BUILD_DIR"
        return 1
    fi

    # Cleanup and return to home directory
    cd "$HOME"
    print_message "blue" "Cleaning up temporary yay build directory..."
    rm -rf "$YAY_BUILD_DIR"
}

# Function to install packages using yay
install_packages() {
    print_message "blue" "Starting application installation using yay..."
    
    # Check if yay is available
    if ! command -v yay &> /dev/null; then
        print_message "red" "yay is not installed or not in PATH. Cannot install applications. Skipping."
        return 1
    fi

    # Install all listed applications non-interactively
    print_message "blue" "Installing: ${APPS_TO_INSTALL[*]}"
    yay -S --noconfirm "${APPS_TO_INSTALL[@]}" || {
        print_message "red" "One or more packages failed to install via yay. Check the output above."
        return 1
    }

    print_message "green" "All packages successfully submitted for installation."
    
    # Quick check for core installed apps
    for app in "${CORE_APPS_TO_CHECK[@]}"; do
        if command -v "$app" &> /dev/null; then
            print_message "green" "$app is installed."
        else
            print_message "yellow" "$app may not have installed correctly. Please check."
        fi
    done
}

# Function to switch the default shell to fish
switch_shell() {
    print_message "blue" "Attempting to switch default shell to fish."
    if ! command -v fish &> /dev/null; then
        print_message "red" "fish is not installed or not in PATH. Skipping shell switch."
        return 1
    fi

    local fish_path
    fish_path=$(command -v fish)

    if [ "$SHELL" = "$fish_path" ]; then
        print_message "yellow" "Default shell is already set to $fish_path. Skipping."
        return 0
    fi

    # Add fish to /etc/shells if it's not already there (sudo required)
    if ! grep -q "$fish_path" /etc/shells; then
        print_message "blue" "Adding $fish_path to /etc/shells..."
        echo "$fish_path" | sudo tee -a /etc/shells > /dev/null
    fi

    # Change the default shell for the current user
    if chsh -s "$fish_path"; then
        print_message "green" "Successfully switched default shell to $fish_path."
        print_message "yellow" "NOTE: You must log out and back in for this change to take effect."
    else
        print_message "red" "Failed to switch default shell using chsh. Manual intervention may be required."
        return 1
    fi
}

# --- Main Script ---

# Navigate to the home directory
cd "$HOME" || exit 1

print_message "blue" "Starting full system and dotfiles setup..."
echo

# 1. Package Installation and System Configuration
# ---------------------------------------------------------------------
print_message "blue" "SECTION 1: Package Installation and System Configuration"
install_yay
install_packages
switch_shell
echo
print_message "green" "--- Section 1 Complete ---"
echo

# 2. Clone the dotfiles repository if it doesn't exist
# ---------------------------------------------------------------------
print_message "blue" "SECTION 2: Dotfiles Cloning"
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
echo
print_message "green" "--- Section 2 Complete ---"
echo

# 3. Create backup and config directories and Symlinking
# ---------------------------------------------------------------------
print_message "blue" "SECTION 3: Backup and Symlinking"
print_message "blue" "Creating backup directory at $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
mkdir -p "$CONFIG_DIR"

# 4. Backup existing configs and create symlinks
for config in "${CONFIGS_TO_LINK[@]}"; do
    source_path="$DOTFILES_DIR/$config"
    target_path="$CONFIG_DIR/$config"

    print_message "blue" "Processing '$config' configuration..."

    if [ ! -d "$source_path" ]; then
        print_message "yellow" "Source directory '$source_path' not found in dotfiles repo. Skipping."
        continue
    fi

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        print_message "yellow" "Existing configuration found at '$target_path'. Backing it up."
        if mv "$target_path" "$BACKUP_DIR/"; then
            print_message "green" "Backup of '$config' created in $BACKUP_DIR"
        else
            print_message "red" "Failed to back up '$config'. Skipping symlink creation."
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
print_message "green" "--- Section 3 Complete ---"
echo

# 5. Final Message
# ---------------------------------------------------------------------
print_message "green" "------------------------------------------------"
print_message "green" "FULL SETUP COMPLETE! 🎉"
print_message "yellow" "Original configurations (if any) are backed up in: $BACKUP_DIR"
print_message "red" "🚨 IMPORTANT: You MUST log out and log back in for the new **fish** shell and font settings to take full effect."