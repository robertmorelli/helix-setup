
#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
os="$(uname -s | tr '[:upper:]' '[:lower:]')"

# ----------------------------
# Helpers
# ----------------------------
backup_existing() {
  local p="$1"
  if [[ -e "$p" || -L "$p" ]]; then
    mv "$p" "$p.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || rm -rf "$p"
  fi
}

sync_path() {
  local src="$1" dst="$2"
  backup_existing "$dst"
  cp -R "$src" "$dst"
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
# Install Helix (best effort)
# ----------------------------
install_helix() {
  command -v hx >/dev/null 2>&1 && return 0
  case "$os" in
    darwin)
      command -v brew >/dev/null 2>&1 && brew install helix || true
      ;;
    linux)
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y helix || true
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y helix || true
      elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm helix || true
      fi
      ;;
  esac
}
install_helix || true

# ----------------------------
# Helix sync (repo -> config)
# ----------------------------
HX_DST="$(hx_config_dir)"
mkdir -p "$HX_DST"
[[ -f "$REPO_DIR/helix/config.toml" ]] \
  && sync_path "$REPO_DIR/helix/config.toml" "$HX_DST/config.toml"
[[ -f "$REPO_DIR/helix/languages.toml" ]] \
  && sync_path "$REPO_DIR/helix/languages.toml" "$HX_DST/languages.toml"
[[ -d "$REPO_DIR/helix/themes" ]] \
  && sync_path "$REPO_DIR/helix/themes" "$HX_DST/themes"

# ----------------------------
# Ghostty sync (repo -> config)
# ----------------------------
GHOSTTY_DST="$(ghostty_config_dir)"
mkdir -p "$GHOSTTY_DST"
[[ -f "$REPO_DIR/ghostty/config" ]] \
  && sync_path "$REPO_DIR/ghostty/config" "$GHOSTTY_DST/config"
[[ -d "$REPO_DIR/ghostty/themes" ]] \
  && sync_path "$REPO_DIR/ghostty/themes" "$GHOSTTY_DST/themes"

echo "Deployed configs from repo to system"
