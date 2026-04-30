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
# Ensure basic tooling
# --------------------------
log "Ensuring network tooling is available"
case "$PM" in
    apt)
        sudo apt update
        sudo apt install -y curl wget git ca-certificates gnupg
        ;;
    dnf)
        sudo dnf install -y curl wget git ca-certificates
        ;;
    pacman)
        sudo pacman -Sy --noconfirm curl wget git ca-certificates
        ;;
esac

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
# Install Go (latest from go.dev/dl)
# --------------------------
log "Installing Go"
mkdir -p /tmp/go-download
cd /tmp/go-download

# Fetch latest Go version from go.dev/dl API
LATEST_GO=$(curl -s https://go.dev/dl/?mode=json | grep -oP '"version":\s*"\K[^"]+' | head -1)

if [[ -n "$LATEST_GO" ]]; then
    GO_ARCHIVE="go${LATEST_GO}.linux-amd64.tar.gz"
    curl -LO "https://go.dev/dl/${GO_ARCHIVE}"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "${GO_ARCHIVE}"
    log "Go ${LATEST_GO} installed"
else
    echo "Failed to fetch latest Go version"
    exit 1
fi

cd - > /dev/null

# --------------------------
# tmux (local build)
# --------------------------
if [[ "$PM" == "apt" ]]; then
    sudo apt install -y \
        build-essential \
        libevent-dev \
        ncurses-dev
fi
TMUX_VERSION="3.6a"
TMUX_BIN="$HOME/.local/bin/tmux"

if [[ ! -x "$TMUX_BIN" ]]; then
    log "Installing tmux ${TMUX_VERSION} (local build)"

    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/src"
    cd "$HOME/.local/src"

    curl -LO \
      https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz

    tar xf tmux-${TMUX_VERSION}.tar.gz
    cd tmux-${TMUX_VERSION}

    ./configure --prefix="$HOME/.local"
    make -j"$(nproc)"
    make install
fi

# --------------------------
# fzf (standalone binary)
# --------------------------
FZF_BIN="$HOME/.local/bin/fzf"

if [[ ! -x "$FZF_BIN" ]]; then
    log "Installing fzf (binary)"
    mkdir -p "$HOME/.local/bin"
    curl -L \
      https://github.com/junegunn/fzf/releases/latest/download/fzf-linux_amd64 \
      -o "$FZF_BIN"
    chmod +x "$FZF_BIN"
fi


# AppImage runtime dependency
if [[ "$PM" == "apt" ]]; then
    sudo apt install -y fuse
fi

# --------------------------
# neovim (standalone AppImage)
# --------------------------
NVIM_BIN="$HOME/.local/bin/nvim"

if [[ ! -x "$NVIM_BIN" ]]; then
    log "Installing neovim (AppImage)"
    mkdir -p "$HOME/.local/bin"

    curl -L \
      https://github.com/neovim/neovim/releases/latest/download/nvim.appimage \
      -o "$NVIM_BIN"

    chmod +x "$NVIM_BIN"
fi


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
# Install Oh My Zsh
# --------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "Installing Oh My Zsh"
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi

# --------------------------
# Install TPM (tmux plugin manager)
# --------------------------
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    log "Installing tmux plugin manager (TPM)"
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# --------------------------
# Symlink dotfiles
# --------------------------
log "Linking dotfiles"

mkdir -p "$HOME/.tmux"
ln -sf "$DOTFILES/zsh/zshrc" "$HOME/.zshrc"
# ln -sf "$DOTFILES/zsh/zprofile" "$HOME/.zprofile"
ln -sf "$DOTFILES/tmux/tmux.conf" "$HOME/.tmux.conf"
ln -sf "$DOTFILES/tmux/cheatsheet.txt" "$HOME/.tmux/cheatsheet.txt"

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
