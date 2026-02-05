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

# Install 99 AI agent plugin (fork with CopilotCLI support)
install_99_plugin() {
    echo -e "${YELLOW}Installing 99 AI agent plugin...${NC}"
    PLUGIN_DIR="$HOME/neovim-configs/99"
    
    if [[ -d "$PLUGIN_DIR" ]]; then
        echo -e "${GREEN}99 plugin already exists, pulling latest...${NC}"
        cd "$PLUGIN_DIR" && git pull origin master
    else
        echo -e "${YELLOW}Cloning 99 plugin fork...${NC}"
        mkdir -p "$HOME/neovim-configs"
        git clone https://github.com/sebishogun/99.git "$PLUGIN_DIR"
    fi
    
    # Check if opencode is installed (default provider)
    if command -v opencode &> /dev/null; then
        echo -e "${GREEN}OpenCode CLI found - configuring neovim agent...${NC}"
        configure_opencode_agent
    else
        echo -e "${YELLOW}Note: Install OpenCode CLI for 99 plugin: https://github.com/opencode-ai/opencode${NC}"
        echo -e "${YELLOW}Or switch to another provider with :NNClaude, :NNCopilot, etc.${NC}"
    fi
}

# Configure OpenCode with neovim agent for 99 plugin
configure_opencode_agent() {
    OPENCODE_CONFIG="$HOME/.config/opencode/config.json"
    mkdir -p "$HOME/.config/opencode"
    
    # Neovim agent config - allows external file writes for 99 plugin temp files
    NEOVIM_AGENT='{
  "neovim": {
    "description": "Agent for neovim 99 plugin - allows all file writes",
    "mode": "all",
    "permission": {
      "external_directory": "allow",
      "read": "allow",
      "edit": "allow",
      "bash": "allow",
      "glob": "allow",
      "grep": "allow",
      "list": "allow",
      "question": "deny",
      "doom_loop": "deny"
    }
  }
}'

    if [[ -f "$OPENCODE_CONFIG" ]]; then
        # Check if neovim agent already configured
        if grep -q '"neovim"' "$OPENCODE_CONFIG" 2>/dev/null; then
            echo -e "${GREEN}OpenCode neovim agent already configured${NC}"
            return
        fi
        
        # Add neovim agent to existing config using jq if available
        if command -v jq &> /dev/null; then
            # Merge agent config into existing config
            jq --argjson agent "$NEOVIM_AGENT" '.agent = (.agent // {}) + $agent' "$OPENCODE_CONFIG" > "$OPENCODE_CONFIG.tmp" && mv "$OPENCODE_CONFIG.tmp" "$OPENCODE_CONFIG"
            echo -e "${GREEN}Added neovim agent to OpenCode config${NC}"
        else
            echo -e "${YELLOW}jq not found - please manually add neovim agent to $OPENCODE_CONFIG${NC}"
            echo -e "${YELLOW}See: https://github.com/sebishogun/99#opencode-setup${NC}"
        fi
    else
        # Create new config with neovim agent
        cat > "$OPENCODE_CONFIG" << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "neovim": {
      "description": "Agent for neovim 99 plugin - allows all file writes",
      "mode": "all",
      "permission": {
        "external_directory": "allow",
        "read": "allow",
        "edit": "allow",
        "bash": "allow",
        "glob": "allow",
        "grep": "allow",
        "list": "allow",
        "question": "deny",
        "doom_loop": "deny"
      }
    }
  }
}
EOF
        echo -e "${GREEN}Created OpenCode config with neovim agent${NC}"
    fi
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
    install_99_plugin
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
    echo ""
    echo "Debugging:"
    echo "  <leader>db  = Toggle breakpoint"
    echo "  <leader>dc  = Start/continue debug"
    echo ""
    echo "99 AI Agent (requires OpenCode/Claude/Copilot CLI):"
    echo "  <leader>9f  = Fill in function"
    echo "  <leader>9v  = Process visual selection"
    echo "  :NNOpenCode = Switch to OpenCode provider"
    echo "  :NNClaude   = Switch to Claude CLI"
    echo "  :NNCopilot  = Switch to Copilot CLI"
}

main "$@"
