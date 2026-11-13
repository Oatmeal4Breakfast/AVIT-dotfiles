#!/bin/bash
# migrate-to-stow.sh - one-time cleanup for links made by the old installer.
#
# The previous install script created absolute symlinks (and occasionally a
# relative one) plus a couple of whole-directory symlinks. GNU Stow refuses
# to adopt links it did not create, so they have to be removed before the
# new installer can run.
#
# Dry-run by default. Nothing is removed until --apply is passed.
#
# Usage: ./migrate-to-stow.sh [--apply] [--prune-backups] [--dotfiles DIR]

set -uo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
APPLY=0
PRUNE_BACKUPS=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

FOLD_PACKAGES=(zsh tmux git aerospace starship ghostty nvim ssh)
UNFOLD_PACKAGES=(opencode rex)

usage() {
  cat <<'EOF'
Usage: migrate-to-stow.sh [options]

Remove symlinks created by the pre-stow install script so GNU Stow can own
the config paths. Dry-run by default; nothing is removed until --apply.
Safe to run again: links stow already owns are left alone.

Options:
  --apply          actually remove the legacy links
  --prune-backups  also remove stale *.backup.* symlinks that point into the
                   dotfiles repo (only does anything with --apply)
  --dotfiles DIR   dotfiles checkout to compare against (default: ~/dotfiles)
  -h, --help       show this help

After --apply, run install_script.sh (or the stow commands printed at the
end) to recreate the links with stow.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --prune-backups) PRUNE_BACKUPS=1 ;;
    --dotfiles)
      shift
      if [ $# -eq 0 ] || [ -z "$1" ]; then
        echo "error: --dotfiles needs a directory" >&2
        exit 2
      fi
      DOTFILES_DIR="$1"
      ;;
    --dotfiles=*)
      DOTFILES_DIR="${1#*=}"
      if [ -z "$DOTFILES_DIR" ]; then
        echo "error: --dotfiles needs a directory" >&2
        exit 2
      fi
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

DOTFILES_DIR="${DOTFILES_DIR%/}"

if [ ! -d "$DOTFILES_DIR/.git" ]; then
  echo -e "${RED}error: $DOTFILES_DIR is not a dotfiles checkout${NC}" >&2
  exit 1
fi

REPO_REAL="$(cd "$DOTFILES_DIR" && pwd -P)"
REPO_BASE="$(basename "$REPO_REAL")"

# Legacy targets and shapes produced by the old install_script.sh.
LEGACY_LINKS=(
  "$HOME/.zshrc"
  "$HOME/.tmux.conf"
  "$HOME/.gitconfig"
  "$HOME/.aerospace.toml"
  "$HOME/.config/ghostty"
  "$HOME/.config/ghostty/config"
  "$HOME/.config/starship.toml"
  "$HOME/.config/nvim"
  "$HOME/.config/opencode"
  "$HOME/.config/rex"
  "$HOME/.ssh/allowed_signers"
  "$HOME/.ssh/config"
)

