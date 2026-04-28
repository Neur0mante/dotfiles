#!/usr/bin/env bash
set -e

DOTFILES="$HOME/.dotfiles"

log() { printf "\033[1;32m[+] %s\033[0m\n" "$1"; }

# --------------------------
# Detect package manager
# --------------------------
if command -v apt >/dev/null; then
    PM="apt"
elif command -v dnf >/dev/null; then
    PM="dnf"
elif command -v pacman >/dev/null; then
    PM="pacman"
else
    echo "Unsupported distro"
    exit 1
fi

log "Using package manager: $PM"

# --------------------------
# Install packages
# --------------------------
log "Installing packages"

case "$PM" in
    apt)
        sudo apt update
        sudo apt install -y $(<"$DOTFILES/packages/common.txt")
        ;;
    dnf)
        sudo dnf install -y $(<"$DOTFILES/packages/common.txt")
        ;;
    pacman)
        sudo pacman -Sy --noconfirm $(<"$DOTFILES/packages/common.txt")
        ;;
esac

# --------------------------
# Set zsh as default shell
# --------------------------
# if [[ "$SHELL" != "$(command -v zsh)" ]]; then
#     log "Setting zsh as default shell"
#     chsh -s "$(command -v zsh)"
# fi

# --------------------------
# Symlink dotfiles
# --------------------------
log "Linking dotfiles"

ln -sf "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"
# ln -sf "$DOTFILES/zsh/zprofile" "$HOME/.zprofile"
ln -sf "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"

# --------------------------
# Install Oh My Zsh (optional)
# --------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "Installing Oh My Zsh"
    RUNZSH=no CHSH=no \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# --------------------------
# Install tmux plugin manager
# --------------------------
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    log "Installing tmux plugin manager"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

log "Bootstrap completed. Restart your shell."
