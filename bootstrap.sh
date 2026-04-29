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
# broot (Azlux repo, Debian/Ubuntu)
# --------------------------
if [[ "$PM" == "apt" ]]; then
    AZLUX_KEYRING="/usr/share/keyrings/azlux-archive-keyring.gpg"
    AZLUX_SOURCE="/etc/apt/sources.list.d/azlux.sources"

    if [[ ! -f "$AZLUX_KEYRING" ]]; then
        log "Installing Azlux keyring (broot)"
        sudo mkdir -p /usr/share/keyrings
        sudo wget -qO "$AZLUX_KEYRING" https://azlux.fr/repo.gpg
    fi

    if [[ ! -f "$AZLUX_SOURCE" ]]; then
        log "Adding Azlux APT source (broot)"
        sudo tee "$AZLUX_SOURCE" > /dev/null <<'EOF'
Types: deb
URIs: http://packages.azlux.fr/debian/
Suites: trixie
Components: main
Signed-By: /usr/share/keyrings/azlux-archive-keyring.gpg
EOF
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
