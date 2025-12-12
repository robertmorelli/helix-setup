#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$REPO_DIR/helix"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"

# Decide Helix config dir per OS
hx_config_dir() {
  case "$os" in
    darwin) echo "${XDG_CONFIG_HOME:-$HOME/.config}/helix" ;;
    linux)  echo "${XDG_CONFIG_HOME:-$HOME/.config}/helix" ;;
    msys*|mingw*|cygwin*)
      # Git Bash / MSYS: prefer Windows USERPROFILE if present
      local home_win="${USERPROFILE:-$HOME}"
      echo "${XDG_CONFIG_HOME:-$home_win/.config}/helix"
      ;;
    *)
      echo "${XDG_CONFIG_HOME:-$HOME/.config}/helix"
      ;;
  esac
}

CONFIG_DIR="$(hx_config_dir)"
mkdir -p "$CONFIG_DIR"

# Install Helix (best-effort). You can comment out what you don't want.
install_helix() {
  if command -v hx >/dev/null 2>&1; then
    echo "hx already present: $(hx --version 2>/dev/null || true)"
    return 0
  fi

  echo "hx not found. Trying to install..."
  case "$os" in
    darwin)
      if command -v brew >/dev/null 2>&1; then
        brew install helix
      else
        echo "Homebrew not found. Install brew or install helix manually."
        return 1
      fi
      ;;
    linux)
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y helix
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y helix || true
        # Fedora sometimes lags; you may prefer manual install for latest.
      elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm helix
      elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y helix
      else
        echo "No known package manager found. Install helix manually."
        return 1
      fi
      ;;
    msys*|mingw*|cygwin*)
      echo "Windows shell detected. Recommend installing Helix via winget or scoop:"
      echo "  winget install Helix.Helix"
      echo "  scoop install helix"
      return 1
      ;;
    *)
      echo "Unknown OS: $os. Install helix manually."
      return 1
      ;;
  esac
}

# Choose copy vs symlink (symlink preferred for editing-in-repo)
LINK_MODE="${LINK_MODE:-symlink}"  # set LINK_MODE=copy to copy files instead
backup_existing() {
  local p="$1"
  if [[ -e "$p" && ! -L "$p" ]]; then
    local ts; ts="$(date +%Y%m%d-%H%M%S)"
    mv "$p" "$p.bak.$ts"
  fi
}

sync_path() {
  local src="$1" dst="$2"

  backup_existing "$dst"
  rm -rf "$dst" 2>/dev/null || true

  if [[ "$LINK_MODE" == "copy" ]]; then
    if [[ -d "$src" ]]; then
      cp -R "$src" "$dst"
    else
      cp "$src" "$dst"
    fi
  else
    ln -s "$src" "$dst"
  fi
}

install_helix || true

# Sync config and themes
[[ -f "$SRC_DIR/config.toml" ]]      && sync_path "$SRC_DIR/config.toml"      "$CONFIG_DIR/config.toml"
[[ -f "$SRC_DIR/languages.toml" ]]   && sync_path "$SRC_DIR/languages.toml"   "$CONFIG_DIR/languages.toml"
[[ -d "$SRC_DIR/themes" ]]           && sync_path "$SRC_DIR/themes"           "$CONFIG_DIR/themes"

echo "Helix config installed to: $CONFIG_DIR"
echo "Mode: $LINK_MODE (set LINK_MODE=copy to copy instead of symlink)"
