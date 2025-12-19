#!/usr/bin/env bash
# =============================================================================
# Script: arch-kde.sh
# Purpose: Bootstrap a clean Arch system + install an operator-focused KDE Plasma
# Model: Frontend workstation (SSH, Emacs, terminals) — backend is headless
# Safe to re-run. No disk or bootloader changes.
# =============================================================================

set -euo pipefail

say()  { printf "\n\033[1m▶ %s\033[0m\n" "$*"; }
ok()   { printf "   ✓ %s\n" "$*"; }
warn() { printf "\033[33m   ! %s\033[0m\n" "$*"; }
die()  { printf "\033[31m   ✗ %s\033[0m\n" "$*"; exit 1; }

# ---- Preflight ---------------------------------------------------------------
if ! command -v sudo >/dev/null 2>&1; then
  if [[ $EUID -ne 0 ]]; then
    die "This script requires sudo or root."
  fi
  SUDO=""
else
  SUDO="sudo"
fi

# ---- 1) Pacman sanity --------------------------------------------------------
say "Refreshing system and ensuring pacman sanity…"

$SUDO pacman -Syu --noconfirm || true

# Keyring (fresh installs)
if ! $SUDO pacman-key --list-keys >/dev/null 2>&1; then
  say "Initializing pacman keyring…"
  $SUDO pacman-key --init
  $SUDO pacman-key --populate archlinux
fi

# Mirrors (if needed)
$SUDO pacman -S --needed --noconfirm reflector
$SUDO reflector --latest 10 --protocol https --sort rate \
  --save /etc/pacman.d/mirrorlist
$SUDO pacman -Syu --noconfirm

ok "Pacman ready."

# ---- 2) Base system services -------------------------------------------------
say "Installing base system services…"

BASE_PKGS=(
  sudo
  networkmanager
  openssh
  git
)

$SUDO pacman -S --needed --noconfirm "${BASE_PKGS[@]}"
$SUDO systemctl enable --now NetworkManager
ok "Base services installed."

# ---- 3) Core CLI / operator tools -------------------------------------------
say "Installing core CLI + operator tools…"

CORE_PKGS=(
  tmux
  wezterm
  emacs
  neovim
  yazi
  lazygit

  btop
  ripgrep
  fd
  bat
  fzf
  jq
  cmake

  ffmpegthumbnailer
  poppler
  imagemagick
  mediainfo

  p7zip
  tar

  ipython
  glow
  git-delta

  links
  w3m

  obs-studio
  vlc
  qbittorrent
)

$SUDO pacman -S --needed --noconfirm "${CORE_PKGS[@]}"
ok "Core tools installed."

# ---- 4) Audio stack (PipeWire) -----------------------------------------------
say "Installing PipeWire audio stack…"

AUDIO_PKGS=(
  pipewire
  pipewire-alsa
  pipewire-pulse
  wireplumber
  pavucontrol
)

$SUDO pacman -S --needed --noconfirm "${AUDIO_PKGS[@]}"
ok "Audio stack ready."

# ---- 5) Bluetooth (system-level only) ---------------------------------------
say "Installing Bluetooth stack…"

BT_PKGS=(
  bluez
  bluez-utils
)

$SUDO pacman -S --needed --noconfirm "${BT_PKGS[@]}"
$SUDO systemctl enable --now bluetooth || true
$SUDO rfkill unblock bluetooth || true

ok "Bluetooth base configured."

# ---- 6) KDE Plasma (tailored, minimal) --------------------------------------
say "Installing KDE Plasma (operator-focused)…"

KDE_PKGS=(
  plasma-desktop
  plasma-wayland-session

  kde-system-meta
  kde-utilities-meta

  xdg-desktop-portal
  xdg-desktop-portal-kde

  bluedevil
  powerdevil
  kdeconnect

  dolphin
  konsole
  ark
  kcalc
)

$SUDO pacman -S --needed --noconfirm "${KDE_PKGS[@]}"
ok "KDE Plasma installed."

# ---- 7) Fonts ----------------------------------------------------------------
say "Installing fonts…"

FONT_PKGS=(
  ttf-jetbrains-mono-nerd
  noto-fonts
  noto-fonts-emoji
)

$SUDO pacman -S --needed --noconfirm "${FONT_PKGS[@]}"
ok "Fonts installed."

# ---- 8) Browsers -------------------------------------------------------------
say "Installing browsers…"

BROWSER_PKGS=(
  firefox-esr
  falkon
)

$SUDO pacman -S --needed --noconfirm "${BROWSER_PKGS[@]}"
ok "Browsers installed."

# ---- 9) Doom Emacs (optional, non-destructive) -------------------------------
say "Installing Doom Emacs (optional)…"

if [[ ! -d "$HOME/.emacs.d/.git" ]]; then
  git clone --depth 1 https://github.com/doomemacs/doomemacs "$HOME/.emacs.d"
  "$HOME/.emacs.d/bin/doom" install --no-config --no-env
  ok "Doom Emacs installed."
else
  ok "Doom Emacs already present; skipping."
fi

# ---- Final -------------------------------------------------------------------
say "Bootstrap complete."

echo
echo "Next steps:"
echo "  1) Reboot"
echo "  2) Select: Plasma (Wayland)"
echo "  3) Configure KWin shortcuts, window rules, and workspaces"
echo

ok "System ready for daily use."
