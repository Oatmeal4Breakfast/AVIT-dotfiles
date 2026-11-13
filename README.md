# My Dotfiles

Personal configuration files for macOS development environment.

## What's Included

- **Zsh** - Shell configuration with Starship prompt
- **Tmux** - Terminal multiplexer for session management
- **Ghostty** - Fast, modern terminal emulator
- **Rex** - Terminal multiplexer configuration
- **Neovim** - LazyVim configuration
- **Starship** - Cross-shell prompt
- **aerospace** - i3 style window manager

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/Oatmeal4Breakfast/AVIT-dotfiles/main/install_script.sh | bash
```

## Already installed?

Configs are linked with [GNU Stow](https://www.gnu.org/software/stow/), one
package per app. If an older version of the installer created your symlinks,
run the one-time migration first:

```bash
cd ~/dotfiles
./migrate-to-stow.sh                             # dry run, shows what changes
./migrate-to-stow.sh --apply --prune-backups     # remove the old links
./install_script.sh                              # re-link with stow
```
