#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
os="$(uname -s | tr '[:upper:]' '[:lower:]')"

# ----------------------------
# Helpers
# ----------------------------
copy_if_exists() {
  local src="$1" dst="$2"
  [[ -e "$src" ]] || return 0
  # Remove destination first (handles symlinks)
  rm -rf "$dst"
  # Copy actual file contents, dereferencing symlinks
  cp -RfL "$src" "$dst"
}

# ----------------------------
# Helix paths
# ----------------------------
hx_config_dir() {
  case "$os" in
    darwin|linux)
      echo "${XDG_CONFIG_HOME:-$HOME/.config}/helix"
      ;;
    msys*|mingw*|cygwin*)
      local home_win="${USERPROFILE:-$HOME}"
      echo "${XDG_CONFIG_HOME:-$home_win/.config}/helix"
      ;;
    *)
      echo "${XDG_CONFIG_HOME:-$HOME/.config}/helix"
      ;;
  esac
}

# ----------------------------
# Ghostty paths
# ----------------------------
ghostty_config_dir() {
  case "$os" in
    darwin|linux)
      echo "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
      ;;
    msys*|mingw*|cygwin*)
      local base="${APPDATA:-${USERPROFILE:-$HOME}/AppData/Roaming}"
      echo "$base/ghostty"
      ;;
    *)
      echo "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
      ;;
  esac
}

# ----------------------------
# Clean existing symlinks in repo
# ----------------------------
rm -f "$REPO_DIR/helix/config.toml" 2>/dev/null || true
rm -f "$REPO_DIR/helix/languages.toml" 2>/dev/null || true
rm -rf "$REPO_DIR/helix/themes" 2>/dev/null || true

# ----------------------------
# Save Helix
# ----------------------------
HX_SRC="$(hx_config_dir)"
mkdir -p "$REPO_DIR/helix"
copy_if_exists "$HX_SRC/config.toml"    "$REPO_DIR/helix/config.toml"
copy_if_exists "$HX_SRC/languages.toml" "$REPO_DIR/helix/languages.toml"
copy_if_exists "$HX_SRC/themes"         "$REPO_DIR/helix/themes"

# ----------------------------
# Save Ghostty
# ----------------------------
GHOSTTY_SRC="$(ghostty_config_dir)"
mkdir -p "$REPO_DIR/ghostty"
copy_if_exists "$GHOSTTY_SRC/config" "$REPO_DIR/ghostty/config"
copy_if_exists "$GHOSTTY_SRC/themes" "$REPO_DIR/ghostty/themes"

echo "Saved Helix + Ghostty configs into repo"
