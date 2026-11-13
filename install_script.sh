#!/bin/bash
# Dotfiles Installation Script
# Usage: curl -fsSL https://raw.githubusercontent.com/Oatmeal4Breakfast/AVIT-dotfiles/main/install_script.sh | bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Dotfiles directory
DOTFILES_DIR="$HOME/dotfiles"
REPO_URL="https://github.com/Oatmeal4Breakfast/AVIT-dotfiles.git"
BREWFILE="$DOTFILES_DIR/Brewfile"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo -e "${RED}This script is designed for macOS${NC}"
  exit 1
fi

# Xcode Command Line Tools are needed for git and Homebrew
if ! xcode-select -p >/dev/null 2>&1; then
  echo -e "${YELLOW}Installing Xcode Command Line Tools...${NC}"
  xcode-select --install
  echo "Re-run this script when the installer finishes."
  exit 0
fi

# Install Homebrew if not installed
if ! command -v brew >/dev/null 2>&1; then
  echo -e "${YELLOW}Installing Homebrew...${NC}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Clone dotfiles repo if not exists
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  echo -e "${YELLOW}Cloning dotfiles repository...${NC}"
  git clone "$REPO_URL" "$DOTFILES_DIR"
else
  echo -e "${GREEN}✓ Dotfiles directory exists${NC}"
  git -C "$DOTFILES_DIR" pull --ff-only || echo -e "${YELLOW}WARNING: could not update dotfiles; continuing.${NC}"
fi

cd "$DOTFILES_DIR"

# Install everything declared in the Brewfile
echo -e "${YELLOW}Installing Homebrew packages from Brewfile...${NC}"
if ! brew bundle --file="$BREWFILE"; then
  echo -e "${YELLOW}WARNING: some Brewfile items failed; continuing with config setup.${NC}"
fi

if ! command -v stow >/dev/null 2>&1; then
  echo -e "${RED}stow is required. Install it with: brew install stow${NC}"
  exit 1
fi

# Install Rex (if not installed); Rex is not available as a Homebrew cask
if [ ! -d "/Applications/Rex Beta.app" ]; then
  echo -e "${YELLOW}Note: Install Rex manually from https://superlogical.com${NC}"
fi

# Remove symlinks created by the old install script so stow can own them.
# Only symlinks pointing into this repo are touched; real files are left alone.
echo -e "${YELLOW}Cleaning up old symlinks...${NC}"
for link in \
  "$HOME/.zshrc" \
  "$HOME/.tmux.conf" \
  "$HOME/.gitconfig" \
  "$HOME/.aerospace.toml" \
  "$HOME/.config/ghostty/config" \
  "$HOME/.config/starship.toml" \
  "$HOME/.ssh/allowed_signers" \
  "$HOME/.ssh/config"; do
  if [ -L "$link" ]; then
    # Resolve first: the old script wrote both absolute and relative links.
    resolved="$(realpath "$link" 2>/dev/null || true)"
    case "$resolved" in
      "$(realpath "$DOTFILES_DIR")" | "$(realpath "$DOTFILES_DIR")"/*) rm "$link" ;;
    esac
  fi
done

# The old script linked the whole nvim directory and the ghostty config file.
# Stow needs real directories for these targets.
for dir in "$HOME/.config/ghostty" "$HOME/.config/nvim"; do
  if [ -L "$dir" ]; then
    rm "$dir"
  fi
done

# Back up real files that would block stow, matching the old script's safety
# net. Symlinks were already removed above, and missing paths are left alone.
backup_conflicts() {
  for target in "$@"; do
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo -e "${YELLOW}Backing up existing $target${NC}"
      mv "$target" "$target.backup.$(date +%Y%m%d_%H%M%S)"
    fi
  done
}

backup_conflicts \
  "$HOME/.zshrc" \
  "$HOME/.tmux.conf" \
  "$HOME/.gitconfig" \
  "$HOME/.aerospace.toml" \
  "$HOME/.config/ghostty/config" \
  "$HOME/.config/starship.toml" \
  "$HOME/.ssh/allowed_signers" \
  "$HOME/.ssh/config"

# A pre-existing real Neovim config would be merged into, so move it aside.
if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ] && [ -n "$(ls -A "$HOME/.config/nvim")" ]; then
  echo -e "${YELLOW}Backing up existing $HOME/.config/nvim${NC}"
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
fi

mkdir -p "$HOME/.config/ghostty" "$HOME/.config/nvim" "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Stow configs. --no-folding keeps runtime files (OpenCode node_modules, Rex
# state, etc.) in ~/.config instead of writing them into the dotfiles repo.
echo -e "${YELLOW}Stowing configs...${NC}"
stow_pkg() {
  local target="$1"
  shift
  if ! stow --no-folding -R -t "$target" "$@"; then
    echo -e "${YELLOW}WARNING: stow failed for $* into $target${NC}"
  fi
}

stow_pkg "$HOME" zsh tmux git aerospace
stow_pkg "$HOME/.config/ghostty" ghostty
stow_pkg "$HOME/.config/nvim" nvim
stow_pkg "$HOME/.config" starship
stow_pkg "$HOME/.ssh" ssh
stow_pkg "$HOME" rex opencode

# Install brew-maintenance LaunchAgent (expands __HOME__ placeholder)
AGENT="$HOME/Library/LaunchAgents/com.elvinsalcedo.brew-maintenance.plist"
if [ -f "$DOTFILES_DIR/com.elvinsalcedo.brew-maintenance.plist" ]; then
  echo -e "${YELLOW}Installing brew-maintenance LaunchAgent...${NC}"
  mkdir -p "$HOME/Library/LaunchAgents"
  # Remove a pre-existing link first: redirecting through it would truncate the
  # template in the repo instead of writing the expanded copy into ~/Library.
  rm -f "$AGENT"
  sed "s|__HOME__|$HOME|g" "$DOTFILES_DIR/com.elvinsalcedo.brew-maintenance.plist" >"$AGENT"
  echo -e "${GREEN}✓ LaunchAgent installed (edit schedule in $AGENT)${NC}"
fi

# Set zsh as default shell
if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
  echo -e "${YELLOW}Setting zsh as default shell...${NC}"
  chsh -s "$(command -v zsh)" || echo -e "${YELLOW}Could not change shell; run 'chsh -s $(command -v zsh)' manually.${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Dotfiles installation complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Open Neovim and let LazyVim install plugins"
echo "2. Restart Rex or Ghostty to pick up the new config"
echo ""

# Drop into a fresh login shell when the script is running in a terminal.
# Checking stdout rather than stdin keeps this working with `curl | bash`.
if [ -t 1 ]; then
  exec zsh -l
fi
