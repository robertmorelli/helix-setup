#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DST_DIR="$REPO_DIR/helix"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"

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

SRC_DIR="$(hx_config_dir)"

mkdir -p "$DST_DIR"

copy_if_exists() {
  local src="$1" dst="$2"
  [[ -e "$src" ]] || return 0
  rm -rf "$dst"
  cp -R "$src" "$dst"
}

copy_if_exists "$SRC_DIR/config.toml"    "$DST_DIR/config.toml"
copy_if_exists "$SRC_DIR/languages.toml" "$DST_DIR/languages.toml"
copy_if_exists "$SRC_DIR/themes"         "$DST_DIR/themes"

echo "Saved Helix config from:"
echo "  $SRC_DIR"
echo "Into repo:"
echo "  $DST_DIR"
