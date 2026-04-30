#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

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
# Update system packages
# --------------------------
log "Updating system packages"
case "$PM" in
    apt)
        sudo apt update
        sudo apt upgrade -y
        ;;
    dnf)
        sudo dnf update -y
        ;;
    pacman)
        sudo pacman -Syu --noconfirm
        ;;
esac

# --------------------------
# Update broot
# --------------------------
log "Updating broot"
case "$PM" in
    apt)
        sudo apt install --only-upgrade -y broot
        ;;
    dnf)
        sudo dnf update -y broot
        ;;
    pacman)
        sudo pacman -Sy --noconfirm broot
        ;;
esac

# --------------------------
# Update Go (latest from go.dev/dl)
# --------------------------
log "Updating Go"
mkdir -p /tmp/go-download
cd /tmp/go-download

# Get current Go version
CURRENT_GO=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//' || echo "none")

# Fetch latest Go version from go.dev/dl API
LATEST_GO=$(curl -s https://go.dev/dl/?mode=json | grep -oP '"version":\s*"\K[^"]+' | head -1)

if [[ "$CURRENT_GO" != "$LATEST_GO" && -n "$LATEST_GO" ]]; then
    log "Updating Go to ${LATEST_GO} (current: ${CURRENT_GO})"
    GO_ARCHIVE="go${LATEST_GO}.linux-amd64.tar.gz"
    curl -LO "https://go.dev/dl/${GO_ARCHIVE}"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "${GO_ARCHIVE}"
else
    log "Go is up to date (${CURRENT_GO})"
fi

cd - > /dev/null

# --------------------------
# Update tmux (local build)
# --------------------------
TMUX_BIN="$HOME/.local/bin/tmux"
CURRENT_TMUX_VERSION=$(tmux -V 2>/dev/null | awk '{print $2}' || echo "none")
LATEST_TMUX_VERSION="3.6a"  # Update this manually or fetch from GitHub releases

if [[ "$CURRENT_TMUX_VERSION" != "$LATEST_TMUX_VERSION" ]]; then
    log "Updating tmux to ${LATEST_TMUX_VERSION}"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/src"
    cd "$HOME/.local/src"

    curl -LO https://github.com/tmux/tmux/releases/download/${LATEST_TMUX_VERSION}/tmux-${LATEST_TMUX_VERSION}.tar.gz
    tar xf tmux-${LATEST_TMUX_VERSION}.tar.gz
    cd tmux-${LATEST_TMUX_VERSION}

    ./configure --prefix="$HOME/.local"
    make -j"$(nproc)"
    make install
else
    log "tmux is up to date (${CURRENT_TMUX_VERSION})"
fi

# --------------------------
# Update fzf (standalone binary)
# --------------------------
FZF_BIN="$HOME/.local/bin/fzf"
log "Updating fzf"
mkdir -p "$HOME/.local/bin"
curl -L https://github.com/junegunn/fzf/releases/latest/download/fzf-linux_amd64 -o "$FZF_BIN"
chmod +x "$FZF_BIN"

# --------------------------
# Update neovim (standalone AppImage)
# --------------------------
NVIM_BIN="$HOME/.local/bin/nvim"
log "Updating neovim"
mkdir -p "$HOME/.local/bin"
curl -L https://github.com/neovim/neovim/releases/latest/download/nvim.appimage -o "$NVIM_BIN"
chmod +x "$NVIM_BIN"

# --------------------------
# Update Oh My Zsh
# --------------------------
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "Updating Oh My Zsh"
    git -C "$HOME/.oh-my-zsh" pull --rebase --stat
fi

# --------------------------
# Update tmux plugins
# --------------------------
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    log "Updating tmux plugins"
    cd "$HOME/.tmux/plugins/tpm"
    git pull --rebase --stat origin master
    # Install/update plugins
    "$HOME/.tmux/plugins/tpm/bin/install_plugins"
    "$HOME/.tmux/plugins/tpm/bin/update_plugins" all
fi

log "Upgrade completed. Restart your shell if necessary."