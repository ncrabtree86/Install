#!/usr/bin/env bash
# =============================================================================
# Script: Arch-install.sh
# Purpose: install core tools, set up Brave, Sway/Wayland plumbing,
# Bluetooth stack, Doom Emacs, and basic desktop utilities.
# Safe to re-run. Every package is annotated for clarity.
# =============================================================================

set -euo pipefail

say() { printf "\n\033[1m▶ %s\033[0m\n" "$*"; }
ok()  { printf "   ✓ %s\n" "$*"; }
warn(){ printf "\033[33m   ! %s\033[0m\n" "$*"; }
die(){ printf "\033[31m   ✗ %s\033[0m\n" "$*"; exit 1; }

# ---- 0) Preflight: sudo or root ---------------------------------------------
if ! command -v sudo >/dev/null 2>&1; then
  if [[ $EUID -ne 0 ]]; then
    die "This script needs sudo or root. Re-run with sudo or as root."
  fi
  SUDO=""
else
  SUDO="sudo"
fi

# ---- 0.5) Detect session type (Wayland/X11) ---------------------------------
SESSION_TYPE="${XDG_SESSION_TYPE:-}"
if [[ -z "$SESSION_TYPE" ]]; then
  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    SESSION_TYPE="wayland"
  else
    SESSION_TYPE="x11"
  fi
fi
ok "Session detected: $SESSION_TYPE"

# ---- 1) System refresh -------------------------------------------------------
say "Syncing package databases and upgrading system (pacman -Syu)…"
$SUDO pacman -Syu --noconfirm
ok "System up to date."

# ---- 2) Base system services -------------------------------------------------
say "Installing base system services…"
BASE_PKGS=(
  networkmanager   # Network connection manager (Wi-Fi, Ethernet, VPNs)
  openssh          # SSH client/server
  sudo             # Privilege escalation
)

$SUDO pacman -S --needed --noconfirm "${BASE_PKGS[@]}"
$SUDO systemctl enable --now NetworkManager
ok "Base system ready."

# ---- 3) Core CLI + TUI tools -------------------------------------------------
say "Installing core CLI + TUI tools…"
CORE_PKGS=(
  wezterm            # GPU-accelerated terminal (Wayland-native)
  yazi               # Modern TUI file manager
  lazygit            # Git TUI interface
  neovim             # Fast minimal editor
  emacs              # Full editor (Doom Emacs base)
  fish               # Modern sh
  
  btop               # System monitor (CPU/RAM/Disk/Net)
  ripgrep            # Fast recursive search
  fd                 # Modern `find` replacement
  bat                # Better `cat` with syntax highlighting
  fzf                # Fuzzy finder
  git                # Version control

  ffmpegthumbnailer  # Thumbnails in file pickers
  poppler            # PDF tools for previews
  imagemagick        # Image manipulation
  mediainfo          # Video/audio metadata
  jq                 # JSON processing

  udisks2            # System disk management backend
  udiskie            # USB mount helper for Sway (manual approval)
  wl-clipboard       # Wayland clipboard tools
  brightnessctl      # Laptop/monitor brightness controller

  ipython            # Better Python REPL
  waybar             # Sway’s status bar

  pipewire           # Audio server
  pipewire-alsa      # ALSA compatibility
  pipewire-pulse     # PulseAudio compatibility layer
  wireplumber        # PipeWire session manager

  links              # CLI web browser
  w3m                # CLI browser + image preview in terminals
  tmux               # Terminal multiplexer
  glow               # Markdown viewer
  git-delta          # Git diff viewer
  clipman            # Wayland clipboard manager
  cmake              # Build tool

  obs-studio         # Screen recording / streaming
  vlc                # Media player

  p7zip              # 7-zip archives
  tar                # Tape ARchive
  qbittorrent        # full-featured BitTorrent client
)

$SUDO pacman -S --needed --noconfirm "${CORE_PKGS[@]}"
ok "Core tools installed."

# ---- 4) Wayland screenshot tools --------------------------------------------
if [[ "$SESSION_TYPE" == "wayland" ]]; then
  say "Installing Wayland screenshot tools…"
  WAYLAND_SHOT_PKGS=(
    grim              # Wayland screenshot tool
    slurp             # Region selector
  )
  $SUDO pacman -S --needed --noconfirm "${WAYLAND_SHOT_PKGS[@]}"
fi

# ---- 5) Doom Emacs (optional) ------------------------------------------------
say "Installing Doom Emacs (optional)…"
if [[ ! -d "$HOME/.emacs.d/.git" ]]; then
  git clone --depth 1 https://github.com/doomemacs/doomemacs "$HOME/.emacs.d"
  "$HOME/.emacs.d/bin/doom" install --no-config --no-env
  ok "Doom Emacs installed."
else
  ok "Doom Emacs already installed; skipping."
fi