# True when a symlink (valid or dangling) points somewhere inside the repo.
# realpath() handles valid links of either kind; the textual fallbacks cover
# links whose old target no longer exists after the repo was restructured.
points_into_repo() {
  local link="$1" raw resolved
  raw="$(readlink "$link" 2>/dev/null)" || return 1

  case "$raw" in
    "$REPO_REAL" | "$REPO_REAL"/*) return 0 ;;
    "$DOTFILES_DIR" | "$DOTFILES_DIR"/*) return 0 ;;
  esac

  resolved="$(realpath "$link" 2>/dev/null || true)"
  case "$resolved" in
    "$REPO_REAL" | "$REPO_REAL"/*) return 0 ;;
  esac

  case "$raw" in
    "$REPO_BASE" | "$REPO_BASE"/*) return 0 ;;
    "../$REPO_BASE" | "../$REPO_BASE"/*) return 0 ;;
    "../../$REPO_BASE" | "../../$REPO_BASE"/*) return 0 ;;
  esac

  return 1
}

show_path() {
  printf '%s' "${1/#$HOME/~}"
}

# A link is only removed when it is legacy, never when stow already owns it.
# The old installer wrote absolute links; stow writes relative ones. So:
#   - absolute link into the repo  -> legacy, remove
#   - relative link that resolves  -> already correct (stow's), leave it
#   - relative link that dangles   -> legacy, remove
should_remove_link() {
  local link="$1"
  points_into_repo "$link" || return 1

  case "$(readlink "$link")" in
    /*) return 0 ;;
  esac

  [ -e "$link" ] && return 1
  return 0
}

removed=0
skipped=0
missing=0

echo "Dotfiles repo: $REPO_REAL"
if [ "$APPLY" -eq 1 ]; then
  echo "Mode: apply"
else
  echo "Mode: dry run (re-run with --apply to remove)"
fi
echo
echo "== Legacy links"

for link in "${LEGACY_LINKS[@]}"; do
  if [ ! -e "$link" ] && [ ! -L "$link" ]; then
    missing=$((missing + 1))
    continue
  fi

  if [ ! -L "$link" ]; then
    echo -e "${YELLOW}SKIP${NC}    $(show_path "$link") (not a symlink)"
    skipped=$((skipped + 1))
    continue
  fi

  if ! should_remove_link "$link"; then
    echo -e "${YELLOW}SKIP${NC}    $(show_path "$link") -> $(readlink "$link") (not a legacy link)"
    skipped=$((skipped + 1))
    continue
  fi

  if [ "$APPLY" -eq 1 ]; then
    if rm "$link"; then
      echo -e "${GREEN}REMOVED${NC} $(show_path "$link")"
      removed=$((removed + 1))
    else
      echo -e "${RED}FAILED${NC}  $(show_path "$link")" >&2
      skipped=$((skipped + 1))
    fi
  else
    echo "WOULD REMOVE  $(show_path "$link") -> $(readlink "$link")"
    removed=$((removed + 1))
  fi
done

backups=0
if [ "$PRUNE_BACKUPS" -eq 1 ]; then
  echo
  echo "== Stale backup links"
  while IFS= read -r link; do
    [ -n "$link" ] || continue
    if ! points_into_repo "$link"; then
      continue
    fi

    if [ "$APPLY" -eq 1 ]; then
      if rm "$link"; then
        echo -e "${GREEN}REMOVED${NC} $(show_path "$link")"
        backups=$((backups + 1))
      fi
    else
      echo "WOULD REMOVE  $(show_path "$link") -> $(readlink "$link")"
      backups=$((backups + 1))
    fi
  done < <(find "$HOME" -maxdepth 2 -name '*.backup.*' -type l -not -path "$REPO_REAL/*" 2>/dev/null)
fi

echo
echo "== Summary"
echo "  links:   $removed"
echo "  backups: $backups"
echo "  skipped: $skipped (left untouched)"

if [ "$removed" -eq 0 ] && [ "$backups" -eq 0 ]; then
  echo
  echo -e "${GREEN}Nothing to clean up.${NC} This machine already uses stow, or has no legacy links."
  exit 0
fi

if [ "$APPLY" -eq 0 ]; then
  echo
  echo -e "${YELLOW}Dry run: nothing changed.${NC} Re-run with --apply to remove these links."
  exit 0
fi

echo
echo "== Next: recreate the links with stow"
echo "  cd $(show_path "$REPO_REAL")"
echo "  stow --target \"\$HOME\" -R --ignore='\\.DS_Store' ${FOLD_PACKAGES[*]}"
echo "  stow --target \"\$HOME\" -R --no-folding --ignore='\\.DS_Store' ${UNFOLD_PACKAGES[*]}"
echo
echo "Or just run ./install_script.sh."

if ! command -v stow >/dev/null 2>&1; then
  echo
  echo "stow is not installed; skipping the verification pass."
  exit 0
fi

echo
echo "== Verifying (stow dry run)"
if stow -n --target "$HOME" --ignore='\.DS_Store' "${FOLD_PACKAGES[@]}" >/dev/null 2>&1 &&
  stow -n --target "$HOME" --no-folding --ignore='\.DS_Store' "${UNFOLD_PACKAGES[@]}" >/dev/null 2>&1; then
  echo -e "${GREEN}OK:${NC} no conflicts remain; stow can own every path."
  exit 0
fi

stow -n -v --target "$HOME" --ignore='\.DS_Store' "${FOLD_PACKAGES[@]}" 2>&1 | sed 's/^/  /'
stow -n -v --target "$HOME" --no-folding --ignore='\.DS_Store' "${UNFOLD_PACKAGES[@]}" 2>&1 | sed 's/^/  /'
echo
echo -e "${RED}Conflicts remain.${NC} Resolve the paths above, then re-run this script."
exit 1
