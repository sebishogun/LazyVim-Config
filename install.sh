#!/bin/bash
set -e

echo "=== LazyVim Custom Config Installer ==="

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# Check OS
OS="$(uname -s)"
echo -e "${GREEN}Detected OS: $OS${NC}"

# Install dependencies
install_deps() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y git curl unzip ripgrep fd-find nodejs npm python3 python3-pip python3-venv build-essential
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y git curl unzip ripgrep fd-find nodejs npm python3 python3-pip gcc gcc-c++
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu --noconfirm git curl unzip ripgrep fd nodejs npm python python-pip base-devel
    elif command -v brew &> /dev/null; then
        brew install git curl unzip ripgrep fd node python
    else
        echo -e "${RED}Unknown package manager. Install git, ripgrep, fd, node, python manually.${NC}"
    fi
}

# Install Neovim
install_neovim() {
    echo -e "${YELLOW}Installing Neovim...${NC}"
    if command -v nvim &> /dev/null; then
        NVIM_VER=$(nvim --version | head -1 | grep -oP '\d+\.\d+')
        if (( $(echo "$NVIM_VER >= 0.10" | bc -l) )); then
            echo -e "${GREEN}Neovim $NVIM_VER already installed${NC}"
            return
        fi
    fi
    
    if [[ "$OS" == "Linux" ]]; then
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
        sudo rm -rf /opt/nvim && sudo tar -C /opt -xzf nvim-linux64.tar.gz
        sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
        rm nvim-linux64.tar.gz
    elif [[ "$OS" == "Darwin" ]]; then
        brew install neovim
    fi
    echo -e "${GREEN}Neovim installed: $(nvim --version | head -1)${NC}"
}

# Backup existing config
backup_config() {
    if [[ -d "$HOME/.config/nvim" ]]; then
        BACKUP="$HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
        echo -e "${YELLOW}Backing up existing config to $BACKUP${NC}"
        mv "$HOME/.config/nvim" "$BACKUP"
    fi
    rm -rf "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim" 2>/dev/null || true
}

# Install config
install_config() {
    echo -e "${YELLOW}Installing config...${NC}"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    mkdir -p "$HOME/.config"
    cp -r "$SCRIPT_DIR" "$HOME/.config/nvim"
    rm -f "$HOME/.config/nvim/install.sh" "$HOME/.config/nvim/uninstall.sh" "$HOME/.config/nvim/README.md" "$HOME/.config/nvim/.git" 2>/dev/null || true
}

# Sync plugins
sync_plugins() {
    echo -e "${YELLOW}Installing plugins (this may take a minute)...${NC}"
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || nvim --headless -c "lua require('lazy').sync()" -c "qa" 2>/dev/null || true
    echo -e "${GREEN}Plugins installed!${NC}"
}

# Main
main() {
    echo ""
    read -p "Install system dependencies? [y/N] " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] && install_deps
    
    read -p "Install/Update Neovim? [y/N] " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] && install_neovim
    
    backup_config
    install_config
    sync_plugins
    
    echo ""
    echo -e "${GREEN}=== Installation Complete! ===${NC}"
    echo "Run 'nvim' to start. First launch will install remaining plugins."
    echo ""
    echo "Quick tips:"
    echo "  Space       = Leader key"
    echo "  <leader>e   = File explorer"
    echo "  <leader>ff  = Find files"
    echo "  <leader>fg  = Live grep"
    echo "  <leader>db  = Toggle breakpoint"
    echo "  <leader>dc  = Start/continue debug"
}

main "$@"