# ---- 6) Wayland/Sway portals -------------------------------------------------
if [[ "$SESSION_TYPE" == "wayland" ]]; then
  say "Installing portals for Sway…"
  PORTAL_PKGS=(
    xdg-desktop-portal       # Main XDG portal daemon
    xdg-desktop-portal-wlr   # wlroots backend (required for Sway)
  )
  $SUDO pacman -S --needed --noconfirm "${PORTAL_PKGS[@]}"

  # Remove conflicting GTK/GNOME portals
  $SUDO pacman -Rns --noconfirm \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-kde || true

  TARGET="${SUDO_USER:-$USER}"
  sudo -u "$TARGET" systemctl --user enable --now xdg-desktop-portal.service xdg-desktop-portal-wlr.service
  sudo -u "$TARGET" systemctl --user restart     xdg-desktop-portal.service xdg-desktop-portal-wlr.service

  ok "Sway portals configured."
fi

# ---- 7) Bluetooth stack ------------------------------------------------------
say "Installing Bluetooth stack…"
BT_PKGS=(
  bluez              # Core Bluetooth stack
  bluez-utils        # bluetoothctl and helpers
)

$SUDO pacman -S --needed --noconfirm "${BT_PKGS[@]}"
$SUDO systemctl enable --now bluetooth.service
$SUDO rfkill unblock bluetooth || true

# Auto-enable Bluetooth adapters after boot
if [[ -f /etc/bluetooth/main.conf ]]; then
  if grep -q '^\[Policy\]' /etc/bluetooth/main.conf; then
    $SUDO sed -i 's/^AutoEnable=.*/AutoEnable=true/' /etc/bluetooth/main.conf || true
    grep -q '^AutoEnable=' /etc/bluetooth/main.conf || \
      $SUDO bash -c 'printf "\nAutoEnable=true\n" >> /etc/bluetooth/main.conf'
  else
    $SUDO bash -c 'printf "\n[Policy]\nAutoEnable=true\n" >> /etc/bluetooth/main.conf'
  fi
else
  $SUDO install -D -m 0644 /dev/stdin /etc/bluetooth/main.conf <<'CONF'
[General]
[Policy]
AutoEnable=true
CONF
fi
ok "Bluetooth configured."

# ---- 8) Bluetooth GUI (Blueman) ---------------------------------------------
say "Installing Blueman (optional tray GUI)…"
$SUDO pacman -S --needed --noconfirm blueman

SWAYCONF="$HOME/.config/sway/config"
if [[ -f "$SWAYCONF" ]] && ! grep -q "blueman-applet" "$SWAYCONF"; then
  printf "\n# Bluetooth tray\nexec_always blueman-applet\n" >> "$SWAYCONF"
  ok "Added blueman-applet to Sway config."
else
  ok "Skipping Blueman autostart."
fi

# ---- 9) Optional Bluetooth audio codecs -------------------------------------
say "Installing optional high-quality Bluetooth audio codecs…"
BT_CODEC_PKGS=(
  libldac        # Sony LDAC
  libfreeaptx    # aptX
  openaptx       # aptX HD
  fdk-aac        # AAC encoder
)

$SUDO pacman -S --needed --noconfirm "${BT_CODEC_PKGS[@]}" || true
ok "Codec install complete."

# ---- 10) AUR helper ----------------------------------------------------------
say "Checking/installing AUR helper…"
if command -v yay >/dev/null; then
  AUR="yay"
  ok "Using yay."
elif command -v paru >/dev/null; then
  AUR="paru"
  ok "Using paru."
else
  say "Installing yay…"
  $SUDO pacman -S --needed --noconfirm base-devel git
  workdir="$(mktemp -d)"
  trap 'rm -rf "$workdir"' EXIT
  git -C "$workdir" clone https://aur.archlinux.org/yay-bin.git
  (cd "$workdir/yay-bin" && makepkg -si --noconfirm)
  AUR="yay"
  ok "yay installed."
fi

# ---- 11) AUR packages --------------------------------------------------------
say "Installing AUR packages…"
AUR_PKGS=(
  ueberzugpp                 # Image previews in terminal file managers
  brave-bin                  # Brave browser
  ttf-nerd-fonts-symbols     # Icons for terminal + Waybar
  ttf-jetbrains-mono-nerd    # Developer font
  nwg-displays               # Wayland display GUI for Sway
)

$AUR -S --needed --noconfirm "${AUR_PKGS[@]}"
ok "AUR extras installed."

# ---- 12) Wayland/X11 GUI utilities ------------------------------------------
say "Installing display + audio GUIs…"
if [[ "$SESSION_TYPE" == "wayland" ]]; then
  GUI_PKGS=(
    wdisplays      # Wayland display configurator
    pavucontrol    # Audio control
    wofi           # App launcher
    wlogout        # Logout screen
  )
else
  GUI_PKGS=(
    arandr
    pavucontrol
  )
fi

$SUDO pacman -S --needed --noconfirm "${GUI_PKGS[@]}"

# NetworkManager tray GUI
if $SUDO systemctl is-active NetworkManager >/dev/null; then
  $SUDO pacman -S --needed --noconfirm network-manager-applet
  ok "NetworkManager applet installed."
else
  warn "Skipping network-manager-applet (NetworkManager not active)."
fi

# ---- Final reminders ---------------------------------------------------------
say "Final reminders:"
echo " - NetworkManager is enabled and running."
echo " - Wayland users: use wdisplays for monitor setup."
echo " - Sway users: USB handling is via udiskie + udisks2 (manual approval)."

ok "Bootstrap complete!"
