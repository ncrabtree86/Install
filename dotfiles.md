
---

# `~/.bashrc`  *(replace or append to your existing file)*

```bash
#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Colors for common tools
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Prompt
PS1='[\u@\h \W]\$ '

# — Optional: replace old jot with Taskwarrior-backed quick-capture —
# Uncomment to use:
# jot(){ task add +inbox "$*"; echo "added to taskwarrior inbox: $*"; }
```

---

# `~/.config/fish/config.fish`

```fish
# Use CachyOS defaults, then add your tweaks
source /usr/share/cachyos-fish-config/cachyos-config.fish

# Personal settings
set -x neovim
set -x neovim 

# Optional: Taskwarrior-based quick capture (fish)
# function jot
#     task add +inbox $argv
#     echo "added to taskwarrior inbox: $argv"
# end
```

---

# `~/.config/helix/config.toml`

```toml
theme = "material_deep_ocean"

[editor]
line-number = "absolute"
cursorline = true
bufferline = "always"
color-modes = true
```

---

# `~/.config/sway/config`

```ini
# ==================================================================
# Sway configuration
# ==================================================================

### Variables
set $mod Mod4
set $left h
set $down j
set $up   k
set $right l
set $term kitty
# (Optional)
# set $browser brave
```

---

# `~/.config/waybar/style.css`

```css
* {
  font-family: "JetBrainsMono Nerd Font", "FiraCode Nerd Font", "Symbols Nerd Font", monospace;
  font-size: 12.5px;
}
window#waybar {
  background: rgba(30,30,30,0.9);
  color: #eaeaea;
  border-bottom: 1px solid #444;
}
#workspaces button { padding: 0 6px; margin: 0 2px; border-radius: 6px; }
#workspaces button.focused { background: #4c566a; color: #fff; }
#clock, #cpu, #memory, #network, #pulseaudio, #battery, #tray { padding: 0 9px; }
```

---

## How to apply (quick):

```bash
# Create folders (run on the new machine)
mkdir -p ~/.config/{fish,helix,sway,waybar}

# Paste each block into its file path above.
# Then reload:
source ~/.bashrc            # bash
# start a new fish session  # fish
# reload Sway (Mod+Shift+c) # sway
```

Want me to drop this into a ready-to-commit `dotfiles-min/` folder with these five files laid out, plus a tiny `install.sh`?
