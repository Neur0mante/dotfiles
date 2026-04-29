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
# broot (better repo on Debian/Ubuntu)
# --------------------------
if [[ "$PM" == "apt" ]]; then
    if ! apt-cache policy | grep -q packages.azlux.fr; then
        log "Adding Azlux repository for broot"
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://packages.azlux.fr/key.gpg \
          | sudo gpg --dearmor -o /etc/apt/keyrings/azlux.gpg

        echo \
"deb [signed-by=/etc/apt/keyrings/azlux.gpg] https://packages.azlux.fr/also stable main" \
          | sudo tee /etc/apt/sources.list.d/azlux.list > /dev/null

        sudo apt update
    fi

    sudo apt install -y broot
fi

case "$PM" in
    dnf)
        sudo dnf install -y broot
        ;;
    pacman)
        sudo pacman -Sy --noconfirm broot
        ;;
esac

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
# fzf shell integration
# --------------------------
if command -v fzf >/dev/null; then
    log "Setting up fzf integration"
    if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
        mkdir -p ~/.config/fzf
        ln -sf /usr/share/fzf/key-bindings.zsh ~/.config/fzf/key-bindings.zsh
        ln -sf /usr/share/fzf/completion.zsh ~/.config/fzf/completion.zsh
    fi
fi



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

log "Linking neovim config"
mkdir -p ~/.config
ln -sf "$DOTFILES/nvim" "$HOME/.config/nvim"


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



if command -v br >/dev/null; then
    log "broot installed"
fi


log "Bootstrap completed. Restart your shell."
