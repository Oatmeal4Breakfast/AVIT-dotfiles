#!/bin/zsh

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
LOGFILE="$HOME/Library/Logs/brew-maintenance.log"
BREW="/opt/homebrew/bin/brew"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

log() {
  echo "[$TIMESTAMP] $1" | tee -a "$LOGFILE"
}

log "=== Brew maintenance started ==="

# Update Homebrew and upgrade all packages
log "Running brew update..."
$BREW update >> "$LOGFILE" 2>&1

log "Running brew upgrade..."
$BREW upgrade >> "$LOGFILE" 2>&1

# Dump current Brewfile
log "Dumping Brewfile to $DOTFILES_DIR..."
cd "$DOTFILES_DIR"

# Sync with remote first so a stale clone can't clobber or fail on push
SKIP_PUSH=0
log "Syncing dotfiles with remote..."
if git -C "$DOTFILES_DIR" pull --rebase --autostash >> "$LOGFILE" 2>&1; then
  log "Sync complete."
else
  log "WARNING: git pull --rebase failed. Dumping Brewfile but skipping commit/push this run."
  SKIP_PUSH=1
fi

$BREW bundle dump --force --file="$DOTFILES_DIR/Brewfile" >> "$LOGFILE" 2>&1

# Commit and push if there are changes
if [ "$SKIP_PUSH" -eq 1 ]; then
  log "Skipping commit/push due to failed sync."
elif git -C "$DOTFILES_DIR" diff --quiet -- Brewfile; then
  log "No changes to Brewfile. Skipping commit."
elif [ "$(git -C "$DOTFILES_DIR" rev-parse --abbrev-ref HEAD)" = "HEAD" ]; then
  log "WARNING: detached HEAD. Skipping commit/push."
else
  log "Brewfile changed. Committing and pushing..."
  git -C "$DOTFILES_DIR" add Brewfile
  git -C "$DOTFILES_DIR" commit -m "chore: update Brewfile ($(date '+%Y-%m-%d'))" >> "$LOGFILE" 2>&1
  if git -C "$DOTFILES_DIR" push >> "$LOGFILE" 2>&1; then
    log "Changes pushed successfully."
  else
    log "WARNING: git push failed. Leaving commit locally for next run."
  fi
fi

# Cleanup
log "Running brew cleanup..."
$BREW cleanup >> "$LOGFILE" 2>&1

log "=== Brew maintenance completed ==="
